import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'package:cobra_flutter/loader.dart';
import 'package:cobra_flutter/server/server_errors.dart';
import 'package:cobra_flutter/socket/socket.dart';
import 'package:ffi/ffi.dart';

final _bindFunction = CobraLoader.cobraLibrary.lookupFunction<
    Pointer Function(Pointer<Utf8>, Pointer<Utf8>, Int32, Int64, Pointer),
    Pointer Function(Pointer<Utf8>, Pointer<Utf8>, int, int, Pointer)>(
  "fserver_bind",
);

final _closeFunction = CobraLoader.cobraLibrary
    .lookupFunction<Void Function(Pointer), void Function(Pointer)>(
  "fserver_close",
);

final _destroyFunction = CobraLoader.cobraLibrary
    .lookupFunction<Void Function(Pointer), void Function(Pointer)>(
  "fserver_destroy",
);

class CobraServer {
  StreamController<CobraSocket> _controller;
  Pointer _pointer;

  CobraServer._();

  static Stream<CobraSocket> bind(
    String host,
    String port,
    int socketWriteQueueLength,
  ) {
    var server = CobraServer._();

    server._controller = StreamController<CobraSocket>.broadcast(
      onListen: () {
        server._bind(host, port, socketWriteQueueLength);
      },
      onCancel: () {
        server._close();
      },
    );

    return server._controller.stream;
  }

  void _bind(
    String host,
    String port,
    int socketWriteQueueLength,
  ) {
    var eventsPort = ReceivePort();
    var hostPointer = Utf8.toUtf8(host);
    var portPointer = Utf8.toUtf8(port);

    eventsPort.listen((data) {
      if (data is int) {
        _controller.add(CobraSocket(pointer: data));
      } else if (data is List<int>) {
        _controller.addError(CobraServerException(data[0]));
        _controller.close();
        eventsPort.close();

        _destroyFunction(_pointer);
        free(hostPointer);
        free(portPointer);
      }
    });

    _pointer = _bindFunction(
      hostPointer,
      portPointer,
      socketWriteQueueLength,
      eventsPort.sendPort.nativePort,
      NativeApi.postCObject,
    );
  }

  void _close() {
    _closeFunction(_pointer);
  }
}
