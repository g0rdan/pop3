import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:pop3/src/pop3_command.dart';

part 'pop3_model.dart';

class Pop3Client {
  Pop3Client({
    required this.host,
    required this.port,
    this.showLogs = false,
  });

  final String host;
  final int port;
  final bool showLogs;
  late final SecureSocket _socket;
  // ignore: strict_raw_type
  Pop3Command? _lastCommand;

  Future<bool> connect({
    required String user,
    required String password,
  }) async {
    final completer = Completer<bool>();
    try {
      _socket = await SecureSocket.connect(host, port);
      _socket.listen(
        (rawData) {
          final data = utf8.decode(rawData);
          final response = Pop3Response(
            data: data,
            lastCommand: _lastCommand?.type,
          );
          _lastCommand?.completer.complete(data);
          if (showLogs) {
            log('${DateTime.now().toIso8601String()}: ${response.data}');
          }
          if (_lastCommand == null && response.greeting) {
            _executeCommand<String>(
                command: Pop3Command(type: Pop3CommandType.user), arg1: user);
            return;
          }
          if (_lastCommand?.type == Pop3CommandType.user && response.success) {
            _executeCommand<String>(
                command: Pop3Command(type: Pop3CommandType.pass),
                arg1: password);
            return;
          }
          if (_lastCommand?.type == Pop3CommandType.pass && response.success) {
            completer.complete(true);
          }
        },
      );
    } catch (e) {
      completer.complete(false);
    }

    return completer.future;
  }

  Future<String> apop({
    required String user,
    required String pass,
  }) {
    return _executeCommand<String>(
      command: Pop3Command(type: Pop3CommandType.apop),
      arg1: user,
      arg2: pass,
    );
  }

  Future<String> dele({
    required int messageNumber,
  }) {
    return _executeCommand<String>(
      command: Pop3Command(type: Pop3CommandType.dele),
      arg1: messageNumber.toString(),
    );
  }

  Future<String> list({
    int? messageNumber,
  }) {
    return _executeCommand<String>(
      command: Pop3Command(type: Pop3CommandType.list),
      arg1: messageNumber?.toString(),
    );
  }

  Future<Pop3Response> noop() async {
    final responseStr = await _executeCommand<String>(
      command: Pop3Command(type: Pop3CommandType.noop),
    );
    return Pop3Response(
      data: responseStr,
      lastCommand: _lastCommand?.type,
    );
  }

  Future<String> quit() {
    return _executeCommand<String>(
      command: Pop3Command(type: Pop3CommandType.quit),
    );
  }

  Future<String> retr({
    required int messageNumber,
  }) {
    return _executeCommand<String>(
      command: Pop3Command(type: Pop3CommandType.retr),
      arg1: messageNumber.toString(),
    );
  }

  Future<String> rset() {
    return _executeCommand<String>(
      command: Pop3Command(type: Pop3CommandType.rset),
    );
  }

  Future<String> stat() {
    return _executeCommand<String>(
      command: Pop3Command(type: Pop3CommandType.stat),
    );
  }

  Future<void> top({
    required int messageNumber,
    int? lines,
  }) {
    return _executeCommand<String>(
      command: Pop3Command(type: Pop3CommandType.top),
      arg1: messageNumber.toString(),
      arg2: lines?.toString(),
    );
  }

  Future<String> uidl({
    int? messageNumber,
  }) {
    return _executeCommand<String>(
      command: Pop3Command(type: Pop3CommandType.uidl),
      arg1: messageNumber?.toString(),
    );
  }

  Future<void> disconnect() async {
    await _executeCommand<String>(
      command: Pop3Command(type: Pop3CommandType.quit),
    );
    await _socket.close();
  }

  Future<T> _executeCommand<T>({
    required Pop3Command<T> command,
    String? arg1,
    String? arg2,
  }) {
    _lastCommand = command;
    if (arg1 != null && arg2 != null) {
      _socket.add(utf8.encode('${command.type} $arg1 $arg2\r\n'));
    } else if (arg1 != null) {
      _socket.add(utf8.encode('${command.type} $arg1\r\n'));
    } else if (arg2 != null) {
      _socket.add(utf8.encode('${command.type} $arg2\r\n'));
    } else {
      _socket.add(utf8.encode('${command.type}\r\n'));
    }
    return command.completer.future;
  }
}
