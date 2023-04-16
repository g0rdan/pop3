import 'dart:async';

import 'package:pop3/src/pop3_client.dart';

class Pop3Command<T> {
  Pop3Command({
    required this.type,
  });

  final Pop3CommandType type;
  final completer = Completer<T>();
}
