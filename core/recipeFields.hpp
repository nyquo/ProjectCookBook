#pragma once

namespace core {

class SettingStore;

// The recipe fields the user can hide. A hidden field disappears from the
// recipes list, the recipe and the editor; what was entered in it stays.
enum class RecipeField
{
  // Price of the recipe and per serving
  Cost,
  // Prep and cook times
  Times,
  // The amounts listed at the bottom of each step
  StepAmounts,
  // Times cooked and last cooked date
  CookingHistory,
  // Link, book or person
  Source,
  Notes
};

// Stored under "show_cost", "show_times", "show_step_amounts",
// "show_cooking_history", "show_source" and "show_notes" as "true" or
// "false". Shown when unset or unknown.
bool recipeFieldShown(const SettingStore& settings, RecipeField field);
void setRecipeFieldShown(SettingStore& settings, RecipeField field, bool shown);

}
