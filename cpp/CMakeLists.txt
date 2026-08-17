cmake_minimum_required(VERSION 3.20)
project(tally_core LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library(tally_core core/rarity_engine.cpp)
target_include_directories(tally_core PUBLIC core)

enable_testing()
add_executable(rarity_engine_tests core/tests/rarity_engine_tests.cpp)
target_link_libraries(rarity_engine_tests PRIVATE tally_core)
add_test(NAME rarity_engine_tests COMMAND rarity_engine_tests)

