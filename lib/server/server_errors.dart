enum CobraServerError {
  COBRA_SERVER_OK,
  COBRA_SERVER_ERR_ALREADY_OPENED,
  COBRA_SERVER_ERR_ALREADY_CLOSED,
  COBRA_SERVER_ERR_RESOLVING,
  COBRA_SERVER_ERR_BINDING,
  COBRA_SERVER_ERR_LISTENING,
  COBRA_SERVER_ERR_NOT_CLOSED
}

class CobraServerException implements Exception {
  final CobraServerError error;

  CobraServerException(
    int code,
  ) : error = CobraServerError.values[code];

  @override
  String toString() => "CobraServerException: $error";
}
