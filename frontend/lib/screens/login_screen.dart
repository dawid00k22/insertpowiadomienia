import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  String loginStatus = '';

  Future<void> handleSignIn() async {
    final email = await _authService.signInWithGoogle();

    if (email != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(email: email)),
      );
    } else {
      setState(() {
        loginStatus = 'Brak dostępu – email nie znajduje się w bazie';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Google Login')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                print("👆 Kliknięto przycisk logowania");
                handleSignIn();
              },
              child: Text('Zaloguj się przez Google'),
            ),

            SizedBox(height: 20),
            Text(loginStatus, style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
