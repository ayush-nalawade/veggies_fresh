import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'core/dio_client.dart';

void main() {
  DioClient().init();
  runApp(const ProviderScope(child: VeggieFreshApp()));
}

class VeggieFreshApp extends ConsumerWidget {
  const VeggieFreshApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'VeggieFresh',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}