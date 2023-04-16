import 'package:pop3/pop3.dart';

void main(List<String> args) async {
  final client = Pop3Client(
    host: 'pop.gmail.com',
    port: 995,
    showLogs: true,
  );
  final connected = await client.connect(
    user: 'gordin.dan',
    password: 'hyubypfhikxaxxju',
  );
  print('connected: $connected');
  if (connected) {
    final result = await client.noop();
    print('result: $result');
  }
}
