#include "core/recipeFields.hpp"

#include "core/SettingStore.hpp"

#include <array>
#include <string_view>
#include <utility>

namespace core {

// In enum order
static constexpr std::array<std::string_view, 6> recipeFieldKeys{
  "show_cost",   "show_times", "show_step_amounts", "show_cooking_history",
  "show_source", "show_notes"
};

bool recipeFieldShown(const SettingStore& settings, RecipeField field)
{
  return settings.flag(recipeFieldKeys[std::to_underlying(field)], true);
}

void setRecipeFieldShown(SettingStore& settings, RecipeField field, bool shown)
{
  settings.setFlag(recipeFieldKeys[std::to_underlying(field)], shown);
}

}
