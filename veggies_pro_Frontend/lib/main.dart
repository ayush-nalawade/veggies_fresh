import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'core/dio_client.dart';

void main() {
  DioClient().init();
  runApp(const ProviderScope(child: VeggieFreshApp()));
}

class VeggieFreshApp extends StatelessWidget {
  const VeggieFreshApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'VeggieFresh',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}