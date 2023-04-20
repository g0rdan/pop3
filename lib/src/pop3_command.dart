import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:pop3/src/pop3_client.dart';

class Pop3Command<T> extends Equatable {
  Pop3Command({
    required this.type,
  });

  final Pop3CommandType type;
  final completer = Completer<T>();

  @override
  List<Object?> get props => [
        type,
      ];
}
