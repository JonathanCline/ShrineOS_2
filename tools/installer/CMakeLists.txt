cmake_minimum_required (VERSION 3.8)

project ("shrineos-install")

add_executable (${PROJECT_NAME} "main.cpp")

target_compile_features(${PROJECT_NAME} PUBLIC cxx_std_20)
target_compile_definitions(${PROJECT_NAME} PUBLIC
    PROJECT_ROOT="${CMAKE_CURRENT_SOURCE_DIR}/../../"
    OS_SOURCE="${CMAKE_CURRENT_SOURCE_DIR}/../../source/")



install(TARGETS ${PROJECT_NAME} DESTINATION "${CMAKE_CURRENT_SOURCE_DIR}/test")

