#include "core/ShownAmount.hpp"

#include <doctest/doctest.h>

#include <string>
#include <utility>

namespace {

using core::RecipeUnit;
using core::ShownAmount;
using core::Unit;

constexpr auto metric = core::UnitSystem::Metric;
constexpr auto us = core::UnitSystem::Us;

// `quantity` of `unit`, written for 4 servings unless said otherwise
ShownAmount shown(double quantity,
                  RecipeUnit unit,
                  core::UnitSystem system = metric,
                  core::Servings servings = { 4, 4 })
{
  return core::shownAmount(quantity, std::move(unit), servings, system);
}

ShownAmount amount(double quantity, RecipeUnit unit)
{
  return { quantity, std::move(unit), quantity != 1 };
}

}

TEST_CASE("Amounts scale by shown servings over base servings")
{
  CHECK(shown(200, Unit::Grams, metric, { 6, 4 }) == amount(300, Unit::Grams));
  CHECK(shown(200, Unit::Grams, metric, { 2, 4 }) == amount(100, Unit::Grams));
  CHECK(shown(100, Unit::Grams, metric, { 1, 3 }) == amount(33.3, Unit::Grams));
  CHECK(shown(1, Unit::Tablespoons, metric, { 6, 4 }) ==
        amount(1.5, Unit::Tablespoons));
  CHECK(shown(2, Unit::Cups, us, { 1, 2 }) == amount(1, Unit::Cups));
}

TEST_CASE("Metric shows US mass in g or kg")
{
  CHECK(shown(8, Unit::Ounces) == amount(227, Unit::Grams));
  CHECK(shown(1, Unit::Pounds) == amount(454, Unit::Grams));
  CHECK(shown(3, Unit::Pounds) == amount(1.36, Unit::Kilograms));
}

TEST_CASE("Metric shows cups and fl oz in ml or l")
{
  CHECK(shown(1, Unit::Cups) == amount(237, Unit::Milliliters));
  CHECK(shown(5, Unit::Cups) == amount(1.18, Unit::Liters));
  CHECK(shown(16, Unit::FluidOunces) == amount(473, Unit::Milliliters));
  CHECK(shown(40, Unit::FluidOunces) == amount(1.18, Unit::Liters));
}

TEST_CASE("US shows metric mass in oz or lb, from 16 oz")
{
  CHECK(shown(250, Unit::Grams, us) == amount(8.82, Unit::Ounces));
  CHECK(shown(500, Unit::Grams, us) == amount(1.1, Unit::Pounds));
  CHECK(shown(1, Unit::Kilograms, us) == amount(2.2, Unit::Pounds));
  CHECK(shown(1.5, Unit::Kilograms, us) == amount(3.31, Unit::Pounds));
}

TEST_CASE("US shows ml, cl and l in tsp below 1 tbsp, tbsp below 1/4 cup, "
          "then cups")
{
  CHECK(shown(2.5, Unit::Milliliters, us) == amount(0.5, Unit::Teaspoons));
  CHECK(shown(10, Unit::Milliliters, us) == amount(2, Unit::Teaspoons));
  CHECK(shown(15, Unit::Milliliters, us) == amount(1, Unit::Tablespoons));
  CHECK(shown(45, Unit::Milliliters, us) == amount(3, Unit::Tablespoons));
  CHECK(shown(59, Unit::Milliliters, us) == amount(3.93, Unit::Tablespoons));
  CHECK(shown(60, Unit::Milliliters, us) == amount(0.25, Unit::Cups));
  CHECK(shown(250, Unit::Milliliters, us) == amount(1.06, Unit::Cups));
  CHECK(shown(20, Unit::Centiliters, us) == amount(0.85, Unit::Cups));
  CHECK(shown(1, Unit::Liters, us) == amount(4.23, Unit::Cups));
}

TEST_CASE("Metric units follow the amount: g and kg, ml, cl and l")
{
  CHECK(shown(1500, Unit::Grams) == amount(1.5, Unit::Kilograms));
  CHECK(shown(999, Unit::Grams) == amount(999, Unit::Grams));
  CHECK(shown(1, Unit::Kilograms) == amount(1, Unit::Kilograms));
  CHECK(shown(0.75, Unit::Kilograms) == amount(750, Unit::Grams));
  CHECK(shown(1500, Unit::Milliliters) == amount(1.5, Unit::Liters));
  CHECK(shown(0.5, Unit::Liters) == amount(500, Unit::Milliliters));
  // Centiliters stay below 100 cl, but liters never become centiliters
  CHECK(shown(50, Unit::Centiliters) == amount(50, Unit::Centiliters));
  CHECK(shown(50, Unit::Centiliters, metric, { 6, 4 }) ==
        amount(75, Unit::Centiliters));
  CHECK(shown(150, Unit::Centiliters) == amount(1.5, Unit::Liters));
  CHECK(shown(0.25, Unit::Liters) == amount(250, Unit::Milliliters));
}

TEST_CASE("US units follow the amount: oz and lb; cups and fl oz stay")
{
  CHECK(shown(20, Unit::Ounces, us) == amount(1.25, Unit::Pounds));
  CHECK(shown(16, Unit::Ounces, us) == amount(1, Unit::Pounds));
  CHECK(shown(0.5, Unit::Pounds, us) == amount(8, Unit::Ounces));
  CHECK(shown(2, Unit::Cups, us) == amount(2, Unit::Cups));
  CHECK(shown(0.2, Unit::Cups, us) == amount(0.2, Unit::Cups));
  CHECK(shown(40, Unit::FluidOunces, us) == amount(40, Unit::FluidOunces));
}

TEST_CASE("tsp and tbsp belong to both systems and never convert")
{
  for (const core::UnitSystem system : { metric, us }) {
    CHECK(shown(2, Unit::Teaspoons, system) == amount(2, Unit::Teaspoons));
    CHECK(shown(12, Unit::Teaspoons, system) == amount(12, Unit::Teaspoons));
    CHECK(shown(6, Unit::Tablespoons, system) == amount(6, Unit::Tablespoons));
  }
}

TEST_CASE("Pieces, counted units and free-text units never convert")
{
  for (const core::UnitSystem system : { metric, us }) {
    CHECK(shown(3, Unit::Pieces, system) == amount(3, Unit::Pieces));
    for (const Unit unit :
         { Unit::Cloves, Unit::Pinches, Unit::Packs, Unit::Bunches }) {
      CHECK(shown(2, unit, system) == amount(2, unit));
    }
    CHECK(shown(2, Unit::Cans, system) == amount(2, Unit::Cans));
    CHECK(shown(2, std::string("handfuls"), system) ==
          amount(2, std::string("handfuls")));
  }
}

TEST_CASE("Rounding keeps 3 significant digits and 2 decimals at most")
{
  CHECK(shown(1234, Unit::Grams) == amount(1.23, Unit::Kilograms));
  CHECK(shown(12345, Unit::Grams) == amount(12.3, Unit::Kilograms));
  CHECK(shown(123456, Unit::Grams) == amount(123, Unit::Kilograms));
  CHECK(shown(1234567, Unit::Grams) == amount(1230, Unit::Kilograms));
  CHECK(shown(1, Unit::Teaspoons, metric, { 1, 30 }) ==
        amount(0.03, Unit::Teaspoons));
  CHECK(shown(2.25, Unit::Tablespoons) == amount(2.25, Unit::Tablespoons));
  // Free-text units round the same way
  CHECK(shown(2, std::string("handfuls"), metric, { 1, 3 }) ==
        amount(0.67, std::string("handfuls")));
}

TEST_CASE("A quantity never rounds down to 0")
{
  CHECK(shown(0.004, Unit::Teaspoons) == amount(0.01, Unit::Teaspoons));
  CHECK(shown(0.001, Unit::Grams) == amount(0.01, Unit::Grams));
}

TEST_CASE("Pieces round to the nearest half, at least a half")
{
  CHECK(shown(1, Unit::Pieces, metric, { 6, 4 }) == amount(1.5, Unit::Pieces));
  // Halves away from zero: 1.25 is between 1 and 1.5
  CHECK(shown(1, Unit::Pieces, metric, { 5, 4 }) == amount(1.5, Unit::Pieces));
  CHECK(shown(2, Unit::Pieces, metric, { 5, 6 }) == amount(1.5, Unit::Pieces));
  CHECK(shown(3, Unit::Pieces, metric, { 7, 4 }) == amount(5.5, Unit::Pieces));
  CHECK(shown(1, Unit::Pieces, metric, { 1, 4 }) == amount(0.5, Unit::Pieces));
  CHECK(shown(1, Unit::Pieces, metric, { 1, 8 }) == amount(0.5, Unit::Pieces));
}

TEST_CASE("Cloves, pinches, packs, bunches and cans round to the nearest "
          "whole, at least 1")
{
  CHECK(shown(2, Unit::Cloves, metric, { 5, 4 }) == amount(3, Unit::Cloves));
  CHECK(shown(2, Unit::Cloves, metric, { 3, 4 }) == amount(2, Unit::Cloves));
  CHECK(shown(1, Unit::Cloves, metric, { 1, 4 }) == amount(1, Unit::Cloves));
  CHECK(shown(1, Unit::Pinches, metric, { 6, 4 }) == amount(2, Unit::Pinches));
  CHECK(shown(1, Unit::Packs, metric, { 9, 4 }) == amount(2, Unit::Packs));
  CHECK(shown(2, Unit::Bunches, metric, { 7, 4 }) == amount(4, Unit::Bunches));
  CHECK(shown(3, Unit::Cans, metric, { 1, 4 }) == amount(1, Unit::Cans));
}

TEST_CASE("Rounding up to a unit's threshold shows the next unit")
{
  CHECK(shown(999.6, Unit::Grams) == amount(1, Unit::Kilograms));
  CHECK(shown(999.7, Unit::Milliliters) == amount(1, Unit::Liters));
  CHECK(shown(99.96, Unit::Centiliters) == amount(1, Unit::Liters));
  CHECK(shown(453.4, Unit::Grams, us) == amount(1, Unit::Pounds));
  CHECK(shown(14.99, Unit::Milliliters, us) == amount(1, Unit::Tablespoons));
}

TEST_CASE("Labels are singular for exactly 1, plural otherwise")
{
  CHECK_FALSE(core::takesPlural(1));
  CHECK(core::takesPlural(0.5));
  CHECK(core::takesPlural(1.5));
  CHECK(core::takesPlural(2));

  CHECK_FALSE(shown(1, Unit::Cloves).plural);
  CHECK(shown(2, Unit::Cloves).plural);
  CHECK_FALSE(shown(1, Unit::Pinches).plural);
  CHECK(shown(2, Unit::Pinches).plural);
  CHECK_FALSE(shown(1, Unit::Cups, us).plural);
  CHECK(shown(1.5, Unit::Cups, us).plural);
  CHECK(shown(0.5, Unit::Cups, us).plural);
  // After scaling: 4 cloves for 1 serving of 4
  CHECK_FALSE(shown(4, Unit::Cloves, metric, { 1, 4 }).plural);
  // After converting: 236.6 ml is 1 cup
  CHECK_FALSE(shown(236.6, Unit::Milliliters, us).plural);
}

TEST_CASE("Without a quantity: to taste, or the free-text unit alone")
{
  const core::Servings servings{ 6, 4 };
  CHECK(core::shownAmount(std::nullopt, std::nullopt, servings, metric) ==
        ShownAmount{});
  CHECK(core::shownAmount(
          std::nullopt, RecipeUnit("a handful"), servings, metric) ==
        ShownAmount{ std::nullopt, RecipeUnit("a handful"), false });
  // A unit means nothing without a quantity
  CHECK(core::shownAmount(std::nullopt, Unit::Grams, servings, metric) ==
        ShownAmount{});
}
