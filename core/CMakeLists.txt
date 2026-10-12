add_library(core STATIC
    Aisle.hpp
    AisleStore.hpp AisleStore.cpp
    Backend.hpp Backend.cpp
    clock.hpp
    Database.hpp Database.cpp
    migrations.hpp migrations.cpp
    UuidV7Generator.hpp UuidV7Generator.cpp
)

# Includes read "core/<file>.hpp".
target_include_directories(core PUBLIC "${PROJECT_SOURCE_DIR}")
target_link_libraries(core PRIVATE sqlite)
# On Android it ends up inside the app's shared library.
set_target_properties(core PROPERTIES POSITION_INDEPENDENT_CODE ON)
cookbook_set_warnings(core)

# CONFIGURE_DEPENDS: adding or removing a migration file re-runs CMake.
file(GLOB migrationFiles CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/schema/*.sql")
set(migrationsHeader "${CMAKE_CURRENT_BINARY_DIR}/generated/migrationsSql.hpp")
add_custom_command(
    OUTPUT "${migrationsHeader}"
    COMMAND "${CMAKE_COMMAND}"
            "-DSCHEMA_DIR=${CMAKE_CURRENT_SOURCE_DIR}/schema"
            "-DOUTPUT=${migrationsHeader}"
            -P "${PROJECT_SOURCE_DIR}/cmake/EmbedMigrations.cmake"
    DEPENDS ${migrationFiles} "${PROJECT_SOURCE_DIR}/cmake/EmbedMigrations.cmake"
    COMMENT "Embedding schema migrations"
    VERBATIM
)
target_sources(core PRIVATE "${migrationsHeader}")
target_include_directories(core PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/generated")
