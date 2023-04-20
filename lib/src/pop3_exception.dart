class Pop3Expetion implements Exception {
  const Pop3Expetion([this.message]);
  final String? message;
}

class Pop3SocketExpetion implements Pop3Expetion {
  const Pop3SocketExpetion([this.message]);
  @override
  final String? message;
}
