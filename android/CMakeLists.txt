cmake_minimum_required(VERSION 3.6)
add_subdirectory(../libcobra ${CMAKE_CURRENT_BINARY_DIR}/libcobra_build)
add_library(cobra_flutter SHARED
        ../ios/Classes/fsocket.cpp
        ../ios/Classes/fsocket.hpp
        ../ios/Classes/fserver.cpp
        ../ios/Classes/fserver.hpp
        ../ios/Classes/fdiscovery.cpp
        ../ios/Classes/fdiscovery.hpp
        )

target_link_libraries(cobra_flutter cobra_a)