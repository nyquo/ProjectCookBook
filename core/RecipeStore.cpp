#include "core/RecipeStore.hpp"

#include "core/Database.hpp"
#include "core/IngredientStore.hpp"
#include "core/TagStore.hpp"
#include "core/recipeView.hpp"
#include "core/text.hpp"

#include <sqlite3.h>

#include <algorithm>
#include <charconv>
#include <cmath>
#include <format>
#include <iterator>
#include <map>
#include <stdexcept>
#include <utility>

namespace core {

static std::optional<std::string> optionalText(const Statement& statement,
                                               int index)
{
  if (statement.columnIsNull(index)) {
    return std::nullopt;
  }
  return statement.columnText(index);
}

static std::optional<int> optionalInt(const Statement& statement, int index)
{
  if (statement.columnIsNull(index)) {
    return std::nullopt;
  }
  return static_cast<int>(statement.columnInt64(index));
}

static std::optional<double> optionalDouble(const Statement& statement,
                                            int index)
{
  if (statement.columnIsNull(index)) {
    return std::nullopt;
  }
  return statement.columnDouble(index);
}

// "2026-10-28", as the last_cooked column stores it
static std::string dateText(std::chrono::year_month_day date)
{
  return std::format("{:04}-{:02}-{:02}",
                     static_cast<int>(date.year()),
                     static_cast<unsigned>(date.month()),
                     static_cast<unsigned>(date.day()));
}

static std::optional<std::string> dateText(
  const std::optional<std::chrono::year_month_day>& date)
{
  return date ? std::optional(dateText(*date)) : std::nullopt;
}

static std::optional<std::chrono::year_month_day> dateColumn(
  const Statement& statement,
  int index)
{
  if (statement.columnIsNull(index)) {
    return std::nullopt;
  }
  const std::string text = statement.columnText(index);
  const auto number = [&](std::size_t first, std::size_t size, auto& value) {
    const char* end = text.data() + first + size;
    return std::from_chars(text.data() + first, end, value).ptr == end;
  };
  int year = 0;
  unsigned month = 0;
  unsigned day = 0;
  if (text.size() == 10 && text[4] == '-' && text[7] == '-' &&
      number(0, 4, year) && number(5, 2, month) && number(8, 2, day)) {
    const std::chrono::year_month_day date{ std::chrono::year(year),
                                            std::chrono::month(month),
                                            std::chrono::day(day) };
    if (date.ok()) {
      return date;
    }
  }
  throw DatabaseError(SQLITE_CORRUPT, "invalid date '" + text + "'");
}

static std::optional<RecipeUnit> unitColumns(const Statement& statement,
                                             int codeIndex,
                                             int textIndex)
{
  if (!statement.columnIsNull(codeIndex)) {
    const std::string code = statement.columnText(codeIndex);
    const std::optional<Unit> unit = unitFromCode(code);
    if (!unit) {
      throw DatabaseError(SQLITE_CORRUPT, "invalid unit '" + code + "'");
    }
    return *unit;
  }
  if (!statement.columnIsNull(textIndex)) {
    return statement.columnText(textIndex);
  }
  return std::nullopt;
}

// A unit as unit and unit_text store it
static void bindUnit(Statement& statement,
                     int codeIndex,
                     int textIndex,
                     const std::optional<RecipeUnit>& unit)
{
  statement.bindNull(codeIndex).bindNull(textIndex);
  if (const Unit* code = unit ? std::get_if<Unit>(&*unit) : nullptr) {
    statement.bind(codeIndex, unitCode(*code));
  } else if (const auto* text =
               unit ? std::get_if<std::string>(&*unit) : nullptr) {
    statement.bind(textIndex, *text);
  }
}

// Trimmed; none when blank
static std::optional<std::string> cleaned(
  const std::optional<std::string>& text)
{
  if (!text || trimmed(*text).empty()) {
    return std::nullopt;
  }
  return std::string(trimmed(*text));
}

// A free-text unit trimmed; none when blank
static std::optional<RecipeUnit> cleaned(const std::optional<RecipeUnit>& unit)
{
  if (const auto* text = unit ? std::get_if<std::string>(&*unit) : nullptr) {
    const std::optional<std::string> clean = cleaned(std::optional(*text));
    return clean ? std::optional<RecipeUnit>(*clean) : std::nullopt;
  }
  return unit;
}

static void check(bool valid, const char* rule)
{
  if (!valid) {
    throw std::invalid_argument(std::string("RecipeStore: ") + rule);
  }
}

static bool isQuantity(const std::optional<double>& quantity)
{
  return !quantity || (std::isfinite(*quantity) && *quantity > 0);
}

static bool isPhotoId(std::string_view id)
{
  return id.size() == 64 && std::ranges::all_of(id, [](char c) {
           return (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f');
         });
}

RecipeStore::RecipeStore(Database& db,
                         Clock clock,
                         IngredientStore& ingredients,
                         const TagStore& tags)
  : m_db(db)
  , m_clock(std::move(clock))
  , m_ingredients(ingredients)
  , m_tags(tags)
  , m_recipes(load(std::nullopt, false))
{
}

bool RecipeStore::hasRows() const
{
  Statement select = m_db.prepare("SELECT EXISTS (SELECT 1 FROM recipe)");
  return select.step() && select.columnInt64(0) != 0;
}

std::expected<std::string, RecipeError> RecipeStore::create(
  const RecipeDraft& draft)
{
  checkNotNotifying();
  auto fields = validated(draft);
  if (!fields) {
    return std::unexpected(fields.error());
  }

  // Only now that the draft is valid: these writes can't be taken back
  std::vector<std::string> ingredientIds;
  for (const IngredientDraft& ingredient : draft.ingredients) {
    auto id = m_ingredients.dictionaryId(ingredient.name);
    if (!id) {
      return std::unexpected(RecipeError::EmptyIngredientName);
    }
    ingredientIds.push_back(std::move(*id));
  }

  Recipe recipe = built(draft, std::move(*fields), ingredientIds);
  insert(recipe);

  const int index = insertionIndex(recipe.id);
  std::string id = recipe.id;
  apply(RecipeInserted{ index }, [&] {
    m_recipes.insert(m_recipes.begin() + index, std::move(recipe));
  });
  return id;
}

void RecipeStore::setFavorite(std::string_view id, bool favorite)
{
  checkNotNotifying();
  const int index = indexOf(id);
  if (m_recipes[index].favorite == favorite) {
    return;
  }

  const Timestamp now = m_clock();
  m_db
    .prepare("UPDATE recipe SET favorite = ?2, modified_at = ?3 WHERE id = ?1")
    .bind(1, id)
    .bind(2, favorite)
    .bind(3, toMillis(now))
    .run();

  apply(RecipeUpdated{ index, RecipeDetail::Favorite }, [&] {
    m_recipes[index].favorite = favorite;
    m_recipes[index].modifiedAt = now;
  });
}

CookingHistory RecipeStore::markCooked(std::string_view id,
                                       std::chrono::year_month_day today)
{
  checkNotNotifying();
  const int index = indexOf(id);
  check(today.ok(), "today is not a valid date");
  const Recipe& recipe = m_recipes[index];
  CookingHistory before{ recipe.cookCount, recipe.lastCooked };
  writeCookingHistory(index, { before.count + 1, today });
  return before;
}

void RecipeStore::setCookingHistory(std::string_view id,
                                    const CookingHistory& history)
{
  checkNotNotifying();
  const int index = indexOf(id);
  check(history.count >= 0, "a cook count is 0 or more");
  check(!history.lastCooked || history.lastCooked->ok(),
        "the last cooked date is not a valid date");
  const Recipe& recipe = m_recipes[index];
  if (CookingHistory{ recipe.cookCount, recipe.lastCooked } == history) {
    return;
  }
  writeCookingHistory(index, history);
}

void RecipeStore::remove(std::string_view id)
{
  checkNotNotifying();
  const int index = indexOf(id);

  m_db.prepare("UPDATE recipe SET deleted = 1, modified_at = ?2 WHERE id = ?1")
    .bind(1, id)
    .bind(2, toMillis(m_clock()))
    .run();

  apply(RecipeRemoved{ index },
        [&] { m_recipes.erase(m_recipes.begin() + index); });
}

void RecipeStore::restore(std::string_view id)
{
  checkNotNotifying();
  std::vector<Recipe> found = load(id, true);
  check(!found.empty(), "restore: no deleted recipe with this id");
  Recipe recipe = std::move(found.front());

  recipe.modifiedAt = m_clock();
  m_db.prepare("UPDATE recipe SET deleted = 0, modified_at = ?2 WHERE id = ?1")
    .bind(1, id)
    .bind(2, toMillis(recipe.modifiedAt))
    .run();

  const int index = insertionIndex(id);
  apply(RecipeInserted{ index }, [&] {
    m_recipes.insert(m_recipes.begin() + index, std::move(recipe));
  });
}

int RecipeStore::recipeCount(std::string_view tagId) const
{
  return static_cast<int>(std::ranges::count_if(m_recipes, [&](const auto& r) {
    return std::ranges::find(r.tagIds, tagId) != r.tagIds.end();
  }));
}

void RecipeStore::addObserver(RecipeObserver& observer)
{
  m_observers.add(observer);
}

void RecipeStore::removeObserver(RecipeObserver& observer)
{
  m_observers.remove(observer);
}

std::vector<Recipe> RecipeStore::load(std::optional<std::string_view> id,
                                      bool deleted) const
{
  std::vector<Recipe> recipes;
  {
    Statement select = m_db.prepare(
      "SELECT id, title, description, photo_id, base_servings, prep_minutes, "
      "cook_minutes, cost_cents, source, notes, favorite, cook_count, "
      "last_cooked, last_planned_servings, created_at, modified_at "
      "FROM recipe WHERE deleted = ?2 AND (?1 IS NULL OR id = ?1) "
      "ORDER BY id");
    select.bind(1, id).bind(2, deleted);
    while (select.step()) {
      Recipe recipe;
      recipe.id = select.columnText(0);
      recipe.title = select.columnText(1);
      recipe.description = optionalText(select, 2);
      recipe.photoId = optionalText(select, 3);
      recipe.baseServings = static_cast<int>(select.columnInt64(4));
      recipe.prepMinutes = optionalInt(select, 5);
      recipe.cookMinutes = optionalInt(select, 6);
      if (!select.columnIsNull(7)) {
        recipe.costCents = select.columnInt64(7);
      }
      recipe.source = optionalText(select, 8);
      recipe.notes = optionalText(select, 9);
      recipe.favorite = select.columnInt64(10) != 0;
      recipe.cookCount = static_cast<int>(select.columnInt64(11));
      recipe.lastCooked = dateColumn(select, 12);
      recipe.lastPlannedServings = optionalInt(select, 13);
      recipe.createdAt = fromMillis(select.columnInt64(14));
      recipe.modifiedAt = fromMillis(select.columnInt64(15));
      recipes.push_back(std::move(recipe));
    }
  }
  // Rows of recipes not loaded (deleted ones, or live ones) find none
  const auto recipeWithId = [&](const std::string& recipeId) -> Recipe* {
    const auto it =
      std::ranges::lower_bound(recipes, recipeId, {}, &Recipe::id);
    return it != recipes.end() && it->id == recipeId ? &*it : nullptr;
  };

  {
    // Main ingredients come first, so a substitute's main ingredient is known
    Statement select = m_db.prepare(
      "SELECT recipe_id, id, parent_id, name, ingredient_id, quantity, unit, "
      "unit_text, note, optional FROM recipe_ingredient "
      "WHERE deleted = 0 AND (?1 IS NULL OR recipe_id = ?1) "
      "ORDER BY recipe_id, parent_id IS NOT NULL, position, id");
    select.bind(1, id);
    // By main ingredient id
    std::map<std::string, std::vector<RecipeIngredient>, std::less<>>
      substitutes;
    while (select.step()) {
      Recipe* recipe = recipeWithId(select.columnText(0));
      if (!recipe) {
        continue;
      }
      RecipeIngredient line{
        select.columnText(1),      optionalText(select, 2),
        select.columnText(3),      select.columnText(4),
        optionalDouble(select, 5), unitColumns(select, 6, 7),
        optionalText(select, 8),   select.columnInt64(9) != 0
      };
      if (!line.parentId) {
        recipe->ingredients.push_back(std::move(line));
      } else if (mainIngredientIndex(*recipe, *line.parentId) >= 0) {
        substitutes[*line.parentId].push_back(std::move(line));
      }
    }
    for (Recipe& recipe : recipes) {
      std::vector<RecipeIngredient> lines;
      for (RecipeIngredient& main : recipe.ingredients) {
        const auto it = substitutes.find(main.id);
        lines.push_back(std::move(main));
        if (it != substitutes.end()) {
          std::ranges::move(it->second, std::back_inserter(lines));
        }
      }
      recipe.ingredients = std::move(lines);
    }
  }

  {
    Statement select =
      m_db.prepare("SELECT recipe_id, id, text FROM step "
                   "WHERE deleted = 0 AND (?1 IS NULL OR recipe_id = ?1) "
                   "ORDER BY recipe_id, position, id");
    select.bind(1, id);
    while (select.step()) {
      if (Recipe* recipe = recipeWithId(select.columnText(0))) {
        recipe->steps.push_back(
          { select.columnText(1), select.columnText(2), {} });
      }
    }
  }

  {
    Statement select = m_db.prepare(
      "SELECT s.recipe_id, m.step_id, m.id, m.recipe_ingredient_id, m.start, "
      "m.length, m.quantity FROM step_mention m JOIN step s ON s.id = "
      "m.step_id WHERE m.deleted = 0 AND s.deleted = 0 AND "
      "(?1 IS NULL OR s.recipe_id = ?1) ORDER BY m.step_id, m.start, m.id");
    select.bind(1, id);
    while (select.step()) {
      Recipe* recipe = recipeWithId(select.columnText(0));
      if (!recipe) {
        continue;
      }
      const std::string stepId = select.columnText(1);
      const auto step = std::ranges::find(recipe->steps, stepId, &Step::id);
      if (step == recipe->steps.end()) {
        continue;
      }
      StepMention mention{ select.columnText(2),
                           select.columnText(3),
                           static_cast<int>(select.columnInt64(4)),
                           static_cast<int>(select.columnInt64(5)),
                           optionalDouble(select, 6) };
      const int previousEnd =
        step->mentions.empty()
          ? 0
          : step->mentions.back().start + step->mentions.back().length;
      const auto textLength =
        static_cast<std::int64_t>(codePointCount(step->text));
      if (mainIngredientIndex(*recipe, mention.recipeIngredientId) >= 0 &&
          mention.start >= previousEnd && mention.length > 0 &&
          std::int64_t{ mention.start } + mention.length <= textLength) {
        step->mentions.push_back(std::move(mention));
      }
    }
  }

  {
    Statement select = m_db.prepare(
      "SELECT recipe_id, tag_id FROM recipe_tag "
      "WHERE deleted = 0 AND (?1 IS NULL OR recipe_id = ?1) ORDER BY tag_id");
    select.bind(1, id);
    while (select.step()) {
      if (Recipe* recipe = recipeWithId(select.columnText(0))) {
        recipe->tagIds.push_back(select.columnText(1));
      }
    }
  }
  return recipes;
}

std::expected<RecipeFields, RecipeError> RecipeStore::validated(
  const RecipeDraft& draft) const
{
  RecipeFields fields = draft;
  fields.title = std::string(trimmed(draft.title));
  if (fields.title.empty()) {
    return std::unexpected(RecipeError::EmptyTitle);
  }
  fields.description = cleaned(draft.description);
  fields.source = cleaned(draft.source);
  fields.notes = cleaned(draft.notes);
  check(!draft.photoId || isPhotoId(*draft.photoId),
        "a photo id is 64 lowercase hex digits");
  check(draft.baseServings >= 1, "base servings are 1 or more");
  check(!draft.prepMinutes || *draft.prepMinutes >= 0,
        "prep minutes are 0 or more");
  check(!draft.cookMinutes || *draft.cookMinutes >= 0,
        "cook minutes are 0 or more");
  check(!draft.costCents || *draft.costCents >= 0, "a cost is 0 or more");
  check(draft.cookCount >= 0, "a cook count is 0 or more");
  check(!draft.lastCooked || draft.lastCooked->ok(),
        "the last cooked date is not a valid date");
  check(!draft.lastPlannedServings || *draft.lastPlannedServings >= 1,
        "planned servings are 1 or more");

  const auto& ingredients = draft.ingredients;
  const auto isMain = [&](int index) {
    return index >= 0 && index < static_cast<int>(ingredients.size()) &&
           !ingredients[index].substituteFor;
  };
  for (std::size_t i = 0; i < ingredients.size(); ++i) {
    const IngredientDraft& ingredient = ingredients[i];
    if (canonicalName(trimmed(ingredient.name)).empty()) {
      return std::unexpected(RecipeError::EmptyIngredientName);
    }
    check(isQuantity(ingredient.quantity), "a quantity is above 0");
    const std::optional<RecipeUnit> unit = cleaned(ingredient.unit);
    if (ingredient.quantity) {
      check(unit.has_value(), "a quantity needs a unit");
    } else {
      check(!unit || std::holds_alternative<std::string>(*unit),
            "without a quantity, only a free-text unit");
    }
    check(!ingredient.substituteFor || isMain(*ingredient.substituteFor),
          "a substitute replaces a main ingredient");
  }

  for (const StepDraft& step : draft.steps) {
    if (trimmed(step.text).empty()) {
      return std::unexpected(RecipeError::EmptyStep);
    }
    std::vector<MentionDraft> mentions = step.mentions;
    std::ranges::sort(mentions, {}, &MentionDraft::start);
    const auto textLength =
      static_cast<std::int64_t>(codePointCount(step.text));
    std::int64_t previousEnd = 0;
    for (const MentionDraft& mention : mentions) {
      check(isMain(mention.ingredient), "a mention names a main ingredient");
      check(mention.start >= previousEnd && mention.length > 0 &&
              std::int64_t{ mention.start } + mention.length <= textLength,
            "mentions are words of the text, without overlaps");
      check(isQuantity(mention.quantity), "a quantity is above 0");
      previousEnd = std::int64_t{ mention.start } + mention.length;
    }
  }

  for (const std::string& tagId : draft.tagIds) {
    check(std::ranges::find(m_tags.tags(), tagId, &Tag::id) !=
            m_tags.tags().end(),
          "a recipe's tags are live tags");
    check(std::ranges::count(draft.tagIds, tagId) == 1,
          "a recipe carries a tag once");
  }
  return fields;
}

Recipe RecipeStore::built(const RecipeDraft& draft,
                          RecipeFields fields,
                          const std::vector<std::string>& ingredientIds)
{
  const Timestamp now = m_clock();
  Recipe recipe;
  static_cast<RecipeFields&>(recipe) = std::move(fields);
  recipe.id = m_ids.next(now);
  recipe.createdAt = now;
  recipe.modifiedAt = now;

  const auto& ingredients = draft.ingredients;
  std::vector<std::string> lineIds;
  for (std::size_t i = 0; i < ingredients.size(); ++i) {
    lineIds.push_back(m_ids.next(now));
  }
  const auto line = [&](std::size_t index) {
    const IngredientDraft& ingredient = ingredients[index];
    return RecipeIngredient{ lineIds[index],
                             ingredient.substituteFor
                               ? std::optional(
                                   lineIds[*ingredient.substituteFor])
                               : std::nullopt,
                             std::string(trimmed(ingredient.name)),
                             ingredientIds[index],
                             ingredient.quantity,
                             cleaned(ingredient.unit),
                             cleaned(ingredient.note),
                             ingredient.optional };
  };
  for (std::size_t main = 0; main < ingredients.size(); ++main) {
    if (ingredients[main].substituteFor) {
      continue;
    }
    recipe.ingredients.push_back(line(main));
    for (std::size_t i = 0; i < ingredients.size(); ++i) {
      if (ingredients[i].substituteFor == static_cast<int>(main)) {
        recipe.ingredients.push_back(line(i));
      }
    }
  }

  for (const StepDraft& draftStep : draft.steps) {
    Step step{ m_ids.next(now), draftStep.text, {} };
    std::vector<MentionDraft> mentions = draftStep.mentions;
    std::ranges::sort(mentions, {}, &MentionDraft::start);
    for (const MentionDraft& mention : mentions) {
      step.mentions.push_back({ m_ids.next(now),
                                lineIds[mention.ingredient],
                                mention.start,
                                mention.length,
                                mention.quantity });
    }
    recipe.steps.push_back(std::move(step));
  }
  recipe.tagIds = draft.tagIds;
  std::ranges::sort(recipe.tagIds);
  return recipe;
}

void RecipeStore::insert(const Recipe& recipe)
{
  const std::int64_t now = toMillis(recipe.modifiedAt);
  Transaction transaction(m_db);
  m_db
    .prepare("INSERT INTO recipe (id, title, description, photo_id, "
             "base_servings, prep_minutes, cook_minutes, cost_cents, source, "
             "notes, favorite, cook_count, last_cooked, last_planned_servings, "
             "created_at, modified_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, "
             "?8, ?9, ?10, ?11, ?12, ?13, ?14, ?15, ?16)")
    .bind(1, recipe.id)
    .bind(2, recipe.title)
    .bind(3, recipe.description)
    .bind(4, recipe.photoId)
    .bind(5, recipe.baseServings)
    .bind(6, recipe.prepMinutes)
    .bind(7, recipe.cookMinutes)
    .bind(8, recipe.costCents)
    .bind(9, recipe.source)
    .bind(10, recipe.notes)
    .bind(11, recipe.favorite)
    .bind(12, recipe.cookCount)
    .bind(13, dateText(recipe.lastCooked))
    .bind(14, recipe.lastPlannedServings)
    .bind(15, toMillis(recipe.createdAt))
    .bind(16, now)
    .run();

  // Positions count among siblings: main ingredients among themselves, a main
  // ingredient's substitutes among themselves
  int mainPosition = 0;
  int substitutePosition = 0;
  for (const RecipeIngredient& line : recipe.ingredients) {
    if (!line.parentId) {
      substitutePosition = 0;
    }
    Statement insertLine = m_db.prepare(
      "INSERT INTO recipe_ingredient (id, recipe_id, parent_id, position, "
      "quantity, unit, unit_text, name, ingredient_id, note, optional, "
      "modified_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, "
      "?12)");
    insertLine.bind(1, line.id)
      .bind(2, recipe.id)
      .bind(3, line.parentId)
      .bind(4, line.parentId ? substitutePosition++ : mainPosition++)
      .bind(5, line.quantity)
      .bind(8, line.name)
      .bind(9, line.ingredientId)
      .bind(10, line.note)
      .bind(11, line.optional)
      .bind(12, now);
    bindUnit(insertLine, 6, 7, line.unit);
    insertLine.run();
  }

  for (std::size_t position = 0; position < recipe.steps.size(); ++position) {
    const Step& step = recipe.steps[position];
    m_db
      .prepare("INSERT INTO step (id, recipe_id, position, text, modified_at) "
               "VALUES (?1, ?2, ?3, ?4, ?5)")
      .bind(1, step.id)
      .bind(2, recipe.id)
      .bind(3, position)
      .bind(4, step.text)
      .bind(5, now)
      .run();
    for (const StepMention& mention : step.mentions) {
      m_db
        .prepare("INSERT INTO step_mention (id, step_id, recipe_ingredient_id, "
                 "start, length, quantity, modified_at) "
                 "VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)")
        .bind(1, mention.id)
        .bind(2, step.id)
        .bind(3, mention.recipeIngredientId)
        .bind(4, mention.start)
        .bind(5, mention.length)
        .bind(6, mention.quantity)
        .bind(7, now)
        .run();
    }
  }

  for (const std::string& tagId : recipe.tagIds) {
    m_db
      .prepare("INSERT INTO recipe_tag (id, recipe_id, tag_id, modified_at) "
               "VALUES (?1, ?2, ?3, ?4)")
      .bind(1, m_ids.next(recipe.modifiedAt))
      .bind(2, recipe.id)
      .bind(3, tagId)
      .bind(4, now)
      .run();
  }
  transaction.commit();
}

void RecipeStore::writeCookingHistory(int index, const CookingHistory& history)
{
  const Timestamp now = m_clock();
  m_db
    .prepare("UPDATE recipe SET cook_count = ?2, last_cooked = ?3, "
             "modified_at = ?4 WHERE id = ?1")
    .bind(1, m_recipes[index].id)
    .bind(2, history.count)
    .bind(3, dateText(history.lastCooked))
    .bind(4, toMillis(now))
    .run();

  apply(RecipeUpdated{ index, RecipeDetail::CookingHistory }, [&] {
    Recipe& recipe = m_recipes[index];
    recipe.cookCount = history.count;
    recipe.lastCooked = history.lastCooked;
    recipe.modifiedAt = now;
  });
}

int RecipeStore::indexOf(std::string_view id) const
{
  const auto it = std::ranges::find(m_recipes, id, &Recipe::id);
  if (it == m_recipes.end()) {
    throw std::invalid_argument("RecipeStore: no live recipe with this id");
  }
  return static_cast<int>(it - m_recipes.begin());
}

int RecipeStore::insertionIndex(std::string_view id) const
{
  const auto it = std::ranges::lower_bound(m_recipes, id, {}, &Recipe::id);
  return static_cast<int>(it - m_recipes.begin());
}

void RecipeStore::checkNotNotifying() const
{
  if (m_observers.notifying()) {
    throw std::logic_error(
      "RecipeStore: no changes from inside an observer notification");
  }
}

template<typename Mutation>
void RecipeStore::apply(const RecipeChange& change, Mutation mutate) noexcept
{
  m_observers.notify(
    [&](RecipeObserver& observer) { observer.recipeAboutToChange(change); },
    mutate,
    [&](RecipeObserver& observer) { observer.recipeChanged(change); });
}

}
