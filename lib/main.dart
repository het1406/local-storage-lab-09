import 'package:flutter/material.dart';

import 'database_helper.dart';
import 'catalogue_repository.dart';
import 'catalogue_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final helper = DatabaseHelper();
  try {
    await helper.init();
    runApp(DirectoryApp(helper: helper));
  } catch (error) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Could not open local storage. Restart the app to try again.',
            ),
          ),
        ),
      ),
    );
  }
}

class DirectoryApp extends StatelessWidget {
  const DirectoryApp({super.key, required this.helper});
  final DatabaseHelper helper;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Card Catalogue',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff244a42)),
      useMaterial3: true,
    ),
    home: CatalogueScreen(
      helper: helper,
      repository: CatalogueRepository(helper.database),
    ),
  );
}
