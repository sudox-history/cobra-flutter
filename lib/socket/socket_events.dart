import 'dart:typed_data';

abstract class CobraSocketEvent {}

class CobraSocketDataEvent implements CobraSocketEvent {
  final Uint8List data;

  CobraSocketDataEvent(
    this.data,
  );
}

class CobraSocketDrainEvent implements CobraSocketEvent {}
