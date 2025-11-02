import 'package:flutter/cupertino.dart';
import 'package:gymboss/ui/core/ui/button/option_button.dart';
import 'package:gymboss/ui/core/ui/icons/icons_options_menu.dart';
import 'package:gymboss/ui/menu_options_list/exercises/widgets/exerices.dart';
import 'package:gymboss/ui/menu_options_list/program/widgets/program.dart';
import 'package:gymboss/ui/menu_options_list/settings/widgets/settings.dart';
import 'package:gymboss/ui/menu_options_list/statistics/widgets/statistics.dart';
import 'package:gymboss/ui/menu_options_list/training/widgets/training.dart';

class MenuOptions extends StatelessWidget {
  const MenuOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      // navigationBar: const CupertinoNavigationBar(middle: Text("GymBoss")),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "Gym | Control",
                  style: TextStyle(fontSize: 35, color: CupertinoColors.black),
                ),
                const SizedBox(height: 35),

                const Text(
                  "Your fitness companion",
                  style: TextStyle(fontSize: 25, color: CupertinoColors.black),
                ),
                const SizedBox(height: 20),

                OptionButtonMenu(
                  title: "Current strick",
                  borderColor: Color.fromRGBO(99, 32, 36, 1),
                  subtitle: "8 days",
                  icon: Image.asset(
                    IconsOptionsMenu.fire,
                    width: 24,
                    height: 24,
                  ),
                  backgroundColor: Color.fromRGBO(99, 32, 36, 1),
                  callBack: () {},
                ),
                const SizedBox(height: 70),
                OptionButtonMenu(
                  title: "Start training",
                  subtitle: "Begin your workout",
                  borderColor: Color(0xFF0D1F2D),
                  icon: Image.asset(
                    IconsOptionsMenu.play,
                    width: 24,
                    height: 24,
                  ),
                  backgroundColor: Color(0xFF0D1F2D),
                  callBack: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (context) => const Training(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                OptionButtonMenu(
                  title: "My Program",
                  borderColor: Color(0xFF0D1F2D),
                  subtitle: "View routines",
                  icon: Image.asset(
                    IconsOptionsMenu.calender,
                    width: 24,
                    height: 24,
                  ),
                  backgroundColor: Color(0xFF0D1F2D),
                  callBack: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (context) => const Program(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                OptionButtonMenu(
                  title: "Statistics",
                  subtitle: "Track progress",
                  borderColor: Color(0xFF0D1F2D),
                  icon: Image.asset(
                    IconsOptionsMenu.statictics,
                    width: 24,
                    height: 24,
                  ),
                  backgroundColor: Color(0xFF0D1F2D),
                  callBack: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (context) => const Statistics(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),
                OptionButtonMenu(
                  title: "Exercises",
                  subtitle: "Browse library",
                  borderColor: Color(0xFF0D1F2D),
                  icon: Image.asset(
                    IconsOptionsMenu.barbell,
                    width: 24,
                    height: 24,
                  ),
                  backgroundColor: Color(0xFF0D1F2D),
                  callBack: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (context) => const Exercises(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),
                OptionButtonMenu(
                  title: "Settings",
                  subtitle: "Customize app or profile",
                  borderColor: Color(0xFF0D1F2D),
                  icon: Image.asset(
                    IconsOptionsMenu.gear,
                    width: 24,
                    height: 24,
                  ),
                  backgroundColor: Color(0xFF0D1F2D),
                  callBack: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (context) => const Settings(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
