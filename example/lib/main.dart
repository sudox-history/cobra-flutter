import 'dart:io';
import 'dart:typed_data';

import 'package:cobra_flutter/socket/socket.dart';

void main() {
  CobraSocket.connect("45.138.157.33", "5555").then((socket) {
    socket.sink.add(Uint8List.fromList([1, 2, 3]));
  });
}
