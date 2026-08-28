import 'package:uuid/uuid.dart';

abstract class UuidGenerator {
  static const _uuid = Uuid();

  static String generate() {
    return _uuid.v4();
  }
}
