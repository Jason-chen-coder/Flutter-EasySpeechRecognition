// Copyright (c)  2024  Xiaomi Corporation
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import './streaming_asr.dart';
import 'download_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider<DownloadModel>(
            create: (_) => DownloadModel(),
          )
        ],
        child: const MaterialApp(
          home: MyHomePage(),
        ));
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;
  final List<Widget> _tabs = [
    StreamingAsrScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Real-time speech recognition'),
      ),
      body: _tabs[_currentIndex],
    );
  }
}
