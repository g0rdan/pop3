import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';

part 'pop3_model.dart';

class Pop3Client {
  final String host;
  final int port;
  final bool showLogs;

  late final SecureSocket _socket;
  final _responseStream = BehaviorSubject<Pop3Response>();
  Pop3Commands? _lastCommand;

  Stream<Pop3Response> get responseStream => _responseStream.stream;

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
      _socket.listen((rawData) {
        final data = utf8.decode(rawData);
        final response = Pop3Response(
          data: data,
          lastCommand: _lastCommand,
        );
        _responseStream.add(response);
        if (showLogs) {
          print("${DateTime.now().toIso8601String()}: ${response.data}");
        }
        if (_lastCommand == Pop3Commands.user && response.success) {
          _executeCommand(command: Pop3Commands.pass, arg1: password);
        }
        if (_lastCommand == Pop3Commands.pass && response.success) {
          completer.complete(true);
        }
      });
      _executeCommand(command: Pop3Commands.user, arg1: user);
    } catch (e) {
      completer.complete(false);
    }

    return completer.future;
  }

  void noop() {
    _executeCommand(command: Pop3Commands.noop);
  }

  void load([String? index]) {
    _executeCommand(command: Pop3Commands.list, arg1: index);
  }

  void show(int index) {
    _executeCommand(command: Pop3Commands.retr, arg1: '$index');
  }

  Future<void> disconnect() async {
    _executeCommand(command: Pop3Commands.quit);
    await _socket.close();
    await _responseStream.close();
  }

  _executeCommand({
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
