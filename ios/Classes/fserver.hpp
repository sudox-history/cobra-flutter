#include "include/dart_api_dl.h"

#ifndef COBRA_FLUTTER_FSERVER_HPP
#define COBRA_FLUTTER_FSERVER_HPP

typedef struct fserver_data fserver_data;

struct fserver_data {
    Dart_PostCObject_Type post_obj_func;
    Dart_Port port;
};

#endif