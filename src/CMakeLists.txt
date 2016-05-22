cmake_minimum_required(VERSION 2.8)
project(landmarks)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_SOURCE_DIR}/)

find_package(Lua52 REQUIRED)
include_directories(${LUA_INCLUDE_DIR})

find_package(PkgConfig)
pkg_check_modules(ARGOS REQUIRED argos3_simulator)

include_directories(${ARGOS_INCLUDE_DIRS})
link_directories(${ARGOS_LIBRARY_DIRS})

include(ARGoSCheckQTOpenGL)

add_library(landmarks SHARED landmarks.h landmarks.cpp)
add_library(id_loop_functions SHARED id_qtuser_functions.h id_qtuser_functions.cpp)

target_link_libraries(landmarks ${ARGOS_LIBRARIES} ${LUA_LIBRARIES} argos3plugin_simulator_footbot)
target_link_libraries(id_loop_functions argos3core_simulator argos3plugin_simulator_entities
  argos3plugin_simulator_footbot
  argos3plugin_simulator_qtopengl
  ${QT_LIBRARIES} ${GLUT_LIBRARY} ${OPENGL_LIBRARY})