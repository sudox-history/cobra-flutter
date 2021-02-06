#include "fdiscovery.hpp"
#include <cobra.h>

void on_address_found(cobra_discovery_t *discovery, char *host) {
    Dart_CObject object;
    object.type = Dart_CObject_kString;
    object.value.as_string = host;

    auto *data = static_cast<fdiscovery_data *>(cobra_discovery_get_data(discovery));
    data->post_obj_func(data->port, &object);
}

void on_discovery_close(cobra_discovery_t *discovery, cobra_discovery_err_t error) {
    Dart_CObject object;
    object.type = Dart_CObject_kInt32;
    object.value.as_int32 = error;

    auto *data = static_cast<fdiscovery_data *>(cobra_discovery_get_data(discovery));
    data->post_obj_func(data->port, &object);
}

cobra_discovery_t* prepare_discovery(Dart_PostCObject_Type post_obj_func, Dart_Port port) {
    auto data = new fdiscovery_data;
    data->post_obj_func = post_obj_func;
    data->port = port;

    auto *discovery = cobra_discovery_create();
    cobra_discovery_set_data(discovery, data);

    return discovery;
}

extern "C"
cobra_discovery_t* fdiscovery_scan(Dart_PostCObject_Type post_obj_func, Dart_Port port) {
    auto discovery = prepare_discovery(post_obj_func, port);
    cobra_discovery_set_callbacks(discovery, on_address_found, on_discovery_close);
    cobra_discovery_scan(discovery);

    return discovery;
}

extern "C"
cobra_discovery_t* fdiscovery_listen(Dart_PostCObject_Type post_obj_func, Dart_Port port) {
    auto discovery = prepare_discovery(post_obj_func, port);
    cobra_discovery_set_callbacks(discovery, nullptr, on_discovery_close);
    cobra_discovery_listen(discovery);

    return discovery;
}

extern "C"
int fdiscovery_get_addresses(cobra_discovery_t* discovery, cobra_discovery_addresses_cb addresses_callback) {
    int res = cobra_discovery_get_addresses(discovery, addresses_callback);
    cobra_discovery_destroy(discovery);

    return res;
}

extern "C"
void fdiscovery_close(cobra_discovery_t *discovery) {
    cobra_discovery_close(discovery);
}

extern "C"
void fdiscovery_destroy(cobra_discovery_t* discovery) {
    delete static_cast<fdiscovery_data *>(cobra_discovery_get_data(discovery));
    cobra_discovery_destroy(discovery);
}