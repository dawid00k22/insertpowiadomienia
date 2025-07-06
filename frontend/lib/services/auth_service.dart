import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  late final GoogleSignIn _googleSignIn;

  AuthService() {
    final clientId = Platform.isIOS
        ? dotenv.env['GOOGLE_CLIENT_ID_IOS']
        : dotenv.env['GOOGLE_CLIENT_ID_ANDROID'];

    _googleSignIn = GoogleSignIn(
      serverClientId: clientId,
      scopes: ['email'],
    );
  }

  Future<String?> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      final auth = await account?.authentication;
      final token = auth?.idToken;

      if (token == null) {
        print("❌ Brak tokena");
        return null;
      }

      final apiUrl = dotenv.env['API_URL'];
      final url = "$apiUrl/auth/google?token=$token";

      print("🌐 Wysyłam token do backendu: $url");
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        print("✅ Logowanie zakończone sukcesem: ${account?.email}");
        return account?.email;
      } else {
        print("❌ Logowanie odrzucone przez backend: ${response.statusCode}");
        await _googleSignIn.signOut(); // reset konta
        return null;
      }
    } catch (e) {
      print("❌ Błąd logowania: $e");
      await _googleSignIn.signOut();
      return null;
    }
  }
}
