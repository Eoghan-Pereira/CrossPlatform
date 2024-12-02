import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'login_screen.dart';
import 'home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Back4App
  final keyApplicationId = '2R4r8Fp4piBxcLfcgcaVS6Md6wzjJ9kE5XMy81z8';
  final keyClientKey = 'mFh95wjIapYOpxnRKpHfEbH6Q15lQkkZdWbh3zn0';
  final keyParseServerUrl = 'https://parseapi.back4app.com';

  await Parse().initialize(
    keyApplicationId,
    keyParseServerUrl,
    clientKey: keyClientKey,
    debug: true,
  );

  runApp(const QuickTaskApp());
}

class QuickTaskApp extends StatelessWidget {
  const QuickTaskApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickTask',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}