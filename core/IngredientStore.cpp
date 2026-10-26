#include "core/IngredientStore.hpp"

#include "core/AisleStore.hpp"
#include "core/Database.hpp"
#include "core/text.hpp"

#include <sqlite3.h>

#include <algorithm>
#include <cmath>
#include <stdexcept>

namespace core {

static std::optional<std::string> optionalText(const Statement& statement,
                                               int index)
{
  if (statement.columnIsNull(index)) {
    return std::nullopt;
  }
  return statement.columnText(index);
}

static std::vector<IngredientField> changedFields(const Ingredient& before,
                                                  const Ingredient& after)
{
  std::vector<IngredientField> fields;
  if (before.name != after.name ||
      before.canonicalName != after.canonicalName) {
    fields.push_back(IngredientField::Name);
  }
  if (before.aisleId != after.aisleId) {
    fields.push_back(IngredientField::Aisle);
  }
  if (before.icon != after.icon) {
    fields.push_back(IngredientField::Icon);
  }
  if (before.oneTap != after.oneTap) {
    fields.push_back(IngredientField::OneTap);
  }
  if (before.inCatalog != after.inCatalog) {
    fields.push_back(IngredientField::InCatalog);
  }
  return fields;
}

static bool isLiveAisle(const AisleStore& aisles, std::string_view id)
{
  return std::ranges::find(aisles.aisles(), id, &Aisle::id) !=
         aisles.aisles().end();
}

// Binds ?first to ?first + 7: display_name, canonical_name, aisle_id, icon,
// one_tap_quantity, one_tap_unit, in_catalog, modified_at
static void bindColumns(Statement& statement,
                        int first,
                        const Ingredient& ingredient)
{
  statement.bind(first, ingredient.name)
    .bind(first + 1, ingredient.canonicalName)
    .bind(first + 2, ingredient.aisleId)
    .bind(first + 3, ingredient.icon)
    .bind(first + 6, ingredient.inCatalog)
    .bind(first + 7, toMillis(ingredient.modifiedAt));
  if (ingredient.oneTap) {
    statement.bind(first + 4, ingredient.oneTap->quantity)
      .bind(first + 5, unitCode(ingredient.oneTap->unit));
  } else {
    statement.bindNull(first + 4).bindNull(first + 5);
  }
}

IngredientStore::IngredientStore(Database& db,
                                 Clock clock,
                                 const AisleStore& aisles)
  : m_db(db)
  , m_clock(std::move(clock))
  , m_aisles(aisles)
{
  Statement select =
    m_db.prepare("SELECT id, display_name, canonical_name, aisle_id, icon, "
                 "one_tap_quantity, one_tap_unit, in_catalog, modified_at "
                 "FROM ingredient WHERE deleted = 0 ORDER BY id");
  while (select.step()) {
    std::optional<Amount> oneTap;
    if (!select.columnIsNull(5)) {
      const std::string code = select.columnText(6);
      const std::optional<Unit> unit = unitFromCode(code);
      if (!unit) {
        throw DatabaseError(SQLITE_CORRUPT, "invalid unit '" + code + "'");
      }
      oneTap = Amount{ select.columnDouble(5), *unit };
    }
    m_ingredients.push_back({ select.columnText(0),
                              select.columnText(1),
                              select.columnText(2),
                              optionalText(select, 3),
                              optionalText(select, 4),
                              oneTap,
                              select.columnInt64(7) != 0,
                              fromMillis(select.columnInt64(8)) });
  }
}

std::expected<std::string, IngredientError> IngredientStore::addToCatalog(
  const CatalogFields& fields)
{
  checkNotNotifying();
  checkFields(fields);
  auto validated = validName(fields.name, -1);
  if (!validated) {
    return std::unexpected(validated.error());
  }

  const Timestamp now = m_clock();
  Ingredient item{ {},
                   std::move(validated->name),
                   std::move(validated->canonicalName),
                   std::string(fields.aisleId),
                   fields.icon ? std::optional<std::string>(*fields.icon)
                               : std::nullopt,
                   fields.oneTap,
                   true,
                   now };
  if (validated->match >= 0) {
    item.id = m_ingredients[validated->match].id;
    std::string id = item.id;
    update(validated->match, std::move(item));
    return id;
  }

  item.id = m_ids.next(now);
  Statement insert = m_db.prepare(
    "INSERT INTO ingredient (id, display_name, canonical_name, aisle_id, icon, "
    "one_tap_quantity, one_tap_unit, in_catalog, modified_at) "
    "VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)");
  insert.bind(1, item.id);
  bindColumns(insert, 2, item);
  insert.run();

  std::string id = item.id;
  apply(IngredientInserted{ count() },
        [&] { m_ingredients.push_back(std::move(item)); });
  return id;
}

std::expected<void, IngredientError> IngredientStore::updateCatalogItem(
  std::string_view id,
  const CatalogFields& fields)
{
  checkNotNotifying();
  const int index = catalogIndexOf(id);
  checkFields(fields);
  auto validated = validName(fields.name, index);
  if (!validated) {
    return std::unexpected(validated.error());
  }
  if (validated->match >= 0) {
    return std::unexpected(IngredientError::NameTaken);
  }

  Ingredient changed = m_ingredients[index];
  changed.name = std::move(validated->name);
  changed.canonicalName = std::move(validated->canonicalName);
  changed.aisleId = std::string(fields.aisleId);
  changed.icon =
    fields.icon ? std::optional<std::string>(*fields.icon) : std::nullopt;
  changed.oneTap = fields.oneTap;
  changed.modifiedAt = m_clock();
  update(index, std::move(changed));
  return {};
}

void IngredientStore::removeFromCatalog(std::string_view id)
{
  checkNotNotifying();
  const int index = catalogIndexOf(id);

  Ingredient changed = m_ingredients[index];
  changed.inCatalog = false;
  changed.modifiedAt = m_clock();
  update(index, std::move(changed));
}

std::expected<void, IngredientError> IngredientStore::restoreToCatalog(
  std::string_view id)
{
  checkNotNotifying();
  const int index = indexOf(id);
  const Ingredient& current = m_ingredients[index];
  if (current.inCatalog) {
    throw std::invalid_argument(
      "IngredientStore::restoreToCatalog: already in the catalog");
  }
  if (!current.oneTap) {
    throw std::invalid_argument(
      "IngredientStore::restoreToCatalog: no one-tap amount");
  }
  if (!current.aisleId || !isLiveAisle(m_aisles, *current.aisleId)) {
    return std::unexpected(IngredientError::AisleDeleted);
  }

  Ingredient changed = current;
  changed.inCatalog = true;
  changed.modifiedAt = m_clock();
  update(index, std::move(changed));
  return {};
}

std::expected<void, IngredientError> IngredientStore::checkCatalogName(
  std::string_view name,
  std::optional<std::string_view> id) const
{
  const int ignoredIndex = id ? catalogIndexOf(*id) : -1;
  const auto validated = validName(name, ignoredIndex);
  if (!validated) {
    return std::unexpected(validated.error());
  }
  if (id && validated->match >= 0) {
    return std::unexpected(IngredientError::NameTaken);
  }
  return {};
}

void IngredientStore::addObserver(IngredientObserver& observer)
{
  m_observers.add(observer);
}

void IngredientStore::removeObserver(IngredientObserver& observer)
{
  m_observers.remove(observer);
}

int IngredientStore::indexOf(std::string_view id) const
{
  const auto it = std::ranges::find(m_ingredients, id, &Ingredient::id);
  if (it == m_ingredients.end()) {
    throw std::invalid_argument(
      "IngredientStore: no live ingredient with this id");
  }
  return static_cast<int>(it - m_ingredients.begin());
}

int IngredientStore::catalogIndexOf(std::string_view id) const
{
  const int index = indexOf(id);
  if (!m_ingredients[index].inCatalog) {
    throw std::invalid_argument("IngredientStore: not a catalog item");
  }
  return index;
}

void IngredientStore::checkNotNotifying() const
{
  if (m_observers.notifying()) {
    throw std::logic_error(
      "IngredientStore: no changes from inside an observer notification");
  }
}

void IngredientStore::checkFields(const CatalogFields& fields) const
{
  if (!isLiveAisle(m_aisles, fields.aisleId)) {
    throw std::invalid_argument("IngredientStore: no live aisle with this id");
  }
  if (fields.icon && fields.icon->empty()) {
    throw std::invalid_argument("IngredientStore: empty icon key");
  }
  if (!std::isfinite(fields.oneTap.quantity) || fields.oneTap.quantity <= 0) {
    throw std::invalid_argument(
      "IngredientStore: one-tap quantity must be above 0");
  }
}

std::expected<IngredientStore::ValidName, IngredientError>
IngredientStore::validName(std::string_view name, int ignoredIndex) const
{
  std::string clean(trimmed(name));
  std::string canonical = canonicalName(clean);
  if (canonical.empty()) {
    return std::unexpected(IngredientError::EmptyName);
  }
  int match = -1;
  for (int i = 0; i < count(); ++i) {
    if (i != ignoredIndex && m_ingredients[i].canonicalName == canonical) {
      if (m_ingredients[i].inCatalog) {
        return std::unexpected(IngredientError::DuplicateName);
      }
      match = i;
      break;
    }
  }
  return ValidName{ std::move(clean), std::move(canonical), match };
}

void IngredientStore::writeRow(const Ingredient& ingredient)
{
  Statement write = m_db.prepare(
    "UPDATE ingredient SET display_name = ?2, canonical_name = ?3, "
    "aisle_id = ?4, icon = ?5, one_tap_quantity = ?6, one_tap_unit = ?7, "
    "in_catalog = ?8, modified_at = ?9 WHERE id = ?1");
  write.bind(1, ingredient.id);
  bindColumns(write, 2, ingredient);
  write.run();
}

void IngredientStore::update(int index, Ingredient changed)
{
  std::vector<IngredientField> fields =
    changedFields(m_ingredients[index], changed);
  if (fields.empty()) {
    return;
  }
  writeRow(changed);
  apply(IngredientUpdated{ index, std::move(fields) },
        [&] { m_ingredients[index] = std::move(changed); });
}

template<typename Mutation>
void IngredientStore::apply(const IngredientChange& change,
                            Mutation mutate) noexcept
{
  m_observers.notify(
    [&](IngredientObserver& observer) {
      observer.ingredientAboutToChange(change);
    },
    mutate,
    [&](IngredientObserver& observer) { observer.ingredientChanged(change); });
}

}
