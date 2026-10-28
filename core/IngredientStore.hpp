#pragma once

#include "core/Amount.hpp"
#include "core/Ingredient.hpp"
#include "core/Observers.hpp"
#include "core/UuidV7Generator.hpp"
#include "core/clock.hpp"

#include <expected>
#include <optional>
#include <string>
#include <string_view>
#include <variant>
#include <vector>

namespace core {

class AisleStore;
class Database;

// Validation failures the user can fix
enum class IngredientError
{
  EmptyName,     // blank once trimmed
  DuplicateName, // a catalog item has the same canonical name
  NameTaken,     // renaming: an ingredient outside the catalog has it
  AisleDeleted,  // restoreToCatalog(): its aisle was deleted meanwhile
};

enum class IngredientField
{
  Name,
  Aisle,
  Icon,
  OneTap,
  InCatalog
};

// Changes to IngredientStore::ingredients(), by index in that list
struct IngredientInserted
{
  int index;
  bool operator==(const IngredientInserted&) const = default;
};

struct IngredientUpdated
{
  int index;
  // In IngredientField order
  std::vector<IngredientField> fields;
  bool operator==(const IngredientUpdated&) const = default;
};

using IngredientChange = std::variant<IngredientInserted, IngredientUpdated>;

// Called like AisleObserver's functions: before memory changes, then after
class IngredientObserver
{
public:
  virtual void ingredientAboutToChange(
    const IngredientChange& change) noexcept = 0;
  virtual void ingredientChanged(const IngredientChange& change) noexcept = 0;

protected:
  ~IngredientObserver() = default;
};

// What the user edits of a catalog item
struct CatalogFields
{
  std::string_view name;
  // A live aisle's
  std::string_view aisleId;
  // An icon key, or none
  std::optional<std::string_view> icon;
  // Its quantity finite and above 0
  Amount oneTap;
};

// Live ingredients, catalog items or not, in creation order, held in memory and
// written through to SQLite like AisleStore's aisles. Programming errors throw
// std::logic_error subclasses before anything changes: unknown id, an id that
// isn't (or is already) in the catalog, an aisle that isn't live, an empty icon
// key, a quantity that isn't above 0, or a change requested from inside a
// notification.
class IngredientStore
{
public:
  // The database must be migrated; `aisles` must outlive the store
  IngredientStore(Database& db, Clock clock, const AisleStore& aisles);
  IngredientStore(const IngredientStore&) = delete;
  IngredientStore& operator=(const IngredientStore&) = delete;

  const std::vector<Ingredient>& ingredients() const { return m_ingredients; }

  // Returns the item's id. A live ingredient outside the catalog with the same
  // canonical name is reused: it joins the catalog with these fields.
  [[nodiscard]] std::expected<std::string, IngredientError> addToCatalog(
    const CatalogFields& fields);
  [[nodiscard]] std::expected<void, IngredientError> updateCatalogItem(
    std::string_view id,
    const CatalogFields& fields);
  // The ingredient stays, outside the catalog, for recipes and
  // restoreToCatalog()
  void removeFromCatalog(std::string_view id);
  // Fails with AisleDeleted if its aisle was deleted meanwhile
  [[nodiscard]] std::expected<void, IngredientError> restoreToCatalog(
    std::string_view id);

  // What addToCatalog(), or updateCatalogItem() for catalog item `id`, would
  // say of the name
  [[nodiscard]] std::expected<void, IngredientError> checkCatalogName(
    std::string_view name,
    std::optional<std::string_view> id = std::nullopt) const;

  // Not owned: an observer must unregister before it's destroyed
  void addObserver(IngredientObserver& observer);
  void removeObserver(IngredientObserver& observer);

private:
  struct ValidName
  {
    std::string name;
    std::string canonicalName;
    // The other live ingredient with this canonical name, or -1. Never a
    // catalog item: that's DuplicateName.
    int match;
  };

  int count() const { return static_cast<int>(m_ingredients.size()); }
  int indexOf(std::string_view id) const;
  int catalogIndexOf(std::string_view id) const;
  void checkNotNotifying() const;
  void checkFields(const CatalogFields& fields) const;
  std::expected<ValidName, IngredientError> validName(std::string_view name,
                                                      int ignoredIndex) const;
  // Writes every column of a row that exists
  void writeRow(const Ingredient& ingredient);
  // Replaces the ingredient at `index` with `changed` and notifies, unless
  // nothing differs
  void update(int index, Ingredient changed);

  template<typename Mutation>
  void apply(const IngredientChange& change, Mutation mutate) noexcept;

  Database& m_db;
  Clock m_clock;
  const AisleStore& m_aisles;
  UuidV7Generator m_ids;
  std::vector<Ingredient> m_ingredients;
  Observers<IngredientObserver> m_observers;
};

}
