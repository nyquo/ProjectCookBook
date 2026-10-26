#pragma once

#include "core/text.hpp"

#include <QCollator>

namespace app {

// Orders display names in the user's locale, ignoring case, numbers by value
QCollator nameCollator();
// The collator's order, for core functions that sort names. The collator must
// outlive the result.
core::NameLess nameLess(const QCollator& collator);

}
