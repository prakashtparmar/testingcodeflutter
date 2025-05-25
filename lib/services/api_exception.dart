class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  UnauthorizedException() : super('Unauthorized: Please login again.');
}

class NotFoundException extends ApiException {
  NotFoundException() : super('Not Found: The requested resource does not exist.');
}

class ServerErrorException extends ApiException {
  ServerErrorException() : super('Server Error: Please try again later.');
}

class UnknownApiException extends ApiException {
  final int statusCode;
  UnknownApiException(this.statusCode, String message)
      : super('Error $statusCode: $message');
}
