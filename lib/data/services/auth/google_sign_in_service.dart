import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInService {
  final GoogleSignIn _client = GoogleSignIn(
    clientId:
        '756576765751-h5uipv1aos427pmee1hf85t2kms90n04.apps.googleusercontent.com',
    scopes: ['email'],
  );

  /// Returns the Google ID token, or null if the user cancelled.
  Future<String?> signIn() async {
    final account = await _client.signIn();
    if (account == null) return null;
    final auth = await account.authentication;
    return auth.idToken;
  }

  Future<void> signOut() => _client.signOut();
}
