#pragma once

#include "core/Amount.hpp"
#include "core/clock.hpp"

#include <chrono>
#include <cstdint>
#include <optional>
#include <string>
#include <variant>
#include <vector>

namespace core {

// A recipe ingredient's unit: one of the units, or free text as the user
// typed it ("handfuls")
using RecipeUnit = std::variant<Unit, std::string>;

// A line of a recipe's ingredients: a main ingredient, or a substitute for one
struct RecipeIngredient
{
  std::string id;
  // On a substitute: the main ingredient it can replace. One level only: a
  // substitute has none of its own.
  std::optional<std::string> parentId;
  // Trimmed, as the user typed it
  std::string name;
  // The dictionary ingredient with the same canonical name
  std::string ingredientId;
  // Above 0; none: to taste
  std::optional<double> quantity;
  // Set whenever there's a quantity. Without one, only free text ("a
  // handful").
  std::optional<RecipeUnit> unit;
  std::optional<std::string> note;
  bool optional = false;

  bool operator==(const RecipeIngredient&) const = default;
};

// Words of a step's text that name one of the recipe's main ingredients. The
// text always holds every word: a mention only marks some of them.
struct StepMention
{
  std::string id;
  // A main ingredient's id, never a substitute's
  std::string recipeIngredientId;
  // The words, in Unicode code points from the start of the text
  int start = 0;
  int length = 0;
  // What the step uses, in the ingredient's unit; none: all of it
  std::optional<double> quantity;

  bool operator==(const StepMention&) const = default;
};

struct Step
{
  std::string id;
  std::string text;
  // In text order, without overlaps
  std::vector<StepMention> mentions;

  bool operator==(const Step&) const = default;
};

// What describes a recipe, beside its ingredients, steps and tags
struct RecipeFields
{
  // Trimmed
  std::string title;
  std::optional<std::string> description;
  // The photo's id: the SHA-256 of its file, 64 lowercase hex digits
  std::optional<std::string> photoId;
  // 1 or more: the servings the quantities are written for
  int baseServings = 4;
  std::optional<int> prepMinutes;
  std::optional<int> cookMinutes;
  // In euro cents, for the whole recipe
  std::optional<std::int64_t> costCents;
  // A link, a book, a person
  std::optional<std::string> source;
  std::optional<std::string> notes;
  bool favorite = false;
  int cookCount = 0;
  // A local date
  std::optional<std::chrono::year_month_day> lastCooked;
  // Unused for now
  std::optional<int> lastPlannedServings;

  bool operator==(const RecipeFields&) const = default;
};

// A live recipe
struct Recipe : RecipeFields
{
  std::string id;
  Timestamp createdAt;
  Timestamp modifiedAt;
  // The main ingredients in order, each followed by its substitutes
  std::vector<RecipeIngredient> ingredients;
  std::vector<Step> steps;
  // In id order. Deleted tags' too: the links stay, so restoring a tag
  // brings it back.
  std::vector<std::string> tagIds;

  bool operator==(const Recipe&) const = default;
};

// A new recipe's ingredient. The store links it to the dictionary. The
// drafts' members have defaults, so a draft names only the fields it sets.
struct IngredientDraft
{
  std::string name;
  std::optional<double> quantity = std::nullopt;
  std::optional<RecipeUnit> unit = std::nullopt;
  std::optional<std::string> note = std::nullopt;
  bool optional = false;
  // On a substitute: the index of the main ingredient it can replace
  std::optional<int> substituteFor = std::nullopt;
};

struct MentionDraft
{
  // The index of a main ingredient in RecipeDraft::ingredients
  int ingredient = 0;
  // In Unicode code points
  int start = 0;
  int length = 0;
  std::optional<double> quantity = std::nullopt;
};

struct StepDraft
{
  std::string text;
  std::vector<MentionDraft> mentions = {};
};

// What RecipeStore::create() makes a recipe of: rows get their ids and
// positions there
struct RecipeDraft : RecipeFields
{
  // In order; a substitute goes after its main ingredient's other substitutes
  std::vector<IngredientDraft> ingredients;
  std::vector<StepDraft> steps;
  // Live tags
  std::vector<std::string> tagIds;
};

}
