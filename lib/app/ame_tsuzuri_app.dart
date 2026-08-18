import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/room/presentation/room_page.dart';
import '../features/letters/provider/read_letter_provider.dart';
import '../features/letters/repository/read_letter_repository.dart';
import '../features/letters/provider/shizuku_provider.dart';
import '../features/letters/repository/shizuku_repository.dart';
import '../shared/provider/app_data_provider.dart';
import '../shared/provider/weather_provider.dart';
import '../shared/repository/app_date_repository.dart';
import '../shared/repository/weather_repository.dart';
import '../features/furniture/provider/catalog_provider.dart';
import '../features/furniture/repository/purchased_furniture_repository.dart';
import '../features/furniture/provider/placed_furniture_provider.dart';
import '../features/furniture/repository/placed_furniture_repository.dart';

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
        ChangeNotifierProvider(
          create: (_) => AppDateProvider(AppDateRepository())..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => WeatherProvider(WeatherRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              CatalogProvider(PurchasedFurnitureRepository())..load(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              PlacedFurnitureProvider(PlacedFurnitureRepository())..load(),
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
