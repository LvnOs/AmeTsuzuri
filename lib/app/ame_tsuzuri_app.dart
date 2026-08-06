import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/room/presentation/room_page.dart';
import '../features/letters/provider/read_letter_provider.dart';
import '../features/letters/repository/read_letter_repository.dart';
import '../features/shizuku/provider/shizuku_provider.dart';
import '../features/shizuku/repository/shizuku_repository.dart';
import '../shared/provider/app_data_provider.dart';

class AmeTsuzuriApp extends StatelessWidget {
  const AmeTsuzuriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ReadLetterProvider(ReadLetterRepository())..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => ShizukuProvider(ShizukuRepository())..load(),
        ),
        ChangeNotifierProvider(create: (_) => AppDateProvider()),
      ],
      child: MaterialApp(
        title: '雨つづり。',
        debugShowCheckedModeBanner: false,
        home: const RoomPage(),
      ),
    );
  }
}
