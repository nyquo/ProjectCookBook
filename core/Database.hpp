#pragma once

#include <concepts>
#include <cstdint>
#include <filesystem>
#include <memory>
#include <stdexcept>
#include <string>
#include <string_view>

struct sqlite3;
struct sqlite3_stmt;

namespace core {

// The database itself failed: can't open, I/O error, failed migration, or a
// constraint the core should have prevented. Never used for invalid user input.
class DatabaseError : public std::runtime_error
{
public:
  DatabaseError(int code, const std::string& message);

  // SQLite extended result code, e.g. SQLITE_CONSTRAINT_UNIQUE.
  int code() const noexcept { return m_code; }

private:
  int m_code;
};

class Statement;

// Not movable: stores keep a reference to it.
class Database
{
public:
  // ":memory:" opens a private in-memory database.
  explicit Database(const std::filesystem::path& path);
  Database(const Database&) = delete;
  Database& operator=(const Database&) = delete;

  // For constant SQL without parameters; may hold several statements.
  void exec(std::string_view sql);

  Statement prepare(std::string_view sql);

private:
  struct Closer
  {
    void operator()(sqlite3* db) const noexcept;
  };
  std::unique_ptr<sqlite3, Closer> m_db;
};

// Parameters are numbered from 1, as in "?1".
class Statement
{
public:
  Statement(const Statement&) = delete;
  Statement& operator=(const Statement&) = delete;

  Statement& bind(int index, std::integral auto value)
  {
    return bindInt64(index, static_cast<std::int64_t>(value));
  }
  Statement& bind(int index, std::string_view value);

  // True while there is a row to read.
  bool step();
  // For statements that return no rows.
  void run();

  std::int64_t columnInt64(int index) const;
  std::string columnText(int index) const;

private:
  friend class Database;
  Statement(sqlite3* db, sqlite3_stmt* statement);
  Statement& bindInt64(int index, std::int64_t value);
  void check(int result) const;

  struct Finalizer
  {
    void operator()(sqlite3_stmt* statement) const noexcept;
  };
  sqlite3* m_db;
  std::unique_ptr<sqlite3_stmt, Finalizer> m_statement;
};

// Rolls back on destruction unless commit() succeeded.
class Transaction
{
public:
  explicit Transaction(Database& db);
  ~Transaction();
  Transaction(const Transaction&) = delete;
  Transaction& operator=(const Transaction&) = delete;

  void commit();

private:
  Database& m_db;
  bool m_committed = false;
};

}
