#pragma once

#include "core/Amount.hpp"

#include <span>

namespace core {

class SettingStore;

// How amounts are shown. What the user typed is kept as is: switching never
// rewrites stored amounts.
enum class UnitSystem
{
  Metric,
  Us
};

// Stored under "unit_system" as "metric" or "us". Metric when unset or
// unknown.
UnitSystem unitSystem(const SettingStore& settings);
void setUnitSystem(SettingStore& settings, UnitSystem system);

// The units offered where the user picks one, in the order shown. Metric: pcs,
// g, kg, ml, cl, l, pack, bunch. US: pcs, oz, lb, fl oz, pack, bunch.
std::span<const Unit> unitChoices(UnitSystem system);

}
