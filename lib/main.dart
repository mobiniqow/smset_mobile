import 'package:flutter/material.dart';
import 'package:smset/page/splash.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // صفحه اولیه را به صفحه اسپلش تغییر می‌دهیم
      home: SplashScreen(), // صفحه اسپلش به عنوان صفحه ورودی
    );
  }
}
