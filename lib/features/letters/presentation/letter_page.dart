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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 600 ? 20.0 : 32.0;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 32,
              ),
              child: Center(
                child: ConstrainedBox(
                  key: const ValueKey('letterContent'),
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: SizedBox(
                    width: double.infinity,
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
                        const SizedBox(height: 32),
                        Text(
                          letter.body,
                          style: const TextStyle(fontSize: 18, height: 1.9),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
