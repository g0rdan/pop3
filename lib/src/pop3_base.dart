import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';

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
  final _responseStream = BehaviorSubject<Pop3Response>();
  Pop3Commands? _lastCommand;

  Stream<Pop3Response> get responseStream => _responseStream.stream;

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
            lastCommand: _lastCommand,
          );
          _responseStream.add(response);
          if (showLogs) {
            log('${DateTime.now().toIso8601String()}: ${response.data}');
          }
          if (_lastCommand == null && response.greeting) {
            _executeCommand(command: Pop3Commands.user, arg1: user);
            return;
          }
          if (_lastCommand == Pop3Commands.user && response.success) {
            _executeCommand(command: Pop3Commands.pass, arg1: password);
            return;
          }
          if (_lastCommand == Pop3Commands.pass && response.success) {
            completer.complete(true);
          }
        },
      );
    } catch (e) {
      completer.complete(false);
    }

    return completer.future;
  }

  void apop({
    required String user,
    required String pass,
  }) {
    _executeCommand(
      command: Pop3Commands.apop,
      arg1: user,
      arg2: pass,
    );
  }

  void dele({
    required int messageNumber,
  }) {
    _executeCommand(
      command: Pop3Commands.dele,
      arg1: messageNumber.toString(),
    );
  }

  void list({
    int? messageNumber,
  }) {
    _executeCommand(
      command: Pop3Commands.list,
      arg1: messageNumber?.toString(),
    );
  }

  void noop() {
    _executeCommand(
      command: Pop3Commands.noop,
    );
  }

  void quit() {
    _executeCommand(
      command: Pop3Commands.quit,
    );
  }

  void retr({
    required int messageNumber,
  }) {
    _executeCommand(
      command: Pop3Commands.retr,
      arg1: messageNumber.toString(),
    );
  }

  void rset() {
    _executeCommand(
      command: Pop3Commands.rset,
    );
  }

  void stat() {
    _executeCommand(
      command: Pop3Commands.stat,
    );
  }

  void top({
    required int messageNumber,
    int? lines,
  }) {
    _executeCommand(
      command: Pop3Commands.top,
      arg1: messageNumber.toString(),
      arg2: lines?.toString(),
    );
  }

  void uidl({
    int? messageNumber,
  }) {
    _executeCommand(
      command: Pop3Commands.uidl,
      arg1: messageNumber?.toString(),
    );
  }

  Future<void> disconnect() async {
    _executeCommand(command: Pop3Commands.quit);
    await _socket.close();
    await _responseStream.close();
  }

  void _executeCommand({
    required Pop3Commands command,
    String? arg1,
    String? arg2,
  }) {
    _lastCommand = command;
    if (arg1 != null && arg2 != null) {
      _socket.add(utf8.encode('${command.command} $arg1 $arg2\r\n'));
    } else if (arg1 != null) {
      _socket.add(utf8.encode('${command.command} $arg1\r\n'));
    } else if (arg2 != null) {
      _socket.add(utf8.encode('${command.command} $arg2\r\n'));
    } else {
      _socket.add(utf8.encode('${command.command}\r\n'));
    }
  }
}
