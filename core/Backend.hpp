#pragma once

#include "core/AisleStore.hpp"
#include "core/Database.hpp"
#include "core/TagColorStore.hpp"
#include "core/clock.hpp"

#include <filesystem>

namespace core {

// Owns the database and every store. Construction opens the file, migrates it
// and loads the data; throws DatabaseError if the database is broken.
//
// All database work runs synchronously on the main thread: writes are tiny. If
// slow work ever appears (a large import, a sync), it moves to a worker thread
// with its own Database connection, and store changes are posted back to the
// main thread, where store observers are notified.
class Backend
{
public:
  explicit Backend(const std::filesystem::path& databasePath,
                   Clock clock = systemNow);

  TagColorStore& tagColors() { return m_tagColors; }
  AisleStore& aisles() { return m_aisles; }

private:
  Database m_db;
  // The first store migrates the database
  TagColorStore m_tagColors;
  AisleStore m_aisles;
};

}
