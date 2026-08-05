import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/room/presentation/room_page.dart';
import '../features/letters/provider/read_letter_provider.dart';
import '../features/letters/repository/read_letter_repository.dart';

class AmeTsuzuriApp extends StatelessWidget {
  const AmeTsuzuriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReadLetterProvider(ReadLetterRepository())..load(),
      child: MaterialApp(
        title: '雨つづり。',
        debugShowCheckedModeBanner: false,
        home: const RoomPage(),
      ),
    );
  }
}
