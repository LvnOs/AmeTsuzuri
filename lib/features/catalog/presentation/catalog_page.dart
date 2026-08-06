import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shizuku/provider/shizuku_provider.dart';

class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final int currentShizuku = context.watch<ShizukuProvider>().currentShizuku;
    return Scaffold(
      appBar: AppBar(title: const Text('目録')),
      body: Center(child: Text('ここで家具を選びます.雫${currentShizuku}')),
    );
  }
}
