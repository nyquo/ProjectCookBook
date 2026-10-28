#pragma once

#include <string>
#include <variant>
#include <vector>

namespace core {

struct ListRemoved
{
  int index;
  bool operator==(const ListRemoved&) const = default;
};

// The row inserted at `index` is after[index]
struct ListInserted
{
  int index;
  bool operator==(const ListInserted&) const = default;
};

// The row at `from` is now at `to`; those in between shifted by one
struct ListMoved
{
  int from;
  int to;
  bool operator==(const ListMoved&) const = default;
};

using ListEdit = std::variant<ListRemoved, ListInserted, ListMoved>;

// Single-row edits that turn `before` into `after`, two lists of distinct keys,
// so a list model can follow a recomputed list without a reset. Each edit's
// indices count the rows as the previous edits left them. Removals come first,
// from the end; then rows are moved or inserted into place from the top.
std::vector<ListEdit> listEdits(const std::vector<std::string>& before,
                                const std::vector<std::string>& after);

}
