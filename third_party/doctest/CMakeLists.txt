add_library(doctest INTERFACE)
# SYSTEM: our warning flags don't apply to its header
target_include_directories(doctest SYSTEM INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}")
