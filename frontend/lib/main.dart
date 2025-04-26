import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_messaging_handler.dart';
import 'screens/login_screen.dart';
import 'services/application_state.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();
  await FirebaseMessagingHandler.initialize();

  print("✅ APP START");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final ApplicationState applicationState = ApplicationState();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ApplicationState>.value(
      value: applicationState,
      child: Consumer<ApplicationState>(
        builder: (context, appState, _) {
          return MaterialApp(
            title: 'FCM + Google Auth App',
            theme: appState.isDarkMode
                ? ThemeData.dark()
                : ThemeData.light(),
            home: LoginScreen(),
          );
        },
      ),
    );
  }
}
