import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

class StorageService {
  StorageService();
  Directory? _docDir;
  // ignore: unused_field
  final _log = Logger("StorageService");

  Future get _docPath async {
    _docDir ??= await getApplicationDocumentsDirectory();
    return _docDir!.path;
  }

  Future<File?> getFile(int? channelId, String? fname) async {
    if (channelId != null && fname != null) {
      return File("${await _docPath}/$channelId/$fname");
    }
    return null;
  }

  Future<bool> deleteFile(int channelId, String fname) async {
    try {
      final file = File("${await _docPath}/$channelId/$fname");
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
      final dir = Directory("${await _docPath}/$channelId");
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
