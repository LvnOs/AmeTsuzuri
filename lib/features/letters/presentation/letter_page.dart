import 'package:flutter/material.dart';
import '../model/letter.dart';

class LetterPage extends StatelessWidget {
  const LetterPage({super.key, required this.letter});
  final Letter letter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EDE1),
      appBar: AppBar(
        title: const Text('今日の手紙'),
        backgroundColor: const Color(0xFFF3EDE1),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                letter.title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 32),
              Text(letter.body, style: TextStyle(fontSize: 18, height: 1.9)),
            ],
          ),
        ),
      ),
    );
  }
}
