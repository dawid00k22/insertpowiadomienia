import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  final _googleSignIn = GoogleSignIn(
    serverClientId: dotenv.env['GOOGLE_CLIENT_ID'],
  );

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
        return account?.email;
      } else {
        print("❌ Logowanie odrzucone przez backend: ${response.statusCode}");
        await _googleSignIn.signOut(); // reset konta
        return null;
      }
    } catch (e) {
      print("❌ Błąd logowania: $e");
      await _googleSignIn.signOut(); // reset przy błędzie
      return null;
    }
  }
}
