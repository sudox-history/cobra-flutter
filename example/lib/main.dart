import 'dart:io';
import 'dart:typed_data';

import 'package:cobra_flutter/socket/socket.dart';

void main() {
  CobraSocket.connect("192.168.8.101", "5556").then((socket) {});
}
