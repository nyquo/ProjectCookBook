#include "AisleListModel.hpp"

#include "appBackend.hpp"
#include "core/Backend.hpp"
#include "core/Database.hpp"

#include <expected>
#include <iterator>
#include <optional>
#include <stdexcept>
#include <variant>

static_assert(std::size(core::allAisleColors) == 4,
              "Mirror new core::AisleColor values in AisleListModel::Color");

template<typename... Handlers>
struct Overloaded : Handlers...
{
  using Handlers::operator()...;
};

// QML can pass any number as a Color.
static std::optional<core::AisleColor> toCore(AisleListModel::Color color)
{
  for (core::AisleColor coreColor : core::allAisleColors) {
    if (std::to_underlying(coreColor) == std::to_underlying(color)) {
      return coreColor;
    }
  }
  qWarning("AisleListModel: invalid color %d", std::to_underlying(color));
  return std::nullopt;
}

static AisleListModel::Error toError(core::AisleError error)
{
  switch (error) {
    case core::AisleError::EmptyName:
      return AisleListModel::Error::EmptyName;
    case core::AisleError::DuplicateName:
      return AisleListModel::Error::DuplicateName;
  }
  std::unreachable();
}

template<typename T>
static AisleListModel::Error toError(
  const std::expected<T, core::AisleError>& result)
{
  return result ? AisleListModel::Error::NoError : toError(result.error());
}

// Exceptions can't cross into QML. A failed write leaves memory unchanged, so
// the UI stays consistent and only has to report that saving failed. The store
// throws logic errors before changing anything, e.g. for an id QML kept after
// it went stale.
static AisleListModel::Error guarded(auto&& action)
{
  try {
    return action();
  } catch (const core::DatabaseError& error) {
    qCritical("Saving aisles failed: %s", error.what());
    return AisleListModel::Error::StorageFailed;
  } catch (const std::logic_error& error) {
    qWarning("AisleListModel: %s", error.what());
    return AisleListModel::Error::InvalidRequest;
  }
}

AisleListModel::AisleListModel(QObject* parent)
  : AisleListModel(app::backend().aisles(), parent)
{
}

AisleListModel::AisleListModel(core::AisleStore& store, QObject* parent)
  : QAbstractListModel(parent)
  , m_store(store)
{
  m_store.addObserver(*this);
}

AisleListModel::~AisleListModel()
{
  m_store.removeObserver(*this);
}

int AisleListModel::rowCount(const QModelIndex& parent) const
{
  return parent.isValid() ? 0 : static_cast<int>(m_store.aisles().size());
}

QVariant AisleListModel::data(const QModelIndex& index, int role) const
{
  if (!checkIndex(index,
                  CheckIndexOption::IndexIsValid |
                    CheckIndexOption::ParentIsInvalid)) {
    return {};
  }

  const core::Aisle& aisle = m_store.aisles()[index.row()];
  switch (role) {
    case AisleIdRole:
      return QString::fromStdString(aisle.id);
    case NameRole:
      return QString::fromStdString(aisle.name);
    case ColorRole:
      return QVariant::fromValue(static_cast<Color>(aisle.color));
  }
  return {};
}

QHash<int, QByteArray> AisleListModel::roleNames() const
{
  return { { AisleIdRole, "aisleId" },
           { NameRole, "name" },
           { ColorRole, "color" } };
}

AisleListModel::Error AisleListModel::create(const QString& name, Color color)
{
  const auto coreColor = toCore(color);
  if (!coreColor) {
    return Error::InvalidRequest;
  }
  return guarded(
    [&] { return toError(m_store.create(name.toStdString(), *coreColor)); });
}

AisleListModel::Error AisleListModel::rename(int row, const QString& name)
{
  if (!isValidRow(row)) {
    return Error::InvalidRequest;
  }
  return guarded(
    [&] { return toError(m_store.rename(idAt(row), name.toStdString())); });
}

AisleListModel::Error AisleListModel::setColor(int row, Color color)
{
  const auto coreColor = toCore(color);
  if (!isValidRow(row) || !coreColor) {
    return Error::InvalidRequest;
  }
  return guarded([&] {
    m_store.setColor(idAt(row), *coreColor);
    return Error::NoError;
  });
}

AisleListModel::Error AisleListModel::move(int from, int to)
{
  if (!isValidRow(from) || !isValidRow(to)) {
    return Error::InvalidRequest;
  }
  return guarded([&] {
    m_store.move(from, to);
    return Error::NoError;
  });
}

AisleListModel::Error AisleListModel::remove(int row)
{
  if (!isValidRow(row)) {
    return Error::InvalidRequest;
  }
  return guarded([&] {
    m_store.remove(idAt(row));
    return Error::NoError;
  });
}

AisleListModel::Error AisleListModel::restore(const QString& aisleId)
{
  return guarded(
    [&] { return toError(m_store.restore(aisleId.toStdString())); });
}

void AisleListModel::aisleAboutToChange(
  const core::AisleChange& change) noexcept
{
  const Overloaded begin{
    [this](const core::AisleInserted& c) {
      beginInsertRows({}, c.index, c.index);
    },
    [this](const core::AisleRemoved& c) {
      beginRemoveRows({}, c.index, c.index);
    },
    [this](const core::AisleMoved& c) {
      // Qt wants the row it goes before, counted before the move.
      beginMoveRows({}, c.from, c.from, {}, c.to > c.from ? c.to + 1 : c.to);
    },
    [](const core::AisleUpdated&) {},
  };
  std::visit(begin, change);
}

void AisleListModel::aisleChanged(const core::AisleChange& change) noexcept
{
  const Overloaded end{
    [this](const core::AisleInserted&) { endInsertRows(); },
    [this](const core::AisleRemoved&) { endRemoveRows(); },
    [this](const core::AisleMoved&) { endMoveRows(); },
    [this](const core::AisleUpdated& c) {
      const int role = c.field == core::AisleField::Name ? NameRole : ColorRole;
      emit dataChanged(index(c.index), index(c.index), { role });
    },
  };
  std::visit(end, change);
}

// Rows from QML can be stale, e.g. from a delegate in its remove transition.
bool AisleListModel::isValidRow(int row) const
{
  if (row >= 0 && row < rowCount()) {
    return true;
  }
  qWarning("AisleListModel: row %d out of range", row);
  return false;
}

std::string AisleListModel::idAt(int row) const
{
  return m_store.aisles()[row].id;
}
