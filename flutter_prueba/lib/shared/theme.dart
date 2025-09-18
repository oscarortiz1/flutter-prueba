import 'package:flutter/material.dart';

final Color seed = Colors.indigo;

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
  scaffoldBackgroundColor: Colors.white,
  inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.grey[100]),
 );

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
  scaffoldBackgroundColor: Colors.transparent,
  inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white10),
);
