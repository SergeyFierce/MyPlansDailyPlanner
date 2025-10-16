import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'state/task_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru_RU');
  final TaskController controller = await TaskController.create();
  runApp(MyApp(controller: controller));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.controller});

  final TaskController controller;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TaskController>.value(
      value: controller,
      child: MaterialApp(
        title: 'Мои планы — Ежедневник',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF5F6FA),
          textTheme: Typography.englishLike2021.apply(fontFamily: 'Roboto'),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
