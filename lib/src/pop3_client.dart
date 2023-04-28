import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:pop3/src/pop3_command.dart';
import 'package:pop3/src/pop3_exception.dart';
import 'package:rxdart/subjects.dart';

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
  late final Socket _socket;
  // ignore: strict_raw_type
  Pop3Command? _lastCommand;
  final _stringBuilder = StringBuffer();
  final stream = BehaviorSubject<Pop3Response>();

  Future<bool> connect({
    required String user,
    required String password,
    bool secure = true,
    Socket? socket,
  }) async {
    final completer = Completer<bool>();
    try {
      _socket = socket ??
          (secure
              ? await SecureSocket.connect(host, port)
              : await Socket.connect(host, port));
      _socket.listen(
        (rawData) {
          final data = utf8.decode(rawData);
          final response = Pop3Response(
            data: data,
            command: _lastCommand,
          );

          stream.add(response);

          if (rawData.last == LF && rawData[rawData.length - 2] == CR) {
            _stringBuilder.write(data);
            _lastCommand?.completer.complete(_stringBuilder.toString());
            _stringBuilder.clear();
          } else {
            _stringBuilder.write(data);
          }

          if (showLogs) {
            log('${DateTime.now().toIso8601String()}: ${response.data}');
          }

          if (_lastCommand == null && response.isGreeting) {
            _executeCommand<String>(
              command: Pop3Command(type: Pop3CommandType.user),
              arg1: user,
            );
            return;
          }

          if (_lastCommand?.type == Pop3CommandType.user &&
              response.isSuccess) {
            _executeCommand<String>(
              command: Pop3Command(type: Pop3CommandType.pass),
              arg1: password,
            );
            return;
          }

          if (_lastCommand?.type == Pop3CommandType.pass &&
              response.isSuccess) {
            completer.complete(true);
          }
        },
      );
    } catch (e) {
      await _socket.close();
      throw Pop3Expetion();
    }

    return completer.future;
  }

  Future<Pop3Response> apop({
    required String user,
    required String pass,
  }) async {
    final responseStr = await _executeCommand<String>(
      command: Pop3Command(type: Pop3CommandType.apop),
      arg1: user,
      arg2: pass,
    );
    return Pop3Response(
      data: responseStr,
      command: _lastCommand,
    );
  }

  Future<Pop3Response> dele({
    required int messageNumber,
  }) async {
    final responseStr = await _executeCommand<String>(
      command: Pop3Command(type: Pop3CommandType.dele),
      arg1: messageNumber.toString(),
    );

    return Pop3Response(
      data: responseStr,
      command: _lastCommand,
    );
  }

  Future<Pop3ListResponse> list({
    int? messageNumber,
  }) async {
    final responseStr = await _executeCommand<String>(
      command: Pop3Command(type: Pop3CommandType.list),
      arg1: messageNumber?.toString(),
    );

    return Pop3ListResponse(
      data: responseStr,
      command: _lastCommand,
    );
  }

  Future<Pop3Response> noop() async {
    final responseStr = await _executeCommand<String>(
      command: Pop3Command(type: Pop3CommandType.noop),
    );
    return Pop3Response(
      data: responseStr,
      command: _lastCommand,
    );
  }

  Future<Pop3Response> quit() async {
    final responseStr = await _executeCommand<String>(
      command: Pop3Command(type: Pop3CommandType.quit),
    );

    return Pop3Response(
      data: responseStr,
      command: _lastCommand,
    );
  }

  Future<Pop3Response> retr({
    required int messageNumber,
  }) async {
    final responseStr = await _executeCommand<String>(
      command: Pop3Command(type: Pop3CommandType.retr),
      arg1: messageNumber.toString(),
    );

    return Pop3Response(
      data: responseStr,
      command: _lastCommand,
    );
  }

  Future<Pop3Response> rset() async {
    final responseStr = await _executeCommand<String>(
      command: Pop3Command(type: Pop3CommandType.rset),
    );

    return Pop3Response(
      data: responseStr,
      command: _lastCommand,
    );
  }

  Future<Pop3Response> stat() async {
    final responseStr = await _executeCommand<String>(
      command: Pop3Command(type: Pop3CommandType.stat),
    );

    return Pop3Response(
      data: responseStr,
      command: _lastCommand,
    );
  }

  Future<Pop3Response> top({
    required int messageNumber,
    int? lines,
  }) async {
    final responseStr = await _executeCommand<String>(
      command: Pop3Command(type: Pop3CommandType.top),
      arg1: messageNumber.toString(),
      arg2: lines?.toString(),
    );

    return Pop3Response(
      data: responseStr,
      command: _lastCommand,
    );
  }

  Future<Pop3Response> uidl({
    int? messageNumber,
  }) async {
    final responseStr = await _executeCommand<String>(
      command: Pop3Command(type: Pop3CommandType.uidl),
      arg1: messageNumber?.toString(),
    );

    return Pop3Response(
      data: responseStr,
      command: _lastCommand,
    );
  }

  Future<void> disconnect() async {
    await _executeCommand<String>(
      command: Pop3Command(type: Pop3CommandType.quit),
    );
    await _socket.close();
    await stream.close();
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
