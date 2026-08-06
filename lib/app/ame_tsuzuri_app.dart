import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/room/presentation/room_page.dart';
import '../features/letters/provider/read_letter_provider.dart';
import '../features/letters/repository/read_letter_repository.dart';
import '../features/letters/provider/shizuku_provider.dart';
import '../features/letters/repository/shizuku_repository.dart';
import '../shared/provider/app_data_provider.dart';
import '../features/furniture/provider/catalog_provider.dart';
import '../features/furniture/repository/purchased_furniture_repository.dart';

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
        ChangeNotifierProvider(
          create: (_) =>
              CatalogProvider(PurchasedFurnitureRepository())..load(),
        ),
      ],
      child: MaterialApp(
        title: '雨つづり。',
        debugShowCheckedModeBanner: false,
        home: const RoomPage(),
      ),
    );
  }
}
