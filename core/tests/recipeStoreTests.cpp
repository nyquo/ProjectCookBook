#include "core/AisleStore.hpp"
#include "core/IngredientStore.hpp"
#include "core/RecipeStore.hpp"
#include "core/TagStore.hpp"
#include "core/recipeView.hpp"
#include "testSupport.hpp"

#include <doctest/doctest.h>
#include <sqlite3.h>

#include <algorithm>
#include <limits>
#include <stdexcept>

using core::CookingHistory;
using core::RecipeDetail;
using core::RecipeError;
using core::Unit;
using namespace std::chrono_literals;

namespace {

struct Notification
{
  bool changed; // false: about to change
  core::RecipeChange change;
  std::size_t sizeSeen;

  bool operator==(const Notification&) const = default;
};

class RecordingObserver final : public core::RecipeObserver
{
public:
  explicit RecordingObserver(core::RecipeStore& store)
    : m_store(store)
  {
    m_store.addObserver(*this);
  }
  ~RecordingObserver() { m_store.removeObserver(*this); }

  void recipeAboutToChange(const core::RecipeChange& change) noexcept override
  {
    notifications.push_back({ false, change, m_store.recipes().size() });
  }
  void recipeChanged(const core::RecipeChange& change) noexcept override
  {
    notifications.push_back({ true, change, m_store.recipes().size() });
  }

  std::vector<Notification> notifications;

private:
  core::RecipeStore& m_store;
};

std::vector<Notification> notificationsFor(core::RecipeChange change,
                                           std::size_t sizeBefore,
                                           std::size_t sizeAfter)
{
  return { { false, change, sizeBefore }, { true, change, sizeAfter } };
}

// A title, a serving and one ingredient
core::RecipeDraft toast()
{
  core::RecipeDraft draft;
  draft.title = "Toast";
  draft.baseServings = 1;
  draft.ingredients = {
    { .name = "Bread", .quantity = 2, .unit = Unit::Pieces }
  };
  return draft;
}

// Every kind of row: a main ingredient with a note, one with a substitute,
// an optional one, one to taste, one in free text only; a mention with and
// without a quantity, an ingredient split across two steps, a step without
// mentions
core::RecipeDraft gratin(std::vector<std::string> tagIds)
{
  core::RecipeDraft draft;
  draft.title = "Gratin dauphinois";
  draft.description = "Potatoes baked slowly in cream.";
  draft.photoId = std::string(64, 'a');
  draft.baseServings = 6;
  draft.prepMinutes = 20;
  draft.cookMinutes = 75;
  draft.costCents = 850;
  draft.source = "Grandma";
  draft.notes = "Use a wide dish.";
  draft.favorite = true;
  draft.cookCount = 4;
  draft.lastCooked = 2026y / 5 / 30;
  draft.lastPlannedServings = 4;
  draft.ingredients = {
    { .name = "Potatoes",
      .quantity = 1.2,
      .unit = Unit::Kilograms,
      .note = "Firm-fleshed" },
    { .name = "Heavy cream", .quantity = 20, .unit = Unit::Centiliters },
    { .name = "Garlic", .quantity = 2, .unit = Unit::Cloves },
    { .name = "Gruyère",
      .quantity = 80,
      .unit = Unit::Grams,
      .optional = true },
    { .name = "Salt" },
    { .name = "Basil", .unit = std::string("a handful") },
    // A substitute listed after the others: it still follows the cream
    { .name = "Crème fraîche",
      .quantity = 20,
      .unit = Unit::Centiliters,
      .note = "Full fat",
      .substituteFor = 1 },
  };
  draft.steps = {
    { .text = "Slice the potatoes thin.",
      .mentions = { { .ingredient = 0, .start = 10, .length = 8 } } },
    { .text = "Simmer the cream with a garlic clove.",
      .mentions = { { .ingredient = 2,
                      .start = 24,
                      .length = 12,
                      .quantity = 1 },
                    { .ingredient = 1, .start = 11, .length = 5 } } },
    { .text = "Rub the dish with the remaining garlic.",
      .mentions = { { .ingredient = 2,
                      .start = 18,
                      .length = 20,
                      .quantity = 1 } } },
    { .text = "Bake for 1 h 15." },
  };
  draft.tagIds = std::move(tagIds);
  return draft;
}

struct Fixture
{
  test::FakeClock clock;
  core::Database db{ ":memory:" };
  core::AisleStore aisles{ test::migrated(db), clock.function() };
  core::IngredientStore ingredients{ db, clock.function(), aisles };
  core::TagStore tags{ db, clock.function() };
  core::RecipeStore store{ db, clock.function(), ingredients, tags };
  RecordingObserver observer{ store };

  std::string tag(std::string_view name)
  {
    const auto id = tags.create(name);
    REQUIRE(id);
    return *id;
  }

  // Created a minute after the previous one, so ids sort by creation
  std::string create(const core::RecipeDraft& draft)
  {
    clock.now += 1min;
    const auto id = store.create(draft);
    REQUIRE(id);
    return *id;
  }

  const core::Recipe& recipe(std::string_view id) const
  {
    const auto& recipes = store.recipes();
    const auto it = std::ranges::find(recipes, id, &core::Recipe::id);
    REQUIRE(it != recipes.end());
    return *it;
  }

  std::string dictionaryIdOf(std::string_view canonicalName) const
  {
    const auto& all = ingredients.ingredients();
    const auto it =
      std::ranges::find(all, canonicalName, &core::Ingredient::canonicalName);
    REQUIRE(it != all.end());
    return it->id;
  }

  core::RecipeStore reloaded()
  {
    return core::RecipeStore(db, core::systemNow, ingredients, tags);
  }

  bool reloadMatches()
  {
    const core::RecipeStore again(db, core::systemNow, ingredients, tags);
    return again.recipes() == store.recipes();
  }

  // Rows of a table, as "column|column|…" texts, for comparisons
  std::vector<std::string> rows(std::string_view sql)
  {
    core::Statement select = db.prepare(sql);
    std::vector<std::string> result;
    while (select.step()) {
      result.push_back(select.columnText(0));
    }
    return result;
  }
};

// `write` must fail, because of a trigger the test installed
void checkFailedWriteChangesNothing(Fixture& f, auto&& write)
{
  const auto before = f.store.recipes();
  const auto rowsBefore =
    f.rows("SELECT id || deleted || favorite || cook_count FROM recipe");
  f.observer.notifications.clear();

  CHECK(test::errorCode(write) == SQLITE_CONSTRAINT_TRIGGER);
  CHECK(f.store.recipes() == before);
  CHECK(f.rows("SELECT id || deleted || favorite || cook_count FROM recipe") ==
        rowsBefore);
  CHECK(f.reloadMatches());
  CHECK(f.observer.notifications.empty());
}

}

TEST_CASE_FIXTURE(Fixture, "A new database has no recipes")
{
  CHECK(store.recipes().empty());
  CHECK_FALSE(store.hasRows());
}

TEST_CASE_FIXTURE(Fixture, "create stores a recipe and every row it has")
{
  const std::string vegetarian = tag("Vegetarian");
  const std::string oven = tag("Oven");
  const std::string id = create(gratin({ vegetarian, oven }));

  CHECK(id[14] == '7');
  CHECK(store.hasRows());
  CHECK(observer.notifications ==
        notificationsFor(core::RecipeInserted{ 0 }, 0, 1));

  const core::Recipe& stored = recipe(id);
  CHECK(static_cast<const core::RecipeFields&>(stored) ==
        static_cast<const core::RecipeFields&>(gratin({})));
  CHECK(stored.createdAt == clock.now);
  CHECK(stored.modifiedAt == clock.now);
  CHECK(stored.tagIds ==
        std::vector{ std::min(vegetarian, oven), std::max(vegetarian, oven) });

  // Main ingredients in order, the substitute after its main ingredient
  std::vector<std::string> names;
  for (const core::RecipeIngredient& line : stored.ingredients) {
    names.push_back(line.name);
  }
  CHECK(names == std::vector<std::string>{ "Potatoes",
                                           "Heavy cream",
                                           "Crème fraîche",
                                           "Garlic",
                                           "Gruyère",
                                           "Salt",
                                           "Basil" });
  const auto& lines = stored.ingredients;
  CHECK(lines[0].quantity == 1.2);
  CHECK(lines[0].unit == core::RecipeUnit(Unit::Kilograms));
  CHECK(lines[0].note == "Firm-fleshed");
  CHECK(lines[2].parentId == lines[1].id);
  CHECK(lines[2].note == "Full fat");
  CHECK(lines[4].optional);
  CHECK_FALSE(lines[5].quantity);
  CHECK_FALSE(lines[5].unit);
  CHECK(lines[6].unit == core::RecipeUnit("a handful"));

  // Mentions point to rows, in text order
  REQUIRE(stored.steps.size() == 4);
  const auto& simmer = stored.steps[1].mentions;
  REQUIRE(simmer.size() == 2);
  CHECK(simmer[0].recipeIngredientId == lines[1].id);
  CHECK(simmer[0].start == 11);
  CHECK_FALSE(simmer[0].quantity);
  CHECK(simmer[1].recipeIngredientId == lines[3].id);
  CHECK(simmer[1].quantity == 1.0);
  CHECK(stored.steps[3].mentions.empty());

  CHECK(reloadMatches());
}

TEST_CASE_FIXTURE(Fixture, "Every table round-trips its columns")
{
  const std::string vegetarian = tag("Vegetarian");
  const std::string id = create(gratin({ vegetarian }));

  CHECK(rows("SELECT title || '|' || description || '|' || photo_id || '|' "
             "|| base_servings || '|' || prep_minutes || '|' || cook_minutes "
             "|| '|' || cost_cents || '|' || source || '|' || notes || '|' "
             "|| favorite || '|' || cook_count || '|' || last_cooked || '|' "
             "|| last_planned_servings || '|' || deleted FROM recipe") ==
        std::vector<std::string>{ "Gratin dauphinois|Potatoes baked slowly in "
                                  "cream.|" +
                                  std::string(64, 'a') +
                                  "|6|20|75|850|Grandma|Use a wide "
                                  "dish.|1|4|2026-05-30|4|0" });
  // Positions count among siblings
  CHECK(rows("SELECT name || '|' || (parent_id IS NOT NULL) || '|' || "
             "position || '|' || ifnull(quantity, '') || '|' || "
             "ifnull(unit, '') || '|' || ifnull(unit_text, '') || '|' || "
             "optional FROM recipe_ingredient "
             "ORDER BY parent_id IS NOT NULL, position") ==
        std::vector<std::string>{ "Potatoes|0|0|1.2|kg||0",
                                  "Heavy cream|0|1|20.0|cl||0",
                                  "Garlic|0|2|2.0|clove||0",
                                  "Gruyère|0|3|80.0|g||1",
                                  "Salt|0|4||||0",
                                  "Basil|0|5|||a handful|0",
                                  "Crème fraîche|1|0|20.0|cl||0" });
  CHECK(rows("SELECT position || '|' || text FROM step ORDER BY position") ==
        std::vector<std::string>{ "0|Slice the potatoes thin.",
                                  "1|Simmer the cream with a garlic clove.",
                                  "2|Rub the dish with the remaining garlic.",
                                  "3|Bake for 1 h 15." });
  CHECK(rows("SELECT i.name || '|' || m.start || '|' || m.length || '|' || "
             "ifnull(m.quantity, '') FROM step_mention m "
             "JOIN recipe_ingredient i ON i.id = m.recipe_ingredient_id "
             "JOIN step s ON s.id = m.step_id ORDER BY s.position, m.start") ==
        std::vector<std::string>{ "Potatoes|10|8|",
                                  "Heavy cream|11|5|",
                                  "Garlic|24|12|1.0",
                                  "Garlic|18|20|1.0" });
  CHECK(rows("SELECT recipe_id || tag_id FROM recipe_tag") ==
        std::vector{ id + vegetarian });
  // Every row's modified_at is the creation time
  CHECK(rows("SELECT DISTINCT modified_at FROM recipe UNION SELECT "
             "modified_at FROM recipe_ingredient UNION SELECT modified_at "
             "FROM step UNION SELECT modified_at FROM step_mention UNION "
             "SELECT modified_at FROM recipe_tag") ==
        std::vector{ std::to_string(core::toMillis(clock.now)) });
}

TEST_CASE_FIXTURE(Fixture,
                  "create links ingredients to the dictionary by canonical "
                  "name, adding the missing ones outside the catalog")
{
  const std::size_t seeded = ingredients.ingredients().size();
  const std::string id = create(gratin({}));

  // Potatoes, Crème fraîche, Garlic and Basil are catalog items; Heavy
  // cream, Gruyère and Salt are new
  CHECK(ingredients.ingredients().size() == seeded + 3);
  // A copy: creating another recipe below moves the store's recipes
  const auto lines = recipe(id).ingredients;
  CHECK(lines[0].ingredientId == dictionaryIdOf("potatoes"));
  CHECK(lines[2].ingredientId == dictionaryIdOf("creme fraiche"));
  CHECK(lines[3].ingredientId == dictionaryIdOf("garlic"));
  CHECK(lines[1].ingredientId == dictionaryIdOf("heavy cream"));
  for (const auto& ingredient : ingredients.ingredients()) {
    if (ingredient.canonicalName == "heavy cream") {
      CHECK_FALSE(ingredient.inCatalog);
      CHECK(ingredient.name == "Heavy cream");
    }
  }

  // Another spelling of the same names adds nothing
  core::RecipeDraft again = toast();
  again.ingredients = {
    { .name = " HEAVY  Cream ", .quantity = 1, .unit = Unit::Cups },
    { .name = "gruyere", .quantity = 1, .unit = Unit::Ounces }
  };
  const std::string other = create(again);
  CHECK(ingredients.ingredients().size() == seeded + 3);
  CHECK(recipe(other).ingredients[0].ingredientId == lines[1].ingredientId);
  CHECK(recipe(other).ingredients[0].name == "HEAVY  Cream");
}

TEST_CASE_FIXTURE(Fixture, "create trims text fields and drops blank ones")
{
  core::RecipeDraft draft = toast();
  draft.title = "  Toast\t";
  draft.description = "   ";
  draft.source = " Me ";
  draft.notes = "";
  draft.ingredients = {
    { .name = " Bread ", .quantity = 2, .unit = Unit::Pieces, .note = "  " },
    { .name = "Herbs", .unit = std::string("  ") },
    { .name = "Chives", .quantity = 1, .unit = std::string(" handful ") }
  };
  const std::string id = create(draft);

  const core::Recipe& stored = recipe(id);
  CHECK(stored.title == "Toast");
  CHECK_FALSE(stored.description);
  CHECK(stored.source == "Me");
  CHECK_FALSE(stored.notes);
  CHECK(stored.ingredients[0].name == "Bread");
  CHECK_FALSE(stored.ingredients[0].note);
  CHECK_FALSE(stored.ingredients[1].unit);
  CHECK(stored.ingredients[2].unit == core::RecipeUnit("handful"));
  CHECK(reloadMatches());
}

TEST_CASE_FIXTURE(Fixture,
                  "create rejects a blank title, ingredient name or step")
{
  const std::size_t seeded = ingredients.ingredients().size();
  const auto fails = [&](auto&& change) {
    core::RecipeDraft draft = gratin({});
    change(draft);
    return store.create(draft);
  };

  CHECK(fails([](auto& d) { d.title = " \t"; }) ==
        std::unexpected(RecipeError::EmptyTitle));
  CHECK(fails([](auto& d) { d.ingredients[4].name = "  "; }) ==
        std::unexpected(RecipeError::EmptyIngredientName));
  CHECK(fails([](auto& d) { d.steps[3].text = "\n"; }) ==
        std::unexpected(RecipeError::EmptyStep));

  CHECK_FALSE(store.hasRows());
  // Validation comes before any dictionary entry is added
  CHECK(ingredients.ingredients().size() == seeded);
  CHECK(observer.notifications.empty());
}

TEST_CASE_FIXTURE(Fixture,
                  "create refuses drafts that break their rules, before "
                  "writing anything")
{
  const std::string vegetarian = tag("Vegetarian");
  const std::string removed = tag("Removed");
  tags.remove(removed);
  const std::size_t seeded = ingredients.ingredients().size();
  const auto throws = [&](auto&& change) {
    core::RecipeDraft draft = gratin({ vegetarian });
    change(draft);
    CHECK_THROWS_AS((void)store.create(draft), std::invalid_argument);
  };
  const double nan = std::numeric_limits<double>::quiet_NaN();

  throws([](auto& d) { d.baseServings = 0; });
  throws([](auto& d) { d.prepMinutes = -1; });
  throws([](auto& d) { d.cookMinutes = -1; });
  throws([](auto& d) { d.costCents = -1; });
  throws([](auto& d) { d.cookCount = -1; });
  throws([](auto& d) { d.lastCooked = 2026y / 2 / 30; });
  throws([](auto& d) { d.lastPlannedServings = 0; });
  throws([](auto& d) { d.photoId = "abc"; });
  throws([](auto& d) { d.photoId = std::string(64, 'A'); });
  throws([](auto& d) { d.ingredients[0].quantity = 0; });
  throws([&](auto& d) { d.ingredients[0].quantity = nan; });
  // A quantity needs a unit; a unit needs a quantity
  throws([](auto& d) { d.ingredients[0].unit = std::nullopt; });
  throws([](auto& d) { d.ingredients[0].unit = std::string(" "); });
  throws([](auto& d) { d.ingredients[4].unit = Unit::Grams; });
  // A substitute replaces a main ingredient
  throws([](auto& d) { d.ingredients[0].substituteFor = 6; });
  throws([](auto& d) { d.ingredients[0].substituteFor = 0; });
  throws([](auto& d) { d.ingredients[0].substituteFor = 9; });
  // Mentions name main ingredients, inside the text, without overlaps
  throws([](auto& d) { d.steps[0].mentions[0].ingredient = 6; });
  throws([](auto& d) { d.steps[0].mentions[0].ingredient = 9; });
  throws([](auto& d) { d.steps[0].mentions[0].length = 0; });
  throws([](auto& d) { d.steps[0].mentions[0].start = -1; });
  throws([](auto& d) { d.steps[0].mentions[0].start = 20; });
  throws([](auto& d) { d.steps[1].mentions[1].length = 15; });
  throws([](auto& d) { d.steps[1].mentions[0].quantity = -1; });
  // Live tags, once each
  throws([](auto& d) { d.tagIds.push_back("unknown"); });
  throws([&](auto& d) { d.tagIds.push_back(removed); });
  throws([&](auto& d) { d.tagIds.push_back(vegetarian); });

  CHECK_FALSE(store.hasRows());
  CHECK(ingredients.ingredients().size() == seeded);
  CHECK(observer.notifications.empty());
}

TEST_CASE_FIXTURE(Fixture, "setFavorite writes and notifies only a change")
{
  const std::string id = create(toast());
  observer.notifications.clear();
  clock.now += 1min;

  store.setFavorite(id, true);
  CHECK(recipe(id).favorite);
  CHECK(recipe(id).modifiedAt == clock.now);
  CHECK(
    observer.notifications ==
    notificationsFor(core::RecipeUpdated{ 0, RecipeDetail::Favorite }, 1, 1));
  CHECK(reloadMatches());

  observer.notifications.clear();
  store.setFavorite(id, true);
  CHECK(observer.notifications.empty());
  store.setFavorite(id, false);
  CHECK_FALSE(recipe(id).favorite);
  CHECK(reloadMatches());
}

TEST_CASE_FIXTURE(Fixture,
                  "markCooked counts one more time, today; undoing it puts "
                  "the history back")
{
  core::RecipeDraft draft = toast();
  draft.cookCount = 4;
  draft.lastCooked = 2026y / 5 / 30;
  const std::string id = create(draft);
  observer.notifications.clear();
  clock.now += 1min;

  const CookingHistory before = store.markCooked(id, 2026y / 10 / 28);
  CHECK(before == CookingHistory{ 4, 2026y / 5 / 30 });
  CHECK(recipe(id).cookCount == 5);
  CHECK(recipe(id).lastCooked == 2026y / 10 / 28);
  CHECK(recipe(id).modifiedAt == clock.now);
  CHECK(observer.notifications ==
        notificationsFor(
          core::RecipeUpdated{ 0, RecipeDetail::CookingHistory }, 1, 1));
  CHECK(rows("SELECT cook_count || '|' || last_cooked FROM recipe") ==
        std::vector<std::string>{ "5|2026-10-28" });
  CHECK(reloadMatches());

  store.setCookingHistory(id, before);
  CHECK(recipe(id).cookCount == 4);
  CHECK(recipe(id).lastCooked == 2026y / 5 / 30);
  CHECK(reloadMatches());

  // Never cooked: undoing leaves no date
  const std::string fresh = create(toast());
  const CookingHistory none = store.markCooked(fresh, 2026y / 10 / 28);
  CHECK(none == CookingHistory{});
  store.setCookingHistory(fresh, none);
  CHECK(recipe(fresh).cookCount == 0);
  CHECK_FALSE(recipe(fresh).lastCooked);
  CHECK(rows("SELECT ifnull(last_cooked, 'none') FROM recipe ORDER BY id") ==
        std::vector<std::string>{ "2026-05-30", "none" });
  CHECK(reloadMatches());
}

TEST_CASE_FIXTURE(Fixture,
                  "remove flags the recipe only; restore brings it back as "
                  "it was")
{
  const std::string vegetarian = tag("Vegetarian");
  const std::string first = create(gratin({ vegetarian }));
  const std::string second = create(toast());
  core::Recipe before = recipe(first);
  const auto childRows =
    rows("SELECT id || deleted FROM recipe_ingredient UNION ALL SELECT id || "
         "deleted FROM step UNION ALL SELECT id || deleted FROM step_mention "
         "UNION ALL SELECT id || deleted FROM recipe_tag");
  observer.notifications.clear();
  clock.now += 1min;

  store.remove(first);
  CHECK(store.recipes().size() == 1);
  CHECK(store.recipes()[0].id == second);
  CHECK(store.hasRows());
  CHECK(store.recipeCount(vegetarian) == 0);
  CHECK(observer.notifications ==
        notificationsFor(core::RecipeRemoved{ 0 }, 2, 1));
  CHECK(rows("SELECT deleted FROM recipe ORDER BY id") ==
        std::vector<std::string>{ "1", "0" });
  CHECK(rows("SELECT id || deleted FROM recipe_ingredient UNION ALL SELECT "
             "id || deleted FROM step UNION ALL SELECT id || deleted FROM "
             "step_mention UNION ALL SELECT id || deleted FROM recipe_tag") ==
        childRows);
  CHECK(reloadMatches());

  observer.notifications.clear();
  clock.now += 1min;
  store.restore(first);
  before.modifiedAt = clock.now;
  CHECK(recipe(first) == before);
  CHECK(store.recipes()[0].id == first);
  CHECK(store.recipeCount(vegetarian) == 1);
  CHECK(observer.notifications ==
        notificationsFor(core::RecipeInserted{ 0 }, 1, 2));
  CHECK(reloadMatches());
}

TEST_CASE_FIXTURE(Fixture,
                  "recipeCount counts the live recipes that carry a tag")
{
  const std::string vegetarian = tag("Vegetarian");
  const std::string oven = tag("Oven");
  CHECK(store.recipeCount(vegetarian) == 0);

  core::RecipeDraft both = toast();
  both.tagIds = { vegetarian, oven };
  const std::string first = create(both);
  core::RecipeDraft one = toast();
  one.tagIds = { vegetarian };
  create(one);
  CHECK(store.recipeCount(vegetarian) == 2);
  CHECK(store.recipeCount(oven) == 1);

  store.remove(first);
  CHECK(store.recipeCount(vegetarian) == 1);
  CHECK(store.recipeCount(oven) == 0);

  // Deleting a tag keeps its links, for Undo: screens show live tags only
  tags.remove(vegetarian);
  CHECK(store.recipeCount(vegetarian) == 1);
  CHECK(reloaded().recipeCount(vegetarian) == 1);
}

TEST_CASE_FIXTURE(Fixture,
                  "Loading drops mentions of deleted ingredients; the text "
                  "keeps every word")
{
  const std::string id = create(gratin({}));
  // Deleted rows, as an edit will leave them: the garlic, and the cream,
  // which takes its substitute along
  db.exec("UPDATE recipe_ingredient SET deleted = 1 "
          "WHERE name IN ('Garlic', 'Heavy cream')");

  const core::RecipeStore again = reloaded();
  const core::Recipe& loaded = again.recipes().at(0);
  CHECK(loaded.id == id);
  std::vector<std::string> names;
  for (const core::RecipeIngredient& line : loaded.ingredients) {
    names.push_back(line.name);
  }
  CHECK(names ==
        std::vector<std::string>{ "Potatoes", "Gruyère", "Salt", "Basil" });
  REQUIRE(loaded.steps.size() == 4);
  CHECK(loaded.steps[0].mentions.size() == 1);
  CHECK(loaded.steps[1].mentions.empty());
  CHECK(loaded.steps[2].mentions.empty());
  CHECK(core::stepSegments(loaded, loaded.steps[2]) ==
        std::vector<core::StepSegment>{
          { "Rub the dish with the remaining garlic." } });
  CHECK(core::stepAmounts(loaded, loaded.steps[2]).empty());
}

TEST_CASE_FIXTURE(Fixture,
                  "Loading drops mentions outside their text or overlapping")
{
  create(gratin({}));
  db.exec("UPDATE step_mention SET start = 30 WHERE start = 10;"
          "UPDATE step_mention SET start = 14 WHERE start = 24");

  const core::RecipeStore again = reloaded();
  const core::Recipe& loaded = again.recipes().at(0);
  // "potatoes" now ends past the text; the garlic overlaps the cream, 11 to 15
  CHECK(loaded.steps[0].mentions.empty());
  CHECK(loaded.steps[1].mentions.size() == 1);
}

TEST_CASE_FIXTURE(Fixture, "Loading refuses a date or a unit it can't read")
{
  create(gratin({}));
  // Only a write that bypassed the CHECK constraints could store them
  SUBCASE("date")
  {
    db.exec("PRAGMA ignore_check_constraints = ON;"
            "UPDATE recipe SET last_cooked = '2026-02-30'");
  }
  SUBCASE("unit")
  {
    db.exec("PRAGMA ignore_check_constraints = ON;"
            "UPDATE recipe_ingredient SET unit = 'cuillere' "
            "WHERE unit = 'kg'");
  }
  CHECK(test::errorCode([&] { (void)reloaded(); }) == SQLITE_CORRUPT);
}

TEST_CASE_FIXTURE(Fixture, "The recipe tables themselves reject invalid rows")
{
  const std::string id = create(gratin({}));
  const std::string bread = dictionaryIdOf("bread");
  const auto insertRecipe = [&](std::string_view lastCooked,
                                std::string_view photoId) {
    return test::errorCode([&] {
      db.prepare("INSERT INTO recipe (id, title, photo_id, last_cooked, "
                 "created_at, modified_at) VALUES ('r', 'T', ?2, ?1, 0, 0)")
        .bind(1, lastCooked)
        .bind(2, photoId)
        .run();
    });
  };
  const std::string photo(64, 'a');
  CHECK(insertRecipe("2026-02-30", photo) == SQLITE_CONSTRAINT_CHECK);
  CHECK(insertRecipe("2026-2-3", photo) == SQLITE_CONSTRAINT_CHECK);
  CHECK(insertRecipe("2026-10-28", std::string(64, 'A')) ==
        SQLITE_CONSTRAINT_CHECK);
  CHECK(insertRecipe("2026-10-28", photo) == SQLITE_OK);

  const auto insertLine = [&](std::optional<double> quantity,
                              std::optional<std::string_view> unit,
                              std::optional<std::string_view> unitText) {
    return test::errorCode([&] {
      db.prepare("INSERT INTO recipe_ingredient (id, recipe_id, position, "
                 "quantity, unit, unit_text, name, ingredient_id, "
                 "modified_at) VALUES (lower(hex(randomblob(16))), ?1, 0, "
                 "?2, ?3, ?4, 'Bread', ?5, 0)")
        .bind(1, id)
        .bind(2, quantity)
        .bind(3, unit)
        .bind(4, unitText)
        .bind(5, bread)
        .run();
    });
  };
  CHECK(insertLine(2, std::nullopt, std::nullopt) == SQLITE_CONSTRAINT_CHECK);
  CHECK(insertLine(std::nullopt, "g", std::nullopt) == SQLITE_CONSTRAINT_CHECK);
  CHECK(insertLine(2, "g", "handfuls") == SQLITE_CONSTRAINT_CHECK);
  CHECK(insertLine(2, "spoonful", std::nullopt) == SQLITE_CONSTRAINT_CHECK);
  CHECK(insertLine(0, "g", std::nullopt) == SQLITE_CONSTRAINT_CHECK);
  CHECK(insertLine(2, "g", std::nullopt) == SQLITE_OK);
  CHECK(insertLine(2, std::nullopt, "handfuls") == SQLITE_OK);
  CHECK(insertLine(std::nullopt, std::nullopt, "a handful") == SQLITE_OK);
  CHECK(insertLine(std::nullopt, std::nullopt, std::nullopt) == SQLITE_OK);

  // A recipe carries a live tag once
  const std::string vegetarian = tag("Vegetarian");
  const auto link = [&](int deleted) {
    return test::errorCode([&] {
      db.prepare("INSERT INTO recipe_tag (id, recipe_id, tag_id, "
                 "modified_at, deleted) VALUES (lower(hex(randomblob(16))), "
                 "?1, ?2, 0, ?3)")
        .bind(1, id)
        .bind(2, vegetarian)
        .bind(3, deleted)
        .run();
    });
  };
  CHECK(link(0) == SQLITE_OK);
  CHECK(link(0) == SQLITE_CONSTRAINT_UNIQUE);
  CHECK(link(1) == SQLITE_OK);
}

TEST_CASE_FIXTURE(Fixture,
                  "Unknown ids and invalid values are programming "
                  "errors")
{
  const std::string id = create(toast());

  CHECK_THROWS_AS(store.setFavorite("unknown", true), std::invalid_argument);
  CHECK_THROWS_AS((void)store.markCooked("unknown", 2026y / 10 / 28),
                  std::invalid_argument);
  CHECK_THROWS_AS((void)store.markCooked(id, 2026y / 2 / 30),
                  std::invalid_argument);
  CHECK_THROWS_AS(store.setCookingHistory("unknown", {}),
                  std::invalid_argument);
  CHECK_THROWS_AS(store.setCookingHistory(id, { -1, std::nullopt }),
                  std::invalid_argument);
  CHECK_THROWS_AS(store.remove("unknown"), std::invalid_argument);
  CHECK_THROWS_AS(store.restore("unknown"), std::invalid_argument);
  CHECK_THROWS_AS(store.restore(id), std::invalid_argument); // live
  CHECK(recipe(id).cookCount == 0);
}

TEST_CASE_FIXTURE(Fixture,
                  "A failed write changes neither the database nor memory")
{
  const std::string id = create(toast());
  // Triggers make SQLite fail in the middle of a write, as a full disk would
  SUBCASE("create")
  {
    db.exec("CREATE TRIGGER fail BEFORE INSERT ON step_mention "
            "BEGIN SELECT RAISE(ABORT, 'simulated'); END");
    checkFailedWriteChangesNothing(*this,
                                   [&] { (void)store.create(gratin({})); });
    // The transaction rolled back every row of the recipe
    CHECK(rows("SELECT id FROM recipe_ingredient").size() == 1);
    CHECK(rows("SELECT id FROM step").empty());
  }
  SUBCASE("setFavorite")
  {
    db.exec("CREATE TRIGGER fail BEFORE UPDATE OF favorite ON recipe "
            "BEGIN SELECT RAISE(ABORT, 'simulated'); END");
    checkFailedWriteChangesNothing(*this, [&] { store.setFavorite(id, true); });
  }
  SUBCASE("markCooked")
  {
    db.exec("CREATE TRIGGER fail BEFORE UPDATE OF cook_count ON recipe "
            "BEGIN SELECT RAISE(ABORT, 'simulated'); END");
    checkFailedWriteChangesNothing(
      *this, [&] { (void)store.markCooked(id, 2026y / 10 / 28); });
  }
  SUBCASE("remove")
  {
    db.exec("CREATE TRIGGER fail BEFORE UPDATE OF deleted ON recipe "
            "BEGIN SELECT RAISE(ABORT, 'simulated'); END");
    checkFailedWriteChangesNothing(*this, [&] { store.remove(id); });
  }
  SUBCASE("restore")
  {
    store.remove(id);
    db.exec("CREATE TRIGGER fail BEFORE UPDATE OF deleted ON recipe "
            "BEGIN SELECT RAISE(ABORT, 'simulated'); END");
    checkFailedWriteChangesNothing(*this, [&] { store.restore(id); });
  }
}

TEST_CASE_FIXTURE(Fixture,
                  "Changing the store from inside a notification is refused")
{
  const std::string id = create(toast());
  struct MeddlingObserver final : core::RecipeObserver
  {
    explicit MeddlingObserver(core::RecipeStore& store, std::string id)
      : store(store)
      , id(std::move(id))
    {
    }
    void recipeAboutToChange(const core::RecipeChange&) noexcept override
    {
      CHECK_THROWS_AS(store.remove(id), std::logic_error);
    }
    void recipeChanged(const core::RecipeChange&) noexcept override
    {
      CHECK_THROWS_AS((void)store.create(toast()), std::logic_error);
    }

    core::RecipeStore& store;
    std::string id;
  } meddling(store, id);
  store.addObserver(meddling);

  store.setFavorite(id, true);

  CHECK(store.recipes().size() == 1);
  store.removeObserver(meddling);
}
