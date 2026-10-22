#include "core/Backend.hpp"

#include "core/migrations.hpp"

namespace core {

static Database& migrated(Database& db)
{
  migrate(db);
  return db;
}

Backend::Backend(const std::filesystem::path& databasePath, Clock clock)
  : m_db(databasePath)
  , m_tagColors(migrated(m_db))
  , m_aisles(m_db, std::move(clock))
{
}

}
