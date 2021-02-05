import 'dart:collection';
import 'dart:ffi';
import 'dart:async';
import 'dart:isolate';
import 'package:async/async.dart';
import 'package:cobra_flutter/discovery/discovery_errors.dart';
import 'package:cobra_flutter/loader.dart';
import 'package:ffi/ffi.dart';

final _createFunction = CobraLoader.cobraLibrary
    .lookupFunction<Pointer Function(), Pointer Function()>(
  "cobra_discovery_create",
);

final _scanFunction = CobraLoader.cobraLibrary.lookupFunction<
    Pointer Function(Pointer, Int64), Pointer Function(Pointer, int)>(
  "fdiscovery_scan",
);

final _getAddressesFunction = CobraLoader.cobraLibrary.lookupFunction<
    Int32 Function(Pointer,
        Pointer<NativeFunction<Void Function(Pointer, Pointer<Utf8>)>>),
    int Function(Pointer,
        Pointer<NativeFunction<Void Function(Pointer, Pointer<Utf8>)>>)>(
  "fdiscovery_get_addresses",
);

final _listenFunction = CobraLoader.cobraLibrary.lookupFunction<
    Pointer Function(Pointer, Int64), Pointer Function(Pointer, int)>(
  "fdiscovery_listen",
);

final _closeFunction = CobraLoader.cobraLibrary
    .lookupFunction<Void Function(Pointer), void Function(Pointer)>(
  "fdiscovery_close",
);

final _destroyFunction = CobraLoader.cobraLibrary
    .lookupFunction<Void Function(Pointer), void Function(Pointer)>(
  "fdiscovery_destroy",
);

class CobraDiscoveryListener {
  final ReceivePort _port = ReceivePort();
  Completer _completer;
  Pointer _pointer;

  CobraDiscoveryListener._() {
    _port.listen((data) {
      if (data is int) {
        _destroyFunction(_pointer);
        _completer.completeError(CobraDiscoveryException(data));
        _port.close();
      }
    });
  }

  static CancelableOperation<void> listen() {
    var listener = CobraDiscoveryListener._();
    var completer = CancelableCompleter(onCancel: () {
      _closeFunction(listener._pointer);
    });

    listener._pointer = _listenFunction(
      NativeApi.postCObject,
      listener._port.sendPort.nativePort,
    );

    return completer.operation;
  }
}

class CobraDiscoveryScanner {
  final ReceivePort _port = ReceivePort();
  StreamController<String> _controller;
  Pointer _pointer;

  CobraDiscoveryScanner._() {
    _controller = StreamController<String>.broadcast(
      onListen: () {
        _port.listen((data) {
          if (data is String) {
            _controller.sink.add(data);
          } else if (data is int) {
            _destroyFunction(_pointer);
            _controller.addError(CobraDiscoveryException(data));
            _controller.close();
            _port.close();
          }
        });

        _pointer = _scanFunction(
          NativeApi.postCObject,
          _port.sendPort.nativePort,
        );
      },
      onCancel: () {
        _closeFunction(_pointer);
      },
    );
  }

  static Stream<String> scan() {
    return CobraDiscoveryScanner._()._controller.stream;
  }
}

class CobraDiscoveryUtils {
  static Map<Pointer, List<String>> _pointersMap = HashMap();

  CobraDiscoveryUtils._();

  static List<String> getAddresses() {
    var pointer = _createFunction();
    var addresses = List<String>();
    _pointersMap[pointer] = addresses;

    var result = _getAddressesFunction(
      pointer,
      Pointer.fromFunction(_onInterfaceFound),
    );

    _pointersMap.remove(pointer);

    if (result != 0) {
      throw CobraDiscoveryException(result);
    }

    return addresses;
  }

  static void _onInterfaceFound(Pointer pointer, Pointer<Utf8> host) {
    _pointersMap[pointer].add(
      Utf8.fromUtf8(host),
    );
  }
}
