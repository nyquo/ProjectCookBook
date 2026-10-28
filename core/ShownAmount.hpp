#pragma once

#include "core/Recipe.hpp"
#include "core/unitSystem.hpp"

#include <optional>

namespace core {

// The servings a recipe is shown for, and those its quantities are written
// for; both 1 or more
struct Servings
{
  int shown;
  int base;
};

// A recipe amount as the recipe screen shows it. The app formats the number
// in the user's locale and the unit's label.
struct ShownAmount
{
  // None: "To taste", or the free-text unit alone when there's one
  std::optional<double> quantity;
  std::optional<RecipeUnit> unit;
  // The unit's label takes its plural form: "2 cloves", "1,5 cups"
  bool plural = false;

  bool operator==(const ShownAmount&) const = default;
};

// Every amount on the recipe screen goes through here:
// 1. scaled by servings.shown / servings.base;
// 2. converted for `system`. Units of the other system convert: in metric,
//    mass shows in g or kg, cups and fl oz in ml or l; in US, mass shows in
//    oz or lb, and ml, cl, l in tsp below 1 tbsp, tbsp below 1/4 cup, cups
//    from there. Units of `system` stay, but follow the amount: g and kg
//    switch at 1000 g, ml and cl become l from 1000 ml (l becomes ml below),
//    oz and lb switch at 16 oz. tsp and tbsp belong to both systems and
//    stay; so do pieces, the other counted units and free-text units;
// 3. rounded to 3 significant digits and 2 decimals at most, but pieces to
//    the nearest 1/2 (at least 1/2), cloves, pinches, packs, bunches and cans
//    to the nearest whole (at least 1). A quantity never rounds to 0. If
//    rounding reaches the next unit's threshold, the next unit shows it:
//    999.6 g shows as 1 kg.
ShownAmount shownAmount(std::optional<double> quantity,
                        const std::optional<RecipeUnit>& unit,
                        Servings servings,
                        UnitSystem system);

// Whether a unit's label after this number takes its plural form: for every
// number but 1, as in English, the language of the app's texts
bool takesPlural(double quantity);

}
