import 'dart:async';
import 'dart:collection';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:async/async.dart';
import 'package:cobra_flutter/loader.dart';
import 'package:cobra_flutter/socket/socket_errors.dart';
import 'package:cobra_flutter/socket/socket_events.dart';
import 'package:ffi/ffi.dart';
import 'package:meta/meta.dart';
import 'package:stream_channel/stream_channel.dart';

final _connectFunction = CobraLoader.cobraLibrary.lookupFunction<
    Pointer Function(
        Pointer<Utf8>, Pointer<Utf8>, Int32, Int64, Pointer, Pointer, Pointer),
    Pointer Function(
        Pointer<Utf8>, Pointer<Utf8>, int, int, Pointer, Pointer, Pointer)>(
  "fsocket_connect",
);

final _closeFunction = CobraLoader.cobraLibrary
    .lookupFunction<Void Function(Pointer), void Function(Pointer)>(
  "fsocket_close",
);

final _prepareFunction = CobraLoader.cobraLibrary.lookupFunction<
    Void Function(Pointer, Int64, Pointer, Pointer, Pointer, Int8),
    void Function(Pointer, int, Pointer, Pointer, Pointer, int)>(
  "fsocket_prepare",
);

final _destroyFunction = CobraLoader.cobraLibrary
    .lookupFunction<Void Function(Pointer), void Function(Pointer)>(
  "fsocket_destroy",
);

class CobraSocket extends StreamChannelMixin {
  static const _defaultConnectTimeout = Duration(seconds: 10);

  Pointer _pointer;
  Completer _completer;
  Timer _connectTimeoutTimer;
  Pointer<Utf8> _hostPointer;
  Pointer<Utf8> _portPointer;
  Queue<Uint8List> _writeQueue = Queue();
  ReceivePort _eventsPort = ReceivePort();
  StreamSubscription _writeSubscription;
  StreamSubscription _eventsSubscription;
  StreamController<Uint8List> _writeController = StreamController();
  StreamController<CobraSocketEvent> _readController =
      StreamController.broadcast();

  @protected
  CobraSocket({int pointer = -1}) {
    _eventsSubscription = _eventsPort.listen((data) {
      if (data == null) {
        _readController.add(CobraSocketDrainEvent());
      } else if (data is SendPort) {
        _connectTimeoutTimer.cancel();
        _connectTimeoutTimer = null;
        _listenWriteRequests(data);
        _completer?.complete(this);
        _completer = null;
      } else if (data is Uint8List) {
        _readController.add(CobraSocketDataEvent(data));
      } else if (data is List) {
        _readController.addError(CobraSocketException(data[0]));

        if (data[1]) {
          _connectTimeoutTimer?.cancel();
          _readController.close();
          _writeController.close();
          _eventsPort.close();

          if (_hostPointer != null && _portPointer != null) {
            free(_hostPointer);
            free(_portPointer);
          }

          _destroyFunction(_pointer);
          _eventsSubscription.cancel();
          _writeSubscription.cancel();
          _completer?.completeError(CobraSocketException(data[0]));
        }
      } else if (data is int) {
        _writeQueue.removeFirst();
      }
    });

    if (pointer != -1) {
      _pointer = Pointer.fromAddress(pointer);
      _prepareFunction(
        _pointer,
        _eventsPort.sendPort.nativePort,
        NativeApi.postCObject,
        NativeApi.closeNativePort,
        NativeApi.newNativePort,
        1,
      );
    }
  }

  static Future<CobraSocket> connect(
    String host,
    String port, {
    int writeQueueLength = 32,
    Duration connectTimeout = _defaultConnectTimeout,
  }) {
    var completer = Completer<CobraSocket>();
    var socket = CobraSocket();

    socket._connect(
      host,
      port,
      writeQueueLength,
      connectTimeout,
      completer,
    );

    return completer.future;
  }

  void _listenWriteRequests(SendPort data) {
    _writeSubscription = _writeController.stream.listen((bytes) {
      _writeQueue.addFirst(bytes);
      data.send([_pointer.address, bytes]);
    });
  }

  void _connect(
    String host,
    String port,
    int writeQueueLength,
    Duration connectTimeout,
    Completer<CobraSocket> completer,
  ) {
    _completer = completer;
    _hostPointer = Utf8.toUtf8(host);
    _portPointer = Utf8.toUtf8(port);
    _connectTimeoutTimer = Timer(connectTimeout, () {
      sink.close();
    });

    _pointer = _connectFunction(
      _hostPointer,
      _portPointer,
      writeQueueLength,
      _eventsPort.sendPort.nativePort,
      NativeApi.postCObject,
      NativeApi.closeNativePort,
      NativeApi.newNativePort,
    );
  }

  @override
  Stream<CobraSocketEvent> get stream => _readController.stream;

  @override
  StreamSink<Uint8List> get sink =>
      _SocketStreamSink(this, _writeController.sink);
}

class _SocketStreamSink extends DelegatingStreamSink<Uint8List> {
  final CobraSocket _socket;

  _SocketStreamSink(
    this._socket,
    StreamSink<Uint8List> sink,
  ) : super(sink);

  @override
  Future close() {
    _closeFunction(_socket._pointer);
    return super.close();
  }
}
