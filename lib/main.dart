import 'package:flutter/cupertino.dart';
import 'package:gymboss/ui/home_screen/home_screen.dart';

void main() {
  runApp(const MyCupertinoApp());
}

class MyCupertinoApp extends StatelessWidget {
  const MyCupertinoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      theme: CupertinoThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Color(0xFF9EA3B0),
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(fontFamily: 'Rubik'),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}
