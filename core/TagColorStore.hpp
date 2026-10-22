#pragma once

#include "core/TagColor.hpp"

#include <vector>

namespace core {

class Database;

// Live tag colors in position order: the colors offered for tags and aisles.
// Read-only for now: the rows come from the schema's seed. Changes, when they
// come, follow AisleStore: validated, committed, then applied and notified.
class TagColorStore
{
public:
  // The database must be migrated
  explicit TagColorStore(Database& db);
  TagColorStore(const TagColorStore&) = delete;
  TagColorStore& operator=(const TagColorStore&) = delete;

  const std::vector<TagColor>& tagColors() const { return m_tagColors; }

private:
  std::vector<TagColor> m_tagColors;
};

}
