import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService with ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  GoogleSignInAccount? _currentUser;
  String? _accessToken;
  bool _isInitialized = false;
  String? _initializationError;

  GoogleSignInAccount? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  bool get isInitialized => _isInitialized;
  String? get initializationError => _initializationError;

  AuthService() {
    _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      // Skip initialization on unsupported platforms (Linux, Windows)
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.linux ||
              defaultTargetPlatform == TargetPlatform.windows)) {
        _initializationError = 'Google Sign-In not supported on Linux/Windows';
        if (kDebugMode) {
          print(_initializationError);
        }
        return;
      }

      // In v7.x, we must call initialize() before any other operations
      final signIn = GoogleSignIn.instance;

      // Initialize with serverClientId=null to use auto-detection from google-services.json
      await signIn.initialize(serverClientId: null);

      _isInitialized = true;
      _initializationError = null;

      // Listen to authentication events
      signIn.authenticationEvents.listen((event) {
        if (kDebugMode) {
          print('🔔 Auth event received: $event');
        }
        switch (event) {
          case GoogleSignInAuthenticationEventSignIn(:final user):
            if (kDebugMode) {
              print('✅ User signed in: ${user.email}');
            }
            _currentUser = user;
            _updateToken();
            notifyListeners();
          case GoogleSignInAuthenticationEventSignOut():
            if (kDebugMode) {
              print('🚪 User signed out');
            }
            _currentUser = null;
            _accessToken = null;
            notifyListeners();
        }
      });

      // Attempt lightweight authentication (silent sign-in)
      try {
        await signIn.attemptLightweightAuthentication();
      } catch (error) {
        if (kDebugMode) {
          print('ℹ️ Lightweight auth skipped: $error');
        }
      }
    } catch (error) {
      _initializationError = error.toString();
      if (kDebugMode) {
        print('Google Sign-In initialization failed: $error');
      }
      _isInitialized = false;
    }
  }

  Future<void> _updateToken() async {
    if (_currentUser == null) return;

    try {
      // In google_sign_in 7.x, authentication is a getter, not a Future
      final auth = _currentUser!.authentication;
      _accessToken = auth.idToken;

      if (_accessToken != null) {
        await _storage.write(key: 'access_token', value: _accessToken);
        if (kDebugMode) {
          print('✅ ID Token saved: ${_accessToken?.substring(0, 20)}...');
        }
      } else {
        if (kDebugMode) {
          print('⚠️ ID Token is null');
        }
      }
    } catch (error) {
      if (kDebugMode) {
        print('Failed to update token: $error');
      }
    }
  }

  Future<void> signIn() async {
    if (!_isInitialized) {
      if (kDebugMode) {
        print('❌ GoogleSignIn not initialized');
      }
      return;
    }

    try {
      if (kDebugMode) {
        print('🔑 Starting sign-in process...');
      }

      final signIn = GoogleSignIn.instance;
      if (signIn.supportsAuthenticate()) {
        await signIn.authenticate();
      } else {
        // Fallback or web specific handling
        if (kDebugMode) {
          print(
            'Platform does not support authenticate(), check implementation',
          );
        }
      }
    } catch (error) {
      if (kDebugMode) {
        print('❌ Sign in failed: $error');
      }
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.disconnect();
      await _storage.delete(key: 'access_token');
      _accessToken = null;
      _currentUser = null;
      notifyListeners();
    } catch (error) {
      if (kDebugMode) {
        print('Sign out failed: $error');
      }
    }
  }
}
