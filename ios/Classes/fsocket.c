#include "fsocket.h"
#include <cobra.h>
#include <stdlib.h>

void free_buffer(void *_, void *pointer) {
    free(pointer);
}

void post_object_to_port(cobra_socket_t *socket, Dart_CObject *object) {
    fsocket_data *data = (fsocket_data *) cobra_socket_get_data(socket);
    data->post_obj_func(data->port, object);
}

void on_socket_connect(cobra_socket_t *socket) {
    Dart_CObject object;
    fsocket_data *data = (fsocket_data *) cobra_socket_get_data(socket);
    object.type = Dart_CObject_kSendPort;
    object.value.as_send_port.id = data->write_port;

    post_object_to_port(socket, &object);
}

void on_socket_close(cobra_socket_t *socket, cobra_socket_err_t error) {
    Dart_CObject resObject;
    resObject.type = Dart_CObject_kInt32;
    resObject.value.as_int32 = error;

    Dart_CObject closeObject;
    closeObject.type = Dart_CObject_kBool;
    closeObject.value.as_bool = true;

    Dart_CObject result;
    Dart_CObject* array[] = {&resObject, &closeObject};
    result.type = Dart_CObject_kArray;
    result.value.as_array.length = 2;
    result.value.as_array.values = array;

    post_object_to_port(socket, &result);
}

void on_socket_alloc(cobra_socket_t *socket, uint8_t **data, uint64_t length) {
    *data = malloc(length);
}

void on_socket_read(cobra_socket_t *socket, uint8_t *data, uint64_t length) {
    Dart_CObject object;
    object.type = Dart_CObject_kExternalTypedData;
    object.value.as_external_typed_data.type = Dart_TypedData_kUint8;
    object.value.as_external_typed_data.length = length;
    object.value.as_external_typed_data.callback = free_buffer;
    object.value.as_external_typed_data.peer = data;
    object.value.as_external_typed_data.data = data;

    post_object_to_port(socket, &object);
}

void on_socket_drain(cobra_socket_t *socket) {
    Dart_CObject object;
    object.type = Dart_CObject_kNull;

    post_object_to_port(socket, &object);
}

void
on_write_request(Dart_Port port, Dart_CObject *data) {
    cobra_socket_t *socket = (cobra_socket_t *) ((intptr_t) data->value.as_array.values[0]->value.as_int64);
    intptr_t length = data->value.as_array.values[1]->value.as_typed_data.length;
    uint8_t *bytes = data->value.as_array.values[1]->value.as_typed_data.values;
    cobra_socket_err_t result = cobra_socket_write(socket, bytes, length);

    if (result != COBRA_SOCKET_OK) {
        Dart_CObject resObject;
        resObject.type = Dart_CObject_kInt32;
        resObject.value.as_int32 = result;

        Dart_CObject closeObject;
        closeObject.type = Dart_CObject_kBool;
        closeObject.value.as_bool = false;

        Dart_CObject resultObj;
        Dart_CObject *array[] = {&resObject, &closeObject};
        resultObj.type = Dart_CObject_kArray;
        resultObj.value.as_array.length = 2;
        resultObj.value.as_array.values = array;

        post_object_to_port(socket, &resultObj);
    }
}

Dart_Port fsocket_prepare(
        cobra_socket_t *socket,
        Dart_Port events_port,
        Dart_PostCObject_Type post_obj_func,
        Dart_CloseNativePort_Type close_port_func,
        Dart_NewNativePort_Type new_port_func,
        bool force_send_port
) {

    fsocket_data *data = malloc(sizeof(fsocket_data));
    data->post_obj_func = post_obj_func;
    data->close_port_func = close_port_func;
    data->write_port = new_port_func("socket_write", on_write_request, false);
    data->port = events_port;

    cobra_socket_set_data(socket, data);
    cobra_socket_set_callbacks(
            socket,
            on_socket_connect,
            on_socket_close,
            on_socket_alloc,
            on_socket_read,
            NULL,
            on_socket_drain
    );

    if (force_send_port) {
        on_socket_connect(socket);
    }

    return data->write_port;
}

cobra_socket_t *fsocket_connect(
        char *host,
        char *port,
        int write_queue_length,
        Dart_Port events_port,
        Dart_PostCObject_Type post_obj_func,
        Dart_CloseNativePort_Type close_port_func,
        Dart_NewNativePort_Type new_port_func
) {
    cobra_socket_t *socket = cobra_socket_create(write_queue_length);
    fsocket_prepare(socket, events_port, post_obj_func, close_port_func, new_port_func, false);
    cobra_socket_connect(socket, host, port);

    return socket;
}

void fsocket_destroy(cobra_socket_t *socket) {
    fsocket_data *data = (fsocket_data *) cobra_socket_get_data(socket);

    data->close_port_func(data->write_port);
    cobra_socket_destroy(socket);
    free(data);
}

void fsocket_close(cobra_socket_t *socket) {
    cobra_socket_close(socket);
}