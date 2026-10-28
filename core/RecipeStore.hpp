#pragma once

#include "core/Observers.hpp"
#include "core/Recipe.hpp"
#include "core/UuidV7Generator.hpp"
#include "core/clock.hpp"

#include <chrono>
#include <expected>
#include <optional>
#include <string>
#include <string_view>
#include <variant>
#include <vector>

namespace core {

class Database;
class IngredientStore;
class TagStore;

// Validation failures the user can fix
enum class RecipeError
{
  EmptyTitle,          // blank once trimmed
  EmptyIngredientName, // an ingredient's name is blank once trimmed and folded
  EmptyStep,           // a step's text is blank once trimmed
};

// What RecipeUpdated changed. Not RecipeField: that's the fields the user can
// hide (recipeFields.hpp).
enum class RecipeDetail
{
  Favorite,
  // The cook count and the last cooked date
  CookingHistory
};

// Changes to RecipeStore::recipes(), by index in that list
struct RecipeInserted
{
  int index;
  bool operator==(const RecipeInserted&) const = default;
};

struct RecipeRemoved
{
  int index;
  bool operator==(const RecipeRemoved&) const = default;
};

struct RecipeUpdated
{
  int index;
  RecipeDetail detail;
  bool operator==(const RecipeUpdated&) const = default;
};

using RecipeChange = std::variant<RecipeInserted, RecipeRemoved, RecipeUpdated>;

// Called like AisleObserver's functions: before memory changes, then after
class RecipeObserver
{
public:
  virtual void recipeAboutToChange(const RecipeChange& change) noexcept = 0;
  virtual void recipeChanged(const RecipeChange& change) noexcept = 0;

protected:
  ~RecipeObserver() = default;
};

// How many times a recipe was cooked, and the last time
struct CookingHistory
{
  int count = 0;
  std::optional<std::chrono::year_month_day> lastCooked;

  bool operator==(const CookingHistory&) const = default;
};

// Live recipes in id order, which is creation order, with their ingredients,
// steps and tag links: the recipe table and its four child tables, read and
// written together. Held in memory and written through to SQLite like
// AisleStore's aisles. A child row is live while its own deleted flag is 0;
// deleting a recipe only flags the recipe row, so restore() finds its children
// as they were.
//
// Loading drops what a recipe can't show: substitutes without a live main
// ingredient, mentions of an ingredient that isn't a live main one of the
// recipe, mentions outside their step's text or overlapping another one. The
// step's text keeps every word.
//
// Programming errors throw std::logic_error subclasses before anything
// changes: unknown id, a draft that breaks a rule its fields document, or a
// change requested from inside a notification.
class RecipeStore
{
public:
  // The database must be migrated; `ingredients` and `tags` must outlive the
  // store
  RecipeStore(Database& db,
              Clock clock,
              IngredientStore& ingredients,
              const TagStore& tags);
  RecipeStore(const RecipeStore&) = delete;
  RecipeStore& operator=(const RecipeStore&) = delete;

  const std::vector<Recipe>& recipes() const { return m_recipes; }
  // Whether the recipe table has any row, deleted recipes included
  bool hasRows() const;

  // Links each ingredient to the dictionary ingredient with its canonical
  // name, adding one outside the catalog when there's none: those stay even
  // if writing the recipe then fails. Text fields are trimmed, and blank ones
  // dropped, except step texts, which mentions count in. Returns the id.
  [[nodiscard]] std::expected<std::string, RecipeError> create(
    const RecipeDraft& draft);
  void setFavorite(std::string_view id, bool favorite);
  // One more time cooked, last on `today`, a local date. Returns the history
  // before, for setCookingHistory() to undo it.
  CookingHistory markCooked(std::string_view id,
                            std::chrono::year_month_day today);
  // A count of 0 or more
  void setCookingHistory(std::string_view id, const CookingHistory& history);
  // Soft delete: only the recipe row is flagged deleted
  void remove(std::string_view id);
  void restore(std::string_view id);

  // The live recipes that carry the tag
  int recipeCount(std::string_view tagId) const;

  // Not owned: an observer must unregister before it's destroyed
  void addObserver(RecipeObserver& observer);
  void removeObserver(RecipeObserver& observer);

private:
  // The recipes with `deleted`, all of them or the one with this id
  std::vector<Recipe> load(std::optional<std::string_view> id,
                           bool deleted) const;
  // The draft's fields, cleaned. Throws std::invalid_argument when the draft
  // breaks a rule its fields document.
  std::expected<RecipeFields, RecipeError> validated(
    const RecipeDraft& draft) const;
  // The draft's rows, with their ids and dictionary links
  Recipe built(const RecipeDraft& draft,
               RecipeFields fields,
               const std::vector<std::string>& ingredientIds);
  // Writes every row of a new recipe, in one transaction
  void insert(const Recipe& recipe);
  void writeCookingHistory(int index, const CookingHistory& history);

  int indexOf(std::string_view id) const;
  // Where a recipe with this id goes, to keep id order
  int insertionIndex(std::string_view id) const;
  void checkNotNotifying() const;

  template<typename Mutation>
  void apply(const RecipeChange& change, Mutation mutate) noexcept;

  Database& m_db;
  Clock m_clock;
  IngredientStore& m_ingredients;
  const TagStore& m_tags;
  UuidV7Generator m_ids;
  std::vector<Recipe> m_recipes;
  Observers<RecipeObserver> m_observers;
};

}
