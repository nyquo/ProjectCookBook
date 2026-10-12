#include "core/Database.hpp"
#include "testSupport.hpp"

#include <doctest/doctest.h>
#include <sqlite3.h>

TEST_CASE("A new connection enforces foreign keys")
{
  core::Database db(":memory:");
  core::Statement select = db.prepare("PRAGMA foreign_keys");
  REQUIRE(select.step());
  CHECK(select.columnInt64(0) == 1);
}

TEST_CASE("Statements bind and read integers and UTF-8 text")
{
  core::Database db(":memory:");
  db.exec("CREATE TABLE t (i INTEGER NOT NULL, s TEXT NOT NULL) STRICT");
  db.prepare("INSERT INTO t (i, s) VALUES (?1, ?2)")
    .bind(1, std::int64_t{ 1 } << 40)
    .bind(2, "Épices & thé")
    .run();
  // An empty string must be stored as '', not NULL.
  db.prepare("INSERT INTO t (i, s) VALUES (?1, ?2)")
    .bind(1, true)
    .bind(2, std::string_view())
    .run();

  core::Statement select = db.prepare("SELECT i, s FROM t ORDER BY i");
  REQUIRE(select.step());
  CHECK(select.columnInt64(0) == 1);
  CHECK(select.columnText(1) == "");
  REQUIRE(select.step());
  CHECK(select.columnInt64(0) == std::int64_t{ 1 } << 40);
  CHECK(select.columnText(1) == "Épices & thé");
  CHECK_FALSE(select.step());
}

TEST_CASE("Failures throw DatabaseError with SQLite's code")
{
  core::Database db(":memory:");
  db.exec("CREATE TABLE t (i INTEGER NOT NULL) STRICT");

  CHECK(test::errorCode([&] { db.exec("SELEC 1"); }) == SQLITE_ERROR);
  CHECK(test::errorCode([&] { db.exec("INSERT INTO t VALUES (NULL)"); }) ==
        SQLITE_CONSTRAINT_NOTNULL);
  // SQLITE_DQS=0: double quotes name a column, they never make a string.
  CHECK(test::errorCode([&] { db.exec("SELECT \"text\""); }) == SQLITE_ERROR);
}

TEST_CASE("Opening a file in a missing directory throws")
{
  const auto path = std::filesystem::temp_directory_path() /
                    "cookbook-no-such-directory" / "data.db";
  const int code = test::errorCode([&] { core::Database db(path); });
  CHECK((code & 0xff) ==
        SQLITE_CANTOPEN); // the low byte is the primary result code
}

TEST_CASE("A transaction commits, or rolls back when destroyed without commit")
{
  core::Database db(":memory:");
  db.exec("CREATE TABLE t (i INTEGER NOT NULL) STRICT");
  {
    core::Transaction transaction(db);
    db.exec("INSERT INTO t VALUES (1)");
    transaction.commit();
  }
  {
    core::Transaction transaction(db);
    db.exec("INSERT INTO t VALUES (2)");
  }

  core::Statement select = db.prepare("SELECT group_concat(i) FROM t");
  REQUIRE(select.step());
  CHECK(select.columnText(0) == "1");
}
