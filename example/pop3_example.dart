import 'package:pop3/pop3.dart';

void main(List<String> args) async {
  final client = Pop3Client(
    host: 'pop.gmail.com',
    port: 995,
    showLogs: true,
  );
  final connected = await client.connect(user: 'username', password: 'pass');
  if (connected) {
    client.noop();
  }
}
