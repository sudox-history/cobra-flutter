#include "fdiscovery.h"
#include <stdlib.h>
#include <cobra.h>

void on_address_found(cobra_discovery_t *discovery, char *host) {
    Dart_CObject object;
    object.type = Dart_CObject_kString;
    object.value.as_string = host;

    fdiscovery_data *data = (fdiscovery_data *) cobra_discovery_get_data(discovery);
    data->post_obj_func(data->port, &object);
}

void on_discovery_close(cobra_discovery_t *discovery, cobra_discovery_err_t error) {
    Dart_CObject object;
    object.type = Dart_CObject_kInt32;
    object.value.as_int32 = error;

    fdiscovery_data *data = (fdiscovery_data *) cobra_discovery_get_data(discovery);
    data->post_obj_func(data->port, &object);
}

cobra_discovery_t* prepare_discovery(Dart_PostCObject_Type post_obj_func, Dart_Port port) {
    fdiscovery_data* data = malloc(sizeof(fdiscovery_data));
    data->post_obj_func = post_obj_func;
    data->port = port;

    cobra_discovery_t *discovery = cobra_discovery_create();
    cobra_discovery_set_data(discovery, data);

    return discovery;
}

cobra_discovery_t* fdiscovery_scan(Dart_PostCObject_Type post_obj_func, Dart_Port port) {
    cobra_discovery_t* discovery = prepare_discovery(post_obj_func, port);
    cobra_discovery_set_callbacks(discovery, on_address_found, on_discovery_close);
    cobra_discovery_scan(discovery);

    return discovery;
}

cobra_discovery_t* fdiscovery_listen(Dart_PostCObject_Type post_obj_func, Dart_Port port) {
    cobra_discovery_t* discovery = prepare_discovery(post_obj_func, port);
    cobra_discovery_set_callbacks(discovery, NULL, on_discovery_close);
    cobra_discovery_listen(discovery);

    return discovery;
}

int fdiscovery_get_addresses(cobra_discovery_t* discovery, cobra_discovery_addresses_cb addresses_callback) {
    int res = cobra_discovery_get_addresses(discovery, addresses_callback);
    cobra_discovery_destroy(discovery);

    return res;
}

void fdiscovery_close(cobra_discovery_t *discovery) {
    cobra_discovery_close(discovery);
}

void fdiscovery_destroy(cobra_discovery_t* discovery) {
    free(cobra_discovery_get_data(discovery));
    cobra_discovery_destroy(discovery);
}