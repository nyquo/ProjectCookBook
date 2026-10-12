# SQLite

| | |
| --- | --- |
| Version | 3.53.4 (source id `2026-07-24 19:02:57 bf7c7f30…`) |
| Source | <https://www.sqlite.org/2026/sqlite-amalgamation-3530400.zip> |
| SHA3-256 of the zip | `628a44cfe82c66aed1ccbbe85a562d2e33ebe64b3288981ed76285612227934e` |
| License | Public domain |
| Files kept | `sqlite3.c`, `sqlite3.h` (unmodified) |

To update: download the new amalgamation zip from <https://www.sqlite.org/download.html>, check its SHA3-256 against the one on that page (`openssl dgst -sha3-256 <zip>`), copy the two files over, and update this table.

## Compile-time options

Set in `CMakeLists.txt`. Most come from sqlite.org's [recommended options](https://www.sqlite.org/compile.html#recommended_compile_time_options).

| Option | Why |
| --- | --- |
| `SQLITE_DQS=0` | `"x"` is always an identifier, never a string literal: typos fail instead of silently comparing to a string. |
| `SQLITE_DEFAULT_FOREIGN_KEYS=1` | Foreign keys on by default; `core::Database` also sets the pragma explicitly. |
| `SQLITE_OMIT_LOAD_EXTENSION` | No loading of native extensions at runtime. Also removes the `-ldl` dependency on Linux. |
| `SQLITE_THREADSAFE=2` | Each connection used by one thread at a time. The recommended `0` removes all locking, which would become a trap if database work ever moves to a worker thread. |
| `SQLITE_DEFAULT_MEMSTATUS=0` | Faster allocations; we never read `sqlite3_status()`. |
| `SQLITE_LIKE_DOESNT_MATCH_BLOBS` | Recommended; we store no blobs. |
| `SQLITE_MAX_EXPR_DEPTH=0` | Recommended; all our SQL is static. |
| `SQLITE_OMIT_DECLTYPE`, `SQLITE_OMIT_DEPRECATED`, `SQLITE_OMIT_PROGRESS_CALLBACK`, `SQLITE_OMIT_SHARED_CACHE` | Recommended; features we don't use. |
| `SQLITE_USE_ALLOCA` | Recommended; slightly faster, available on every toolchain we use. |
| `SQLITE_STRICT_SUBTYPE=1` | Recommended; harmless (we define no SQL functions). |

Recommended but not used:

* `SQLITE_OMIT_AUTOINIT`: crashes if any SQLite call comes before `sqlite3_initialize()`, for no measurable gain.
* `SQLITE_DEFAULT_WAL_SYNCHRONOUS`: only applies to WAL journal mode, which we don't use.
