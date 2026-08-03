import 'package:flutter/material.dart';

import '../features/room/presentation/room_page.dart';

class AmeTsuzuriApp extends StatelessWidget {
  const AmeTsuzuriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '雨つづり。',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const RoomPage(),
    );
  }
}