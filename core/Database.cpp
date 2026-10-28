#include "core/Database.hpp"

#include <sqlite3.h>

namespace core {

DatabaseError::DatabaseError(int code, const std::string& message)
  : std::runtime_error(message)
  , m_code(code)
{
}

void Database::Closer::operator()(sqlite3* db) const noexcept
{
  sqlite3_close_v2(db);
}

Database::Database(const std::filesystem::path& path)
{
  // SQLite expects UTF-8 file names on every platform
  const std::u8string u8Path = path.u8string();
  const std::string fileName(u8Path.begin(), u8Path.end());

  sqlite3* db = nullptr;
  const int result = sqlite3_open_v2(
    fileName.c_str(),
    &db,
    SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_EXRESCODE,
    nullptr);
  m_db.reset(db); // SQLite allocates a handle even when opening fails
  if (result != SQLITE_OK) {
    throw DatabaseError(result,
                        std::string(sqlite3_errstr(result)) + ": " + fileName);
  }

  exec("PRAGMA foreign_keys = ON");
}

void Database::exec(std::string_view sql)
{
  const char* tail = sql.data();
  const char* const end = sql.data() + sql.size();
  while (tail < end) {
    sqlite3_stmt* raw = nullptr;
    const int result = sqlite3_prepare_v2(
      m_db.get(), tail, static_cast<int>(end - tail), &raw, &tail);
    if (result != SQLITE_OK) {
      throw DatabaseError(sqlite3_extended_errcode(m_db.get()),
                          sqlite3_errmsg(m_db.get()));
    }
    if (!raw) {
      continue; // only whitespace or comments were left
    }
    Statement statement(m_db.get(), raw);
    statement.run();
  }
}

Statement Database::prepare(std::string_view sql)
{
  sqlite3_stmt* raw = nullptr;
  const int result = sqlite3_prepare_v2(
    m_db.get(), sql.data(), static_cast<int>(sql.size()), &raw, nullptr);
  if (result != SQLITE_OK) {
    throw DatabaseError(sqlite3_extended_errcode(m_db.get()),
                        sqlite3_errmsg(m_db.get()));
  }
  return Statement(m_db.get(), raw);
}

void Statement::Finalizer::operator()(sqlite3_stmt* statement) const noexcept
{
  sqlite3_finalize(statement);
}

Statement::Statement(sqlite3* db, sqlite3_stmt* statement)
  : m_db(db)
  , m_statement(statement)
{
}

Statement& Statement::bindInt64(int index, std::int64_t value)
{
  check(sqlite3_bind_int64(m_statement.get(), index, value));
  return *this;
}

Statement& Statement::bind(int index, double value)
{
  check(sqlite3_bind_double(m_statement.get(), index, value));
  return *this;
}

Statement& Statement::bindNull(int index)
{
  check(sqlite3_bind_null(m_statement.get(), index));
  return *this;
}

Statement& Statement::bind(int index, std::string_view value)
{
  // An empty view may have a null data(), which SQLite would bind as NULL.
  // SQLITE_TRANSIENT makes SQLite copy the text.
  check(sqlite3_bind_text64(m_statement.get(),
                            index,
                            value.empty() ? "" : value.data(),
                            value.size(),
                            SQLITE_TRANSIENT,
                            SQLITE_UTF8));
  return *this;
}

bool Statement::step()
{
  const int result = sqlite3_step(m_statement.get());
  if (result == SQLITE_ROW) {
    return true;
  }
  if (result == SQLITE_DONE) {
    return false;
  }
  check(result);
  return false;
}

void Statement::run()
{
  while (step()) {
  }
}

bool Statement::columnIsNull(int index) const
{
  return sqlite3_column_type(m_statement.get(), index) == SQLITE_NULL;
}

std::int64_t Statement::columnInt64(int index) const
{
  return sqlite3_column_int64(m_statement.get(), index);
}

double Statement::columnDouble(int index) const
{
  return sqlite3_column_double(m_statement.get(), index);
}

std::string Statement::columnText(int index) const
{
  // Text before size: the order SQLite documents as safe
  const auto* text = reinterpret_cast<const char*>(
    sqlite3_column_text(m_statement.get(), index));
  const int size = sqlite3_column_bytes(m_statement.get(), index);
  return text ? std::string(text, static_cast<std::size_t>(size))
              : std::string();
}

void Statement::check(int result) const
{
  if (result != SQLITE_OK) {
    throw DatabaseError(sqlite3_extended_errcode(m_db), sqlite3_errmsg(m_db));
  }
}

Transaction::Transaction(Database& db)
  : m_db(db)
{
  // IMMEDIATE takes the write lock now rather than at the first write, so a
  // transaction never fails halfway because another connection holds it.
  m_db.exec("BEGIN IMMEDIATE");
}

Transaction::~Transaction()
{
  if (m_committed) {
    return;
  }
  try {
    m_db.exec("ROLLBACK");
  } catch (const DatabaseError&) {
    // Some errors already rolled the transaction back
  }
}

void Transaction::commit()
{
  m_db.exec("COMMIT");
  m_committed = true;
}

}
