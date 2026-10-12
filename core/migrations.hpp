#pragma once

namespace core {

class Database;

// Applies, in order, each embedded core/schema/NNN_name.sql newer than the
// database's PRAGMA user_version, each in its own transaction. Throws
// DatabaseError if one fails or if the database is newer than the app.
void migrate(Database& db);

// PRAGMA user_version: the number of the last migration applied.
int schemaVersion(Database& db);
int latestSchemaVersion();

}
