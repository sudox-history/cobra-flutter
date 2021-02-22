#include "include/dart_api_dl.h"

#ifndef COBRA_FLUTTER_FSOCKET_HPP
#define COBRA_FLUTTER_FSOCKET_HPP

typedef struct fsocket_data fsocket_data;

struct fsocket_data {
    Dart_PostCObject_Type post_obj_func;
    Dart_CloseNativePort_Type close_port_func;
    Dart_Port write_port;
    Dart_Port port;
};

#endif