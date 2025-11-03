import 'package:flutter/cupertino.dart';
import 'package:gymboss/ui/core/themes/light_theme.dart';
import 'package:gymboss/ui/home_screen/home_screen.dart';

const app = CupertinoApp(
  theme: lightTheme,
  debugShowCheckedModeBanner: false,
  home: HomeScreen(),
);
