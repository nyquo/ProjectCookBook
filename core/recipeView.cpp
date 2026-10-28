#include "core/recipeView.hpp"

#include "core/tagView.hpp"

#include <algorithm>
#include <numeric>

namespace core {

std::vector<int> recipesByTitle(const std::vector<Recipe>& recipes,
                                const NameLess& less)
{
  std::vector<int> order(recipes.size());
  std::iota(order.begin(), order.end(), 0);
  std::ranges::sort(order, [&](int a, int b) {
    const Recipe& first = recipes[a];
    const Recipe& second = recipes[b];
    if (less(first.title, second.title)) {
      return true;
    }
    if (less(second.title, first.title)) {
      return false;
    }
    return first.id < second.id;
  });
  return order;
}

std::vector<int> recipeTags(const Recipe& recipe,
                            const std::vector<Tag>& tags,
                            const NameLess& less)
{
  std::vector<int> result;
  for (const int index : tagsByName(tags, less)) {
    if (std::ranges::find(recipe.tagIds, tags[index].id) !=
        recipe.tagIds.end()) {
      result.push_back(index);
    }
  }
  return result;
}

int mainIngredientIndex(const Recipe& recipe, std::string_view id)
{
  const auto& ingredients = recipe.ingredients;
  const auto it = std::ranges::find_if(ingredients, [&](const auto& line) {
    return line.id == id && !line.parentId;
  });
  return it != ingredients.end() ? static_cast<int>(it - ingredients.begin())
                                 : -1;
}

std::vector<StepSegment> stepSegments(const Recipe& recipe, const Step& step)
{
  const std::string_view text = step.text;
  std::vector<StepSegment> segments;
  // Bytes already in a segment
  std::size_t done = 0;
  for (const StepMention& mention : step.mentions) {
    if (mainIngredientIndex(recipe, mention.recipeIngredientId) < 0) {
      continue;
    }
    const std::size_t begin = byteOffset(text, mention.start);
    const std::size_t end = byteOffset(text, mention.start + mention.length);
    if (begin < done || end <= begin) {
      continue;
    }
    if (begin > done) {
      segments.push_back({ std::string(text.substr(done, begin - done)) });
    }
    segments.push_back({ std::string(text.substr(begin, end - begin)), true });
    done = end;
  }
  if (done < text.size()) {
    segments.push_back({ std::string(text.substr(done)) });
  }
  return segments;
}

std::vector<StepAmount> stepAmounts(const Recipe& recipe, const Step& step)
{
  std::vector<StepAmount> amounts;
  for (const StepMention& mention : step.mentions) {
    const int index = mainIngredientIndex(recipe, mention.recipeIngredientId);
    if (index < 0) {
      continue;
    }
    const std::optional<double>& whole = recipe.ingredients[index].quantity;
    const auto it = std::ranges::find(amounts, index, &StepAmount::ingredient);
    if (it == amounts.end()) {
      amounts.push_back({ index,
                          whole ? mention.quantity.value_or(*whole)
                                : std::optional<double>() });
    } else if (whole) {
      *it->quantity += mention.quantity.value_or(*whole);
    }
  }
  return amounts;
}

CookedAge cookedAge(std::chrono::year_month_day lastCooked,
                    std::chrono::year_month_day today)
{
  using Period = CookedAge::Period;
  const int days = static_cast<int>(
    (std::chrono::sys_days(today) - std::chrono::sys_days(lastCooked)).count());
  if (days <= 0) {
    return { Period::Today };
  }
  if (days == 1) {
    return { Period::Yesterday };
  }
  if (days < 7) {
    return { Period::Days, days };
  }
  if (days < 30) {
    return { Period::Weeks, days / 7 };
  }
  if (days < 365) {
    return { Period::Months, days / 30 };
  }
  return { Period::Years, days / 365 };
}

}
