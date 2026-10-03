import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'database/app_database.dart';
import 'struct/document_struct.dart';
import 'struct/category_struct.dart';
import 'struct/search_struct.dart';
import 'pages/home_page.dart';

/// Entry point của ứng dụng StudyDocs
/// Khởi tạo Database → Struct → Provider → UI
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Tạo instance DB duy nhất (singleton trong scope app)
  final database = AppDatabase();

  runApp(StudyDocsApp(database: database));
}

/// Root widget - cung cấp các struct (business logic) qua Provider
class StudyDocsApp extends StatelessWidget {
  final AppDatabase database;

  const StudyDocsApp({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    // MultiProvider: inject các struct cho toàn bộ widget tree
    return MultiProvider(
      providers: [
        // Cung cấp struct, KHÔNG cung cấp DB trực tiếp cho UI
        Provider<DocumentStruct>(create: (_) => DocumentStruct(database)),
        Provider<CategoryStruct>(create: (_) => CategoryStruct(database)),
        Provider<SearchStruct>(create: (_) => SearchStruct(database)),
      ],
      child: MaterialApp(
        title: 'StudyDocs',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
          brightness: Brightness.dark,
        ),
        themeMode: ThemeMode.system,
        home: const HomePage(),
      ),
    );
  }
}
