cmake_minimum_required(VERSION 3.6)
add_subdirectory(../libcobra ${CMAKE_CURRENT_BINARY_DIR}/libcobra_build)
add_library(cobra_flutter SHARED
        ../ios/Classes/fsocket.c
        ../ios/Classes/fsocket.h
        ../ios/Classes/fserver.c
        ../ios/Classes/fserver.h
        ../ios/Classes/fdiscovery.c
        ../ios/Classes/fdiscovery.h
        )

target_link_libraries(cobra_flutter cobra_a)