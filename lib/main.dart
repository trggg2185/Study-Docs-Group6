import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'database/app_database.dart';
import 'firebase_options.dart';
import 'struct/document_struct.dart';
import 'struct/category_struct.dart';
import 'struct/search_struct.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'services/firebase/auth_service.dart';

/// Entry point của ứng dụng StudyDocs
/// Khởi tạo Firebase và Database trước khi hiển thị UI
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Tạo instance DB duy nhất (singleton trong scope app)
  final database = AppDatabase();

  runApp(StudyDocsApp(database: database, authService: AuthService()));
}

/// Root widget - cung cấp các struct (business logic) qua Provider
class StudyDocsApp extends StatelessWidget {
  final AppDatabase database;
  final AuthService authService;

  const StudyDocsApp({
    super.key,
    required this.database,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    // MultiProvider: inject các struct cho toàn bộ widget tree
    return MultiProvider(
      providers: [
        // Cung cấp struct, KHÔNG cung cấp DB trực tiếp cho UI
        Provider<DocumentStruct>(create: (_) => DocumentStruct(database)),
        Provider<CategoryStruct>(create: (_) => CategoryStruct(database)),
        Provider<SearchStruct>(create: (_) => SearchStruct(database)),
        Provider<AuthService>.value(value: authService),
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
        home: AuthGate(authService: authService),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                'Không thể kiểm tra trạng thái đăng nhập: ${snapshot.error}',
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data == null
            ? LoginPage(authService: authService)
            : const HomePage();
      },
    );
  }
}
