import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

part 'pop3_model.dart';

class Pop3Client {
  final String host;
  final int port;
  final bool showLogs;

  late final SecureSocket _socket;

  Pop3Client({
    required this.host,
    required this.port,
    this.showLogs = false,
  });

  Future<bool> connect({
    required String user,
    required String password,
  }) async {
    final completer = Completer<bool>();
    try {
      _socket = await SecureSocket.connect(host, port);
      _socket.listen(
        (Uint8List event) {
          final message = utf8.decode(event);
          if (showLogs) {
            print("${DateTime.now().toIso8601String()}: $message");
          }
          if (message.contains('send PASS')) {
            _socket
                .add(utf8.encode('${Pop3Commands.pass.command} $password\r\n'));
          }
          if (message.contains('Welcome')) {
            completer.complete(true);
          }
        },
      );

      _socket.add(utf8.encode('${Pop3Commands.user.command} $user\r\n'));
    } catch (e) {
      completer.complete(false);
    }

    return completer.future;
  }

  void noop() {
    _socket.add(utf8.encode('${Pop3Commands.noop.command}\r\n'));
  }

  void load([int? index]) {
    if (index == null) {
      _socket.add(utf8.encode('${Pop3Commands.list.command}\r\n'));
    } else {
      _socket.add(utf8.encode('${Pop3Commands.list.command} $index\r\n'));
    }
  }

  void show(int index) {
    _socket.add(utf8.encode('${Pop3Commands.retr.command} $index\r\n'));
  }

  Future<void> disconnect() async {
    _socket.add(utf8.encode('${Pop3Commands.quit.command}\r\n'));
    await _socket.close();
  }
}
