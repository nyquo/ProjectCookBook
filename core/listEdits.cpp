#include "core/listEdits.hpp"

#include <algorithm>
#include <string_view>
#include <unordered_set>

namespace core {

std::vector<ListEdit> listEdits(const std::vector<std::string>& before,
                                const std::vector<std::string>& after)
{
  std::vector<ListEdit> edits;
  const std::unordered_set<std::string_view> kept(after.begin(), after.end());

  std::vector<std::string_view> rows(before.begin(), before.end());
  for (int i = static_cast<int>(rows.size()) - 1; i >= 0; --i) {
    if (!kept.contains(rows[i])) {
      edits.push_back(ListRemoved{ i });
      rows.erase(rows.begin() + i);
    }
  }

  // Rows above `i` are in place, so a row found further down moves up
  for (int i = 0; i < static_cast<int>(after.size()); ++i) {
    if (i < static_cast<int>(rows.size()) && rows[i] == after[i]) {
      continue;
    }
    const auto found = std::find(rows.begin() + i, rows.end(), after[i]);
    if (found != rows.end()) {
      const int from = static_cast<int>(found - rows.begin());
      edits.push_back(ListMoved{ from, i });
      std::rotate(rows.begin() + i, found, found + 1);
    } else {
      edits.push_back(ListInserted{ i });
      rows.insert(rows.begin() + i, after[i]);
    }
  }
  return edits;
}

}
