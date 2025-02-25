// Copyright (c)  2024  Xiaomi Corporation
import "dart:io";

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:easy_speech_recognition/download_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'widgets/download_progress_dialog.dart';

// Copy the asset file from src to dst
Future<String> copyAssetFile(String src, [String? dst]) async {
  final Directory directory = await getApplicationDocumentsDirectory();
  if (dst == null) {
    dst = basename(src);
  }
  final target = join(directory.path, dst);
  bool exists = await new File(target).exists();

  final data = await rootBundle.load(src);

  if (!exists || File(target).lengthSync() != data.lengthInBytes) {
    final List<int> bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await File(target).writeAsBytes(bytes);
  }

  return target;
}

Float32List convertBytesToFloat32(Uint8List bytes, [endian = Endian.little]) {
  final values = Float32List(bytes.length ~/ 2);

  final data = ByteData.view(bytes.buffer);

  for (var i = 0; i < bytes.length; i += 2) {
    int short = data.getInt16(i, endian);
    values[i ~/ 2] = short / 32678.0;
  }

  return values;
}

// 提供模型名称，进行下载
Future<void> downloadModelAndUnZip(
    BuildContext context, String modelName) async {
    final downLoadUrl = "http://172.16.227.131:8000/$modelName.tar.bz2";
  // final downLoadUrl =
  //     'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/$modelName.tar.bz2';
  final downloadModel = Provider.of<DownloadModel>(context, listen: false);
  // 获取本地存储目录
  final Directory directory = await getApplicationDocumentsDirectory();
  final modulePath = join(directory.path, modelName);
  bool moduleExists = await Directory(modulePath).exists();
  final moduleZipFilePath = join(directory.path, '$modelName.tar.bz2');
  bool moduleZipExists = await File(moduleZipFilePath).exists();
  // 模型文件目录存在时直接成功
  if (moduleExists) {
    return;
  }

  // 模型压缩文件和模型目录都不存在时 下载并解压
  if (!moduleExists && !moduleZipExists) {
    bool confirmed = await _showDownloadConfirmationDialog(context);
    if (!confirmed) {
      return;
    }
    // Show the progress dialog before starting the download
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return DownloadProgressDialog();
      },
    );

    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(downLoadUrl));
      final response = await client.send(request);

      int totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;

      // Create file for writing
      final file = File(moduleZipFilePath);
      final sink = file.openWrite();

      await response.stream.forEach((List<int> chunk) {
        // Write chunk directly to file
        sink.add(chunk);
        receivedBytes += chunk.length;
        double progress = totalBytes > 0 ? receivedBytes / totalBytes : 0;
        downloadModel.setProgress(progress);
      });

      // Close the file
      await sink.flush();
      await sink.close();

      // Unzip the downloaded file
      _unzipDownloadedFile(moduleZipFilePath, directory.path, context);
    } catch (e) {
      // Close the dialog if there's an error
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Show error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Download Failed'),
            content: Text('Failed to download the model: ${e.toString()}'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );

      // Clean up partial download if it exists
      final partialFile = File(moduleZipFilePath);
      if (await partialFile.exists()) {
        await partialFile.delete();
      }
    }
  }
}

Future<bool> _showDownloadConfirmationDialog(BuildContext context) async {
  final downloadModel = Provider.of<DownloadModel>(context, listen: false);
  final modelName = downloadModel.modelName;
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Download Required'),
            content: Text(
                'The speech recognition model(${modelName}) is not available locally. Do you want to download it?'),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: Text('Download'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        },
      ) ??
      false;
}

Future<void> unzipModelFile(BuildContext context, String modelName) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return DownloadProgressDialog();
    },
  );
  final Directory directory = await getApplicationDocumentsDirectory();
  final moduleZipFilePath = join(directory.path, '$modelName.tar.bz2');
  final downloadModel = Provider.of<DownloadModel>(context, listen: false);
  try{
    await _unzipDownloadedFile(moduleZipFilePath, directory.path, context);
  }catch(e){
    downloadModel.setUnzipProgress(0.0);
    Navigator.of(context).pop();
     // 解压失败，删除下载的文件
    if (await File(moduleZipFilePath).exists()) {
      await File(moduleZipFilePath).delete();
    }
    //重新下载，解压
    downloadModelAndUnZip(context, modelName);
  }
}

Future<bool> needsDownload(String modelName) async {
  final Directory directory = await getApplicationDocumentsDirectory();
  final modulePath = join(directory.path, modelName);
  bool moduleExists = await Directory(modulePath).exists();
  final moduleZipFilePath = join(directory.path, '$modelName.tar.bz2');
  bool moduleZipExists = await File(moduleZipFilePath).exists();
  print('needsDownload:moduleExists: $moduleExists');
  print('needsDownload:moduleZipExists: $moduleZipExists');
  return !moduleExists && !moduleZipExists;
}

Future<bool> needsUnZip(String modelName) async {
  final Directory directory = await getApplicationDocumentsDirectory();
  final modulePath = join(directory.path, modelName);
  bool moduleExists = await Directory(modulePath).exists();
  final moduleZipFilePath = join(directory.path, '$modelName.tar.bz2');
  bool moduleZipExists = await File(moduleZipFilePath).exists();
  return moduleZipExists && !moduleExists;
}

void _showSuccessDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Success'),
        content:
            Text('The model has been downloaded and extracted successfully.'),
        actions: <Widget>[
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

// Data class to pass to isolate
class UnzipParams {
  final String zipFilePath;
  final String destinationPath;

  UnzipParams(this.zipFilePath, this.destinationPath);
}

// Function to run in isolate for decompression
Future<List<dynamic>> _decompressInIsolate(UnzipParams params) async {
  final bytes = File(params.zipFilePath).readAsBytesSync();

  // First decode the bzip2 compressed data
  final archive = BZip2Decoder().decodeBytes(bytes);

  // Then decode the tar archive
  final tarArchive = TarDecoder().decodeBytes(archive);

  return [archive, tarArchive.files];
}

// Function to extract a single file in isolate
Future<void> _extractFileInIsolate(Map<String, dynamic> params) async {
  final file = params['file'] as ArchiveFile;
  final destinationPath = params['destinationPath'] as String;
  final filename = file.name;

  if (file.isFile) {
    final data = file.content as List<int>;
    File(join(destinationPath, filename))
      ..createSync(recursive: true)
      ..writeAsBytesSync(data);
  } else {
    Directory(join(destinationPath, filename)).create(recursive: true);
  }
}

Future<void> _unzipDownloadedFile(
    String zipFilePath, String destinationPath, BuildContext context) async {

  final downloadModel = Provider.of<DownloadModel>(context, listen: false);
    downloadModel.setUnzipProgress(0.1);

  // Use compute to run decompression in a separate isolate
  final result = await compute(
      _decompressInIsolate, UnzipParams(zipFilePath, destinationPath));

  downloadModel.setUnzipProgress(0.4);

  final files = result[1] as List<ArchiveFile>;
  final totalFiles = files.length;
  int processedFiles = 0;

  // Process files in smaller batches to allow UI updates
  for (final file in files) {
    // Use compute to extract each file in a separate isolate
    await compute(_extractFileInIsolate,
        {'file': file, 'destinationPath': destinationPath});

    processedFiles++;
    double progress = 0.4 + (0.6 * processedFiles / totalFiles);
    // Add a small delay to allow UI updates
    if (processedFiles % 10 == 0) {
      await Future.delayed(Duration(milliseconds: 1));
    }

    downloadModel.setUnzipProgress(progress);
  }

  if (Navigator.canPop(context)) {
    Navigator.of(context).pop();
    _showSuccessDialog(context);
  }
}
