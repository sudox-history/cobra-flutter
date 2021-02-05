import 'dart:ffi';
import 'dart:io';

class CobraLoader {
  static final DynamicLibrary cobraLibrary = Platform.isAndroid
      ? DynamicLibrary.open("libcobra_flutter.so")
      : DynamicLibrary.process();
}
