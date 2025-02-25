import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../download_model.dart';

class DownloadProgressDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Please wait patiently'),
      content: Consumer<DownloadModel>(
        builder: (context, downloadModel, child) {
          final progress = downloadModel.progress;
          final unzipProgress = downloadModel.unzipProgress;
           bool isdownloading = progress< 1.0&& progress > 0.0;
          bool isunzipping = unzipProgress < 1.0 && unzipProgress > 0.0;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(
                  value: isdownloading
                      ? downloadModel.progress
                      : downloadModel.unzipProgress),
              SizedBox(height: 20),
              Text("Please do not perform any operations during ${isdownloading ? 'downloading' : 'unzipping'}"),
              SizedBox(height: 20),
              Text(
                  '${((isdownloading ? downloadModel.progress : downloadModel.unzipProgress) * 100).toStringAsFixed(4)}%'),
            ],
          );
        },
      ),
      actions: <Widget>[
        Consumer<DownloadModel>(
          builder: (context, downloadModel, child) {
            final unzipProgress = downloadModel.unzipProgress;
            final progress = downloadModel.progress;
            bool isdownloading = progress< 1.0&& progress > 0.0;
            bool isunzipping = unzipProgress < 1.0 && unzipProgress > 0.0;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isdownloading && !isunzipping)
                  TextButton(
                    child: Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  )
                else ...[
                  TextButton(
                    onPressed: null,
                    child: Text(isdownloading ? 'Downloading' : 'Unzipping'),
                  ),
                  const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.blue), // 自定义颜色
                    ),
                  ),
                ]
              ],
            );
          },
        ),
      ],
    );
  }
}
