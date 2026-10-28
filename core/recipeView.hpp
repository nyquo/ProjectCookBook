#pragma once

#include "core/Recipe.hpp"
#include "core/Tag.hpp"
#include "core/text.hpp"

#include <chrono>
#include <optional>
#include <string>
#include <vector>

namespace core {

// The indices of `recipes`, in the order the list shows them: by title (ties
// by id)
std::vector<int> recipesByTitle(const std::vector<Recipe>& recipes,
                                const NameLess& less);

// The indices in `tags`, the live tags, of those the recipe carries, by name
// (ties by id). Deleted tags don't show.
std::vector<int> recipeTags(const Recipe& recipe,
                            const std::vector<Tag>& tags,
                            const NameLess& less);

// The index in recipe.ingredients of the main ingredient with this id, or -1
// for a substitute's or an unknown id
int mainIngredientIndex(const Recipe& recipe, std::string_view id);

// A piece of a step's text: a mention's words, or the text around them
struct StepSegment
{
  std::string text;
  bool mention = false;

  bool operator==(const StepSegment&) const = default;
};

// The step's text cut at its mentions: joined, the segments give the whole
// text back. A mention of an ingredient the recipe doesn't have as a main
// ingredient (deleted) counts as plain text.
std::vector<StepSegment> stepSegments(const Recipe& recipe, const Step& step);

// What a step uses of an ingredient
struct StepAmount
{
  // In recipe.ingredients, a main ingredient
  int ingredient = 0;
  // In the ingredient's unit; none for an ingredient without a quantity (to
  // taste)
  std::optional<double> quantity;

  bool operator==(const StepAmount&) const = default;
};

// One amount per ingredient the step mentions, in order of first mention. An
// ingredient's mentions add up; one without a quantity counts as the
// ingredient's whole quantity. Mentions of an ingredient the recipe doesn't
// have as a main ingredient (deleted) are dropped.
std::vector<StepAmount> stepAmounts(const Recipe& recipe, const Step& step);

// How long ago a recipe was last cooked
struct CookedAge
{
  enum class Period
  {
    Today,
    Yesterday,
    Days,
    Weeks,
    Months,
    Years
  };

  Period period;
  // Of days, weeks, months or years; 0 for Today and Yesterday
  int count = 0;

  bool operator==(const CookedAge&) const = default;
};

// Days under a week, weeks under 30 days, 30-day months under a year (365
// days), then years, rounded down. A date after `today` counts as today.
CookedAge cookedAge(std::chrono::year_month_day lastCooked,
                    std::chrono::year_month_day today);

}
