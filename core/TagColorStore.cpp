#include "core/TagColorStore.hpp"

#include "core/Database.hpp"

namespace core {

TagColorStore::TagColorStore(Database& db)
{
  Statement select =
    db.prepare("SELECT id, name, fill, ink, dark_fill, dark_ink, modified_at "
               "FROM tag_color WHERE deleted = 0 ORDER BY position, id");
  while (select.step()) {
    m_tagColors.push_back({ select.columnText(0),
                            select.columnText(1),
                            themedColorsColumns(select, 2),
                            fromMillis(select.columnInt64(6)) });
  }
}

}
