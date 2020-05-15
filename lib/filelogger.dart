library filelogger;

import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ssh/ssh.dart';

class FileLogger {

  static final FileLogger instance = FileLogger._privateConstructor();

  FileLogger._privateConstructor();

  String _privateKey;
  String _logFileName = 'file_logger.txt';
  String _toPath = '';

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_logFileName');
  }

  set privateKey(String key) {
    _privateKey = key;
  }

  void log(String tag, String message) async {
    final file = await _localFile;

    String time = DateTime.now().toUtc().toIso8601String();
    String content = '$time  $tag  $message\n';
    file.writeAsString(content, mode: FileMode.append);
  }

  Future<bool> sendLog(String account, String ftp_address, int port, String destPath, String destFileName, {bool clearLogs = true}) async {
    var path = await _localPath;
    var logFile = File('$path/$_logFileName');

//    String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    var sendFile = await logFile.copy('$path/$destFileName');

    var client = new SSHClient(
      host: ftp_address,
      port: port,
      username: account,
      passwordOrKey: {
        'privateKey': _privateKey,
      },
    );

    await client.connect();
    await client.connectSFTP();
    String result = await client.sftpUpload(path: sendFile.path, toPath: destPath);
    if (result == 'upload_success') {
      sendFile.delete();
      if (clearLogs) {
        logFile.writeAsString('');
      }
      return true;
    } else {
      sendFile.delete();
      return false;
    }
  }
}