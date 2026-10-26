#include "CatalogListModel.hpp"

#include "AmountFormat.hpp"
#include "Overloaded.hpp"
#include "appBackend.hpp"
#include "core/Backend.hpp"
#include "core/Database.hpp"
#include "core/catalogView.hpp"
#include "core/listEdits.hpp"

#include <algorithm>
#include <expected>
#include <optional>
#include <stdexcept>
#include <string>
#include <utility>
#include <variant>

static QColor toQColor(core::Rgb color)
{
  return QColor(color.red, color.green, color.blue);
}

static CatalogListModel::Error toError(core::IngredientError error)
{
  switch (error) {
    case core::IngredientError::EmptyName:
      return CatalogListModel::Error::EmptyName;
    case core::IngredientError::DuplicateName:
      return CatalogListModel::Error::DuplicateName;
    case core::IngredientError::NameTaken:
      return CatalogListModel::Error::NameTaken;
    case core::IngredientError::AisleDeleted:
      return CatalogListModel::Error::AisleDeleted;
  }
  std::unreachable();
}

template<typename T>
static CatalogListModel::Error toError(
  const std::expected<T, core::IngredientError>& result)
{
  return result ? CatalogListModel::Error::NoError : toError(result.error());
}

// Exceptions can't cross into QML. A failed write leaves memory unchanged, so
// the UI stays consistent and only has to report that saving failed. The store
// throws logic errors before changing anything, e.g. for an id QML kept after
// it went stale.
static CatalogListModel::Error guarded(auto&& action)
{
  try {
    return action();
  } catch (const core::DatabaseError& error) {
    qCritical("Saving the catalog failed: %s", error.what());
    return CatalogListModel::Error::StorageFailed;
  } catch (const std::logic_error& error) {
    qWarning("CatalogListModel: %s", error.what());
    return CatalogListModel::Error::InvalidRequest;
  }
}

// The fields of a catalog item, holding the text CatalogFields points to
struct FieldTexts
{
  std::string name;
  std::string aisleId;
  std::string icon;
  std::optional<core::Unit> unit;

  core::CatalogFields fields(double quantity) const
  {
    return { name,
             aisleId,
             icon.empty() ? std::nullopt
                          : std::optional<std::string_view>(icon),
             { quantity, *unit } };
  }
};

static FieldTexts fieldTexts(const QString& name,
                             const QString& aisleId,
                             const QString& icon,
                             const QString& unit)
{
  return { name.toStdString(),
           aisleId.toStdString(),
           icon.toStdString(),
           core::unitFromCode(unit.toStdString()) };
}

CatalogListModel::CatalogListModel(QObject* parent)
  : CatalogListModel(app::backend().aisles(),
                     app::backend().ingredients(),
                     parent)
{
}

CatalogListModel::CatalogListModel(core::AisleStore& aisles,
                                   core::IngredientStore& ingredients,
                                   QObject* parent)
  : QAbstractListModel(parent)
  , m_aisles(aisles)
  , m_ingredients(ingredients)
{
  m_collator.setCaseSensitivity(Qt::CaseInsensitive);
  m_collator.setNumericMode(true);
  m_rows = computeRows();
  m_aisles.addObserver(*this);
  m_ingredients.addObserver(*this);
}

CatalogListModel::~CatalogListModel()
{
  m_ingredients.removeObserver(*this);
  m_aisles.removeObserver(*this);
}

int CatalogListModel::rowCount(const QModelIndex& parent) const
{
  return parent.isValid() ? 0 : static_cast<int>(m_rows.size());
}

QVariant CatalogListModel::data(const QModelIndex& index, int role) const
{
  if (!checkIndex(index,
                  CheckIndexOption::IndexIsValid |
                    CheckIndexOption::ParentIsInvalid)) {
    return {};
  }

  const Row& row = m_rows[index.row()];
  switch (role) {
    case IngredientIdRole:
      return row.ingredientId;
    case NameRole:
      return row.name;
    case IconRole:
      return row.icon;
    case QuantityRole:
      return row.quantity;
    case UnitRole:
      return row.unit;
    case AmountTextRole:
      return row.amountText;
    case AisleIdRole:
      return row.aisleId;
    case AisleNameRole:
      return row.aisleName;
    case FillRole:
      return row.fill;
    case InkRole:
      return row.ink;
    case DarkFillRole:
      return row.darkFill;
    case DarkInkRole:
      return row.darkInk;
    case GroupCountRole:
      return row.groupCount;
    case FirstInGroupRole:
      return row.firstInGroup;
    case LastInGroupRole:
      return row.lastInGroup;
  }
  return {};
}

QHash<int, QByteArray> CatalogListModel::roleNames() const
{
  return { { IngredientIdRole, "ingredientId" },
           { NameRole, "name" },
           { IconRole, "icon" },
           { QuantityRole, "quantity" },
           { UnitRole, "unit" },
           { AmountTextRole, "amountText" },
           { AisleIdRole, "aisleId" },
           { AisleNameRole, "aisleName" },
           { FillRole, "fill" },
           { InkRole, "ink" },
           { DarkFillRole, "darkFill" },
           { DarkInkRole, "darkInk" },
           { GroupCountRole, "groupCount" },
           { FirstInGroupRole, "firstInGroup" },
           { LastInGroupRole, "lastInGroup" } };
}

void CatalogListModel::setSearchText(const QString& text)
{
  if (text == m_searchText) {
    return;
  }
  m_searchText = text;
  emit searchTextChanged();
  refresh();
}

void CatalogListModel::setAisleFilter(const QString& aisleId)
{
  if (aisleId == m_aisleFilter) {
    return;
  }
  m_aisleFilter = aisleId;
  emit aisleFilterChanged();
  refresh();
}

CatalogListModel::Error CatalogListModel::checkName(
  const QString& name,
  const QString& ingredientId) const
{
  const std::string id = ingredientId.toStdString();
  return guarded([&] {
    return toError(m_ingredients.checkCatalogName(
      name.toStdString(),
      id.empty() ? std::nullopt : std::optional<std::string_view>(id)));
  });
}

CatalogListModel::Error CatalogListModel::add(const QString& name,
                                              const QString& aisleId,
                                              const QString& icon,
                                              double quantity,
                                              const QString& unit)
{
  const FieldTexts texts = fieldTexts(name, aisleId, icon, unit);
  if (!texts.unit) {
    qWarning("CatalogListModel: unknown unit %s", qPrintable(unit));
    return Error::InvalidRequest;
  }
  return guarded([&] {
    return toError(m_ingredients.addToCatalog(texts.fields(quantity)));
  });
}

CatalogListModel::Error CatalogListModel::update(const QString& ingredientId,
                                                 const QString& name,
                                                 const QString& aisleId,
                                                 const QString& icon,
                                                 double quantity,
                                                 const QString& unit)
{
  const FieldTexts texts = fieldTexts(name, aisleId, icon, unit);
  if (!texts.unit) {
    qWarning("CatalogListModel: unknown unit %s", qPrintable(unit));
    return Error::InvalidRequest;
  }
  return guarded([&] {
    return toError(m_ingredients.updateCatalogItem(ingredientId.toStdString(),
                                                   texts.fields(quantity)));
  });
}

CatalogListModel::Error CatalogListModel::removeFromCatalog(
  const QString& ingredientId)
{
  return guarded([&] {
    m_ingredients.removeFromCatalog(ingredientId.toStdString());
    return Error::NoError;
  });
}

CatalogListModel::Error CatalogListModel::restoreToCatalog(
  const QString& ingredientId)
{
  return guarded([&] {
    return toError(m_ingredients.restoreToCatalog(ingredientId.toStdString()));
  });
}

void CatalogListModel::aisleAboutToChange(const core::AisleChange&) noexcept {}

void CatalogListModel::aisleChanged(const core::AisleChange&) noexcept
{
  if (!m_aisleFilter.isEmpty() &&
      std::ranges::find(m_aisles.aisles(),
                        m_aisleFilter.toStdString(),
                        &core::Aisle::id) == m_aisles.aisles().end()) {
    m_aisleFilter.clear();
    emit aisleFilterChanged();
  }
  refresh();
}

void CatalogListModel::ingredientAboutToChange(
  const core::IngredientChange&) noexcept
{
}

void CatalogListModel::ingredientChanged(const core::IngredientChange&) noexcept
{
  refresh();
}

std::vector<CatalogListModel::Row> CatalogListModel::computeRows() const
{
  const std::vector<core::Aisle>& aisles = m_aisles.aisles();
  const std::vector<core::Ingredient>& ingredients =
    m_ingredients.ingredients();
  const std::string filter = m_aisleFilter.toStdString();
  const std::vector<core::CatalogEntry> entries = core::catalogView(
    aisles,
    ingredients,
    m_searchText.toStdString(),
    filter.empty() ? std::nullopt : std::optional<std::string_view>(filter),
    [this](std::string_view a, std::string_view b) {
      return m_collator.compare(
               QString::fromUtf8(a.data(), static_cast<qsizetype>(a.size())),
               QString::fromUtf8(b.data(), static_cast<qsizetype>(b.size()))) <
             0;
    });

  std::vector<Row> rows;
  rows.reserve(entries.size());
  for (std::size_t i = 0; i < entries.size(); ++i) {
    const core::CatalogEntry& entry = entries[i];
    const core::Ingredient& ingredient = ingredients[entry.ingredient];
    Row row;
    row.ingredientId = QString::fromStdString(ingredient.id);
    row.name = QString::fromStdString(ingredient.name);
    row.icon = QString::fromStdString(ingredient.icon.value_or(""));
    if (ingredient.oneTap) {
      row.quantity = ingredient.oneTap->quantity;
      const std::string_view unit = core::unitCode(ingredient.oneTap->unit);
      row.unit =
        QString::fromUtf8(unit.data(), static_cast<qsizetype>(unit.size()));
      row.amountText = app::formatAmount(*ingredient.oneTap);
    }
    if (entry.aisle >= 0) {
      const core::Aisle& aisle = aisles[entry.aisle];
      row.aisleId = QString::fromStdString(aisle.id);
      row.aisleName = QString::fromStdString(aisle.name);
      row.fill = toQColor(aisle.colors.fill);
      row.ink = toQColor(aisle.colors.ink);
      row.darkFill = toQColor(aisle.colors.darkFill);
      row.darkInk = toQColor(aisle.colors.darkInk);
    }
    row.firstInGroup = i == 0 || entries[i - 1].aisle != entry.aisle;
    row.lastInGroup =
      i + 1 == entries.size() || entries[i + 1].aisle != entry.aisle;
    rows.push_back(std::move(row));
  }

  for (std::size_t first = 0; first < rows.size();) {
    std::size_t last = first;
    while (!rows[last].lastInGroup) {
      ++last;
    }
    for (std::size_t i = first; i <= last; ++i) {
      rows[i].groupCount = static_cast<int>(last - first + 1);
    }
    first = last + 1;
  }
  return rows;
}

void CatalogListModel::refresh()
{
  std::vector<Row> next = computeRows();
  const auto ids = [](const std::vector<Row>& rows) {
    std::vector<std::string> result;
    result.reserve(rows.size());
    for (const Row& row : rows) {
      result.push_back(row.ingredientId.toStdString());
    }
    return result;
  };
  const int countBefore = rowCount();

  for (const core::ListEdit& edit : core::listEdits(ids(m_rows), ids(next))) {
    const Overloaded apply{
      [&](const core::ListRemoved& e) {
        beginRemoveRows({}, e.index, e.index);
        m_rows.erase(m_rows.begin() + e.index);
        endRemoveRows();
      },
      [&](const core::ListInserted& e) {
        beginInsertRows({}, e.index, e.index);
        m_rows.insert(m_rows.begin() + e.index, next[e.index]);
        endInsertRows();
      },
      [&](const core::ListMoved& e) {
        // Qt wants the row it goes before, counted before the move
        beginMoveRows({}, e.from, e.from, {}, e.to > e.from ? e.to + 1 : e.to);
        const auto first = m_rows.begin();
        if (e.from < e.to) {
          std::rotate(first + e.from, first + e.from + 1, first + e.to + 1);
        } else {
          std::rotate(first + e.to, first + e.from, first + e.from + 1);
        }
        endMoveRows();
      },
    };
    std::visit(apply, edit);
  }

  for (int i = 0; i < rowCount(); ++i) {
    const Row& before = m_rows[i];
    const Row& after = next[i];
    QList<int> roles;
    const auto compare = [&]<typename T>(T Row::* member, int role) {
      if (before.*member != after.*member) {
        roles.append(role);
      }
    };
    compare(&Row::name, NameRole);
    compare(&Row::icon, IconRole);
    compare(&Row::quantity, QuantityRole);
    compare(&Row::unit, UnitRole);
    compare(&Row::amountText, AmountTextRole);
    compare(&Row::aisleId, AisleIdRole);
    compare(&Row::aisleName, AisleNameRole);
    compare(&Row::fill, FillRole);
    compare(&Row::ink, InkRole);
    compare(&Row::darkFill, DarkFillRole);
    compare(&Row::darkInk, DarkInkRole);
    compare(&Row::groupCount, GroupCountRole);
    compare(&Row::firstInGroup, FirstInGroupRole);
    compare(&Row::lastInGroup, LastInGroupRole);
    if (!roles.isEmpty()) {
      m_rows[i] = std::move(next[i]);
      emit dataChanged(index(i), index(i), roles);
    }
  }

  if (rowCount() != countBefore) {
    emit countChanged();
  }
}
