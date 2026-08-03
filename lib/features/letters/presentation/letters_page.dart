import 'package:flutter/material.dart';

class LettersPage extends StatelessWidget {
  const LettersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('手紙')),
      body: const Center(child: Text('ここで手紙を読みます')),
    );
  }
}
