// lib/main.dart - 超级简化版本

import 'package:flutter/material.dart';

void main() {
  print('🚀 Ultra minimal app starting...');
  runApp(UltraMinimalApp());
}

class UltraMinimalApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Test App'),
        ),
        body: Center(
          child: Text(
            'Hello World!\nApp is running!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}
