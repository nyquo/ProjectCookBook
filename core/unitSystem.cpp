#include "core/unitSystem.hpp"

#include "core/SettingStore.hpp"

#include <array>
#include <string_view>
#include <utility>

namespace core {

static constexpr std::string_view unitSystemKey = "unit_system";

// In enum order
static constexpr std::array<std::string_view, 2> unitSystemCodes{ "metric",
                                                                  "us" };

static constexpr std::array metricUnits{ Unit::Pieces,      Unit::Grams,
                                         Unit::Kilograms,   Unit::Milliliters,
                                         Unit::Centiliters, Unit::Liters,
                                         Unit::Packs,       Unit::Bunches };
static constexpr std::array usUnits{ Unit::Pieces, Unit::Ounces,
                                     Unit::Pounds, Unit::FluidOunces,
                                     Unit::Packs,  Unit::Bunches };

UnitSystem unitSystem(const SettingStore& settings)
{
  return static_cast<UnitSystem>(
    settings.codeIndex(unitSystemKey, unitSystemCodes));
}

void setUnitSystem(SettingStore& settings, UnitSystem system)
{
  settings.setValue(unitSystemKey, unitSystemCodes[std::to_underlying(system)]);
}

std::span<const Unit> unitChoices(UnitSystem system)
{
  switch (system) {
    case UnitSystem::Metric:
      return metricUnits;
    case UnitSystem::Us:
      return usUnits;
  }
  std::unreachable();
}

}
