import 'dart:typed_data';
import 'package:cobra_flutter/socket/socket.dart';

void main() {
  var data = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);

  CobraSocket.connect("192.168.8.101", "5556", 32).then((socket) {
    socket.sink.add(data);
  });
}
