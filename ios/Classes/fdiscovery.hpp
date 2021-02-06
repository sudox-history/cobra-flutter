#include "include/dart_api_dl.h"

#ifndef COBRA_FLUTTER_FDISCOVERY_HPP
#define COBRA_FLUTTER_FDISCOVERY_HPP

typedef struct fdiscovery_data fdiscovery_data;

struct fdiscovery_data {
    Dart_PostCObject_Type post_obj_func;
    Dart_Port port;
};

#endif