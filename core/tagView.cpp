#include "core/tagView.hpp"

#include <algorithm>
#include <numeric>

namespace core {

std::vector<int> tagsByName(const std::vector<Tag>& tags, const NameLess& less)
{
  std::vector<int> order(tags.size());
  std::iota(order.begin(), order.end(), 0);
  std::ranges::sort(order, [&](int a, int b) {
    const Tag& first = tags[a];
    const Tag& second = tags[b];
    if (less(first.name, second.name)) {
      return true;
    }
    if (less(second.name, first.name)) {
      return false;
    }
    return first.id < second.id;
  });
  return order;
}

}
