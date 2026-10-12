#include "core/migrations.hpp"

#include "core/Database.hpp"
#include "migrationsSql.hpp"

#include <sqlite3.h>

#include <format>

namespace core {

void migrate(Database& db)
{
  const int current = schemaVersion(db);
  if (current > latestSchemaVersion()) {
    throw DatabaseError(
      SQLITE_ERROR,
      std::format("database schema version {} is newer than this app's ({})",
                  current,
                  latestSchemaVersion()));
  }

  for (const schema::Migration& migration : schema::migrations) {
    if (migration.version <= current) {
      continue;
    }
    try {
      Transaction transaction(db);
      db.exec(migration.sql);
      // PRAGMA takes no bound parameters, so this is the one SQL string built
      // at runtime. The value is a compiled-in integer, never user input.
      db.exec(std::format("PRAGMA user_version = {}", migration.version));
      transaction.commit();
    } catch (const DatabaseError& error) {
      throw DatabaseError(
        error.code(),
        std::format("migration {} failed: {}", migration.name, error.what()));
    }
  }
}

int schemaVersion(Database& db)
{
  Statement statement = db.prepare("PRAGMA user_version");
  statement.step();
  return static_cast<int>(statement.columnInt64(0));
}

int latestSchemaVersion()
{
  return schema::migrations.back().version;
}

}
