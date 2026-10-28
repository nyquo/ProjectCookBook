#include "core/ShownAmount.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <span>
#include <utility>

namespace core {

// A unit on a scale, e.g. kg on the mass scale, measured in the scale's base
// unit: grams or milliliters
struct ScaleRung
{
  Unit unit;
  // Base units in one unit
  double size;
  // The smallest amount the unit shows, in base units
  double from;
};

static constexpr double gramsPerOunce = 28.35;
static constexpr double gramsPerPound = 453.6;
static constexpr double millilitersPerTeaspoon = 5;
static constexpr double millilitersPerTablespoon = 15;
static constexpr double millilitersPerCup = 236.6;
static constexpr double millilitersPerFluidOunce = 29.57;

static constexpr std::array<ScaleRung, 2> metricMass{ {
  { Unit::Grams, 1, 0 },
  { Unit::Kilograms, 1000, 1000 },
} };
static constexpr std::array<ScaleRung, 2> usMass{ {
  { Unit::Ounces, gramsPerOunce, 0 },
  { Unit::Pounds, gramsPerPound, 16 * gramsPerOunce },
} };
static constexpr std::array<ScaleRung, 2> metricVolume{ {
  { Unit::Milliliters, 1, 0 },
  { Unit::Liters, 1000, 1000 },
} };
// Centiliters stay centiliters up to the liter
static constexpr std::array<ScaleRung, 2> centiliterVolume{ {
  { Unit::Centiliters, 10, 0 },
  { Unit::Liters, 1000, 1000 },
} };
static constexpr std::array<ScaleRung, 3> usVolume{ {
  { Unit::Teaspoons, millilitersPerTeaspoon, 0 },
  { Unit::Tablespoons, millilitersPerTablespoon, millilitersPerTablespoon },
  { Unit::Cups, millilitersPerCup, millilitersPerCup / 4 },
} };
// US units of the US system keep their unit
static constexpr std::array<ScaleRung, 1> cupVolume{ {
  { Unit::Cups, millilitersPerCup, 0 },
} };
static constexpr std::array<ScaleRung, 1> fluidOunceVolume{ {
  { Unit::FluidOunces, millilitersPerFluidOunce, 0 },
} };

// Half away from zero. A relative nudge keeps a half that floating point
// left just under .5 (2.4999999999999996) a half.
static double roundTo(double value, int decimals)
{
  constexpr double nudge = 1 + 1e-9;
  if (decimals < 0) {
    const double step = std::pow(10.0, -decimals);
    return std::round(value / step * nudge) * step;
  }
  const double scale = std::pow(10.0, decimals);
  return std::round(value * scale * nudge) / scale;
}

// 3 significant digits and 2 decimals at most, never down to 0
static double roundSignificant(double value)
{
  if (!(value > 0)) {
    return value;
  }
  const int integerDigits = static_cast<int>(std::floor(std::log10(value))) + 1;
  const double rounded = roundTo(value, std::min(3 - integerDigits, 2));
  return rounded > 0 ? rounded : 0.01;
}

// With a tolerance for floating point: 16 oz reaches the pound
static bool reaches(double amount, double threshold)
{
  return amount >= threshold * (1 - 1e-9);
}

static ShownAmount withQuantity(double quantity, std::optional<RecipeUnit> unit)
{
  return { quantity, std::move(unit), takesPlural(quantity) };
}

// `base`: the amount in the scale's base unit
static ShownAmount onScale(double base, std::span<const ScaleRung> scale)
{
  std::size_t rung = 0;
  while (rung + 1 < scale.size() && reaches(base, scale[rung + 1].from)) {
    ++rung;
  }
  double shown = roundSignificant(base / scale[rung].size);
  // Rounding up can reach the next unit: 999.6 g rounds to 1000 g, 1 kg
  while (rung + 1 < scale.size() &&
         reaches(shown * scale[rung].size, scale[rung + 1].from)) {
    ++rung;
    shown = roundSignificant(base / scale[rung].size);
  }
  return withQuantity(shown, scale[rung].unit);
}

ShownAmount shownAmount(std::optional<double> quantity,
                        const std::optional<RecipeUnit>& unit,
                        Servings servings,
                        UnitSystem system)
{
  if (!quantity) {
    // Only a free-text unit goes without a quantity
    if (unit && std::holds_alternative<std::string>(*unit)) {
      return { std::nullopt, unit, false };
    }
    return {};
  }

  // Multiplying first loses less precision than a ratio would
  const double scaled = *quantity * servings.shown / servings.base;
  if (!unit || !std::holds_alternative<Unit>(*unit)) {
    return withQuantity(roundSignificant(scaled), unit);
  }

  const bool metric = system == UnitSystem::Metric;
  const std::span<const ScaleRung> mass =
    metric ? std::span<const ScaleRung>(metricMass) : usMass;
  const std::span<const ScaleRung> volume =
    metric ? std::span<const ScaleRung>(metricVolume) : usVolume;
  const Unit code = std::get<Unit>(*unit);
  switch (code) {
    case Unit::Pieces:
      return withQuantity(std::max(0.5, roundTo(scaled * 2, 0) / 2), code);
    case Unit::Cloves:
    case Unit::Pinches:
    case Unit::Packs:
    case Unit::Bunches:
    case Unit::Cans:
      return withQuantity(std::max(1.0, roundTo(scaled, 0)), code);
    case Unit::Teaspoons:
    case Unit::Tablespoons:
      return withQuantity(roundSignificant(scaled), code);
    case Unit::Grams:
      return onScale(scaled, mass);
    case Unit::Kilograms:
      return onScale(scaled * 1000, mass);
    case Unit::Ounces:
      return onScale(scaled * gramsPerOunce, mass);
    case Unit::Pounds:
      return onScale(scaled * gramsPerPound, mass);
    case Unit::Milliliters:
      return onScale(scaled, volume);
    case Unit::Centiliters:
      return onScale(scaled * 10,
                     metric ? std::span<const ScaleRung>(centiliterVolume)
                            : usVolume);
    case Unit::Liters:
      return onScale(scaled * 1000, volume);
    case Unit::Cups:
      return onScale(scaled * millilitersPerCup,
                     metric ? std::span<const ScaleRung>(metricVolume)
                            : cupVolume);
    case Unit::FluidOunces:
      return onScale(scaled * millilitersPerFluidOunce,
                     metric ? std::span<const ScaleRung>(metricVolume)
                            : fluidOunceVolume);
  }
  std::unreachable();
}

bool takesPlural(double quantity)
{
  return quantity != 1;
}

}
