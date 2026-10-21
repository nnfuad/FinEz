import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase;
  UserProfile? _currentProfile;
  bool _isLoading = false;

  AuthService(this._supabase) {
    _init();
  }

  UserProfile? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _supabase.auth.currentUser != null;
  User? get currentUser => _supabase.auth.currentUser;
  bool get isAdmin => _currentProfile?.isAdmin ?? false;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<void> _init() async {
    if (isAuthenticated) {
      await fetchCurrentProfile();
    }
  }

  Future<void> fetchCurrentProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _currentProfile = null;
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        _currentProfile = UserProfile.fromJson(data);
      } else {
        // If profile doesn't exist yet, insert a default member profile
        final defaultProfile = {
          'id': user.id,
          'role': 'MEMBER',
        };
        await _supabase.from('profiles').upsert(defaultProfile);
        _currentProfile = UserProfile(id: user.id, role: UserRole.member);
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      await fetchCurrentProfile();
      return res;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _currentProfile = null;
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email.trim());
  }
}
