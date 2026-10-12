add_executable(coreTests
    main.cpp
    testSupport.hpp
    aisleStoreTests.cpp
    backendTests.cpp
    databaseTests.cpp
    migrationsTests.cpp
    uuidTests.cpp
)

# sqlite for its result-code constants only.
target_link_libraries(coreTests PRIVATE core sqlite doctest)
cookbook_set_warnings(coreTests)

add_test(NAME coreTests COMMAND coreTests)
