#include "AisleListModel.hpp"

#include "Overloaded.hpp"
#include "appBackend.hpp"
#include "core/Backend.hpp"
#include "core/Database.hpp"

#include <algorithm>
#include <cstdint>
#include <expected>
#include <optional>
#include <stdexcept>
#include <utility>
#include <variant>

static QColor toQColor(core::Rgb color)
{
  return QColor(color.red, color.green, color.blue);
}

// QML can pass any color, but "#rrggbb" holds neither an invalid nor a
// translucent one
static std::optional<core::Rgb> toCore(const QColor& color)
{
  if (!color.isValid() || color.alpha() != 255) {
    qWarning("AisleListModel: invalid or translucent color %s",
             qPrintable(color.name(QColor::HexArgb)));
    return std::nullopt;
  }
  const QColor rgb = color.toRgb();
  return core::Rgb{ static_cast<std::uint8_t>(rgb.red()),
                    static_cast<std::uint8_t>(rgb.green()),
                    static_cast<std::uint8_t>(rgb.blue()) };
}

static std::optional<core::ThemedColors> toCore(const QColor& fill,
                                                const QColor& ink,
                                                const QColor& darkFill,
                                                const QColor& darkInk)
{
  const auto coreFill = toCore(fill);
  const auto coreInk = toCore(ink);
  const auto coreDarkFill = toCore(darkFill);
  const auto coreDarkInk = toCore(darkInk);
  if (!coreFill || !coreInk || !coreDarkFill || !coreDarkInk) {
    return std::nullopt;
  }
  return core::ThemedColors{ *coreFill, *coreInk, *coreDarkFill, *coreDarkInk };
}

static AisleListModel::Error toError(core::AisleError error)
{
  switch (error) {
    case core::AisleError::EmptyName:
      return AisleListModel::Error::EmptyName;
    case core::AisleError::DuplicateName:
      return AisleListModel::Error::DuplicateName;
    case core::AisleError::InUse:
      return AisleListModel::Error::InUse;
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
  : AisleListModel(app::backend().aisles(),
                   app::backend().ingredients(),
                   parent)
{
}

AisleListModel::AisleListModel(core::AisleStore& store,
                               core::IngredientStore& ingredients,
                               QObject* parent)
  : QAbstractListModel(parent)
  , m_store(store)
  , m_ingredients(ingredients)
  , m_itemCounts(countItems())
{
  m_store.addObserver(*this);
  m_ingredients.addObserver(*this);
}

AisleListModel::~AisleListModel()
{
  m_ingredients.removeObserver(*this);
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
    case FillRole:
      return toQColor(aisle.colors.fill);
    case InkRole:
      return toQColor(aisle.colors.ink);
    case DarkFillRole:
      return toQColor(aisle.colors.darkFill);
    case DarkInkRole:
      return toQColor(aisle.colors.darkInk);
    case ItemCountRole: {
      const auto it = m_itemCounts.find(aisle.id);
      return it != m_itemCounts.end() ? it->second : 0;
    }
  }
  return {};
}

QHash<int, QByteArray> AisleListModel::roleNames() const
{
  return { { AisleIdRole, "aisleId" },    { NameRole, "name" },
           { FillRole, "fill" },          { InkRole, "ink" },
           { DarkFillRole, "darkFill" },  { DarkInkRole, "darkInk" },
           { ItemCountRole, "itemCount" } };
}

AisleListModel::Error AisleListModel::create(const QString& name,
                                             const QColor& fill,
                                             const QColor& ink,
                                             const QColor& darkFill,
                                             const QColor& darkInk)
{
  const auto colors = toCore(fill, ink, darkFill, darkInk);
  if (!colors) {
    return Error::InvalidRequest;
  }
  return guarded(
    [&] { return toError(m_store.create(name.toStdString(), *colors)); });
}

AisleListModel::Error AisleListModel::rename(int row, const QString& name)
{
  if (!isValidRow(row)) {
    return Error::InvalidRequest;
  }
  return guarded(
    [&] { return toError(m_store.rename(idAt(row), name.toStdString())); });
}

AisleListModel::Error AisleListModel::setColors(int row,
                                                const QColor& fill,
                                                const QColor& ink,
                                                const QColor& darkFill,
                                                const QColor& darkInk)
{
  const auto colors = toCore(fill, ink, darkFill, darkInk);
  if (!isValidRow(row) || !colors) {
    return Error::InvalidRequest;
  }
  return guarded([&] {
    m_store.setColors(idAt(row), *colors);
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
  return guarded([&] { return toError(m_store.remove(idAt(row))); });
}

AisleListModel::Error AisleListModel::restore(const QString& aisleId)
{
  return guarded(
    [&] { return toError(m_store.restore(aisleId.toStdString())); });
}

int AisleListModel::rowOf(const QString& aisleId) const
{
  const auto& aisles = m_store.aisles();
  const auto it =
    std::ranges::find(aisles, aisleId.toStdString(), &core::Aisle::id);
  return it != aisles.end() ? static_cast<int>(it - aisles.begin()) : -1;
}

QString AisleListModel::aisleIdAt(int row) const
{
  return row >= 0 && row < rowCount() ? QString::fromStdString(idAt(row))
                                      : QString();
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
      // Qt wants the row it goes before, counted before the move
      beginMoveRows({}, c.from, c.from, {}, c.to > c.from ? c.to + 1 : c.to);
    },
    [](const core::AisleUpdated&) {},
  };
  std::visit(begin, change);
}

void AisleListModel::aisleChanged(const core::AisleChange& change) noexcept
{
  const Overloaded end{
    [this](const core::AisleInserted&) {
      endInsertRows();
      emit countChanged();
    },
    [this](const core::AisleRemoved&) {
      endRemoveRows();
      emit countChanged();
    },
    [this](const core::AisleMoved&) { endMoveRows(); },
    [this](const core::AisleUpdated& c) {
      const QList<int> roles =
        c.field == core::AisleField::Name
          ? QList<int>{ NameRole }
          : QList<int>{ FillRole, InkRole, DarkFillRole, DarkInkRole };
      emit dataChanged(index(c.index), index(c.index), roles);
    },
  };
  std::visit(end, change);
}

void AisleListModel::ingredientAboutToChange(
  const core::IngredientChange&) noexcept
{
}

void AisleListModel::ingredientChanged(const core::IngredientChange&) noexcept
{
  std::map<std::string, int, std::less<>> counts = countItems();
  std::swap(m_itemCounts, counts);
  const auto countOf = [](const auto& map, const std::string& id) {
    const auto it = map.find(id);
    return it != map.end() ? it->second : 0;
  };
  for (int row = 0; row < rowCount(); ++row) {
    const std::string id = idAt(row);
    if (countOf(m_itemCounts, id) != countOf(counts, id)) {
      emit dataChanged(index(row), index(row), { ItemCountRole });
    }
  }
}

std::map<std::string, int, std::less<>> AisleListModel::countItems() const
{
  std::map<std::string, int, std::less<>> counts;
  for (const core::Ingredient& ingredient : m_ingredients.ingredients()) {
    if (ingredient.inCatalog && ingredient.aisleId) {
      ++counts[*ingredient.aisleId];
    }
  }
  return counts;
}

// Rows from QML can be stale, e.g. from a delegate in its remove transition
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
