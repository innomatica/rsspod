import 'dart:io';

import 'package:logging/logging.dart';

import '../../../util/constants.dart' show appDocPath;

class StorageService {
  StorageService();

  // ignore: unused_field
  final _log = Logger("StorageService");

  Future<File?> getFile(int? channelId, String? fname) async {
    if (channelId != null && fname != null) {
      return File("$appDocPath/$channelId/$fname");
    }
    return null;
  }

  Future<bool> deleteFile(int channelId, String fname) async {
    try {
      final file = File("$appDocPath/$channelId/$fname");
      if (file.existsSync()) {
        await file.delete();
        return true;
      }
    } on Exception {
      rethrow;
    }
    return false;
  }

  Future<bool> deleteDirectory(int channelId) async {
    try {
      final dir = Directory("$appDocPath/$channelId");
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
        return true;
      }
    } on Exception {
      rethrow;
    }
    return false;
  }
}
