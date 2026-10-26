#pragma once

#include "core/Tag.hpp"
#include "core/text.hpp"

#include <vector>

namespace core {

// The indices of `tags`, in the order they're shown: by name (ties by id)
std::vector<int> tagsByName(const std::vector<Tag>& tags, const NameLess& less);

}
