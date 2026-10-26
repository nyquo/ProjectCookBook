add_executable(coreTests
    main.cpp
    testSupport.hpp
    aisleStoreTests.cpp
    backendTests.cpp
    catalogViewTests.cpp
    databaseTests.cpp
    defaultFiltersTests.cpp
    ingredientStoreTests.cpp
    listEditsTests.cpp
    migrationsTests.cpp
    settingStoreTests.cpp
    tagColorStoreTests.cpp
    tagStoreTests.cpp
    tagViewTests.cpp
    textTests.cpp
    themedColorsTests.cpp
    uuidTests.cpp
)

# sqlite for its result-code constants only
target_link_libraries(coreTests PRIVATE core sqlite doctest)
cookbook_set_warnings(coreTests)

add_test(NAME coreTests COMMAND coreTests)
