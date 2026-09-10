import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/pdf_service.dart';
import 'services/storage_service.dart';
import 'state/reports_provider.dart';
import 'state/settings_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = StorageService();

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        Provider<PdfService>(create: (_) => PdfService(storage)),
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(storage),
        ),
        ChangeNotifierProvider<ReportsProvider>(
          create: (_) => ReportsProvider(storage),
        ),
      ],
      child: const RapportInterventionApp(),
    ),
  );
}
