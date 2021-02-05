enum CobraDiscoveryError {
  COBRA_DISCOVERY_OK,
  COBRA_DISCOVERY_ERR_ALREADY_OPENED,
  COBRA_DISCOVERY_ERR_ALREADY_CLOSED,
  COBRA_DISCOVERY_ERR_BINDING,
  COBRA_DISCOVERY_ERR_JOINING_GROUP,
  COBRA_DISCOVERY_ERR_SENDING_FRAME,
  COBRA_DISCOVERY_ERR_NOT_CLOSED,
  COBRA_DISCOVERY_ERR_GETTING_ADDRESSES
}

class CobraDiscoveryException implements Exception {
  final CobraDiscoveryError error;

  CobraDiscoveryException(
    int code,
  ) : error = CobraDiscoveryError.values[code];

  @override
  String toString() => "CobraDiscoveryException: $error";
}
