library filelogger;

import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ssh2/ssh2.dart';

class FileLogger {
  static final FileLogger instance = FileLogger._privateConstructor();

  FileLogger._privateConstructor();

  String _privateKey = '';
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

  Future<void> log(String tag, String message) async {
    final file = await _localFile;

    String time = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    String content = '$time  $tag  $message\n';
    await file.writeAsString(content, mode: FileMode.append);
  }

  Future<bool?> sendLog(String account, String ftpAddress, int port,
      String destPath, String destFileName,
      {bool clearLogs = true}) async {
    var path = await _localPath;
    var logFile = File('$path/$_logFileName');

//    String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    var sendFile = await logFile.copy('$path/$destFileName');

    var client = new SSHClient(
      host: ftpAddress,
      port: port,
      username: account,
      passwordOrKey: {
        'privateKey': _privateKey,
      },
    );

    try {
      String? result = await client.connect();
      // print(result);
      if (result == 'session_connected') {
        String? result = await client.connectSFTP();
        // print(result);
        if (result == 'sftp_connected') {
          String? result =
              await client.sftpUpload(path: sendFile.path, toPath: destPath);
          print(result);
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
    } catch (e) {
      // print('Error: ${e.code}\nError Message: ${e.message}');
      return false;
    }
  }
}
