# Version and the reasons for each option: README.md.
add_library(sqlite STATIC sqlite3.c)

target_include_directories(sqlite SYSTEM PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")

# PUBLIC: some options also change what sqlite3.h declares (e.g. OMIT_DEPRECATED).
target_compile_definitions(sqlite PUBLIC
    SQLITE_DQS=0
    SQLITE_DEFAULT_FOREIGN_KEYS=1
    SQLITE_OMIT_LOAD_EXTENSION
    SQLITE_THREADSAFE=2
    SQLITE_DEFAULT_MEMSTATUS=0
    SQLITE_LIKE_DOESNT_MATCH_BLOBS
    SQLITE_MAX_EXPR_DEPTH=0
    SQLITE_OMIT_DECLTYPE
    SQLITE_OMIT_DEPRECATED
    SQLITE_OMIT_PROGRESS_CALLBACK
    SQLITE_OMIT_SHARED_CACHE
    SQLITE_USE_ALLOCA
    SQLITE_STRICT_SUBTYPE=1
)

# On Android it ends up inside the app's shared library, hence position-independent.
target_compile_options(sqlite PRIVATE $<IF:$<C_COMPILER_ID:MSVC>,/W0,-w>)
set_target_properties(sqlite PROPERTIES POSITION_INDEPENDENT_CODE ON)
