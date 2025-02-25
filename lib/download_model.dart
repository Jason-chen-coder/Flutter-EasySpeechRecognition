import 'package:flutter/cupertino.dart';

class DownloadModel with ChangeNotifier {
  String _modelName =
      "sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20";
  String get modelName => _modelName;
  void setModelName(String value) {
    _modelName = value;
    notifyListeners();
  }

  double _progress = 0;
  double get progress => _progress;
  void setProgress(double value) {
    if (value >= 1.0) {
      _progress = 1;
    } else {
      _progress = value;
    }
    notifyListeners();
  }

  double _unzipProgress = 0;
  double get unzipProgress => _unzipProgress;
  void setUnzipProgress(double value) {
    if (value >= 1.0) {
      _unzipProgress = 1;
    } else {
      _unzipProgress = value;
    }
    notifyListeners();
  }
}
