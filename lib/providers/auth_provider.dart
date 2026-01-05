import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../models/user.dart';
import '../config/constants.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _showLoginDialog = false;

  // Store registered users (in-memory for demo purposes)
  final List<User> _registeredUsers = [];

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isDriver => _user?.isDriver ?? false;
  bool get showLoginDialog => _showLoginDialog;
  bool _showGuestModal = false;
  bool get showGuestModal => _showGuestModal;

  void setShowLoginDialog(bool show) {
    _showLoginDialog = show;
    notifyListeners();
  }

  void setShowGuestModal(bool show) {
    _showGuestModal = show;
    notifyListeners();
  }

  /// Register a new user
  /// Returns null on success, error message on failure
  String? register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? address,
  }) {
    // Check if email already exists
    final existingUser = _registeredUsers.firstWhere(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
      orElse: () => User(
        id: '',
        name: '',
        email: '',
        phone: '',
        address: '',
        orders: 0,
        favorites: 0,
        isAdmin: false,
        isDriver: false,
      ),
    );

    if (existingUser.email.isNotEmpty) {
      return 'Email is already in use';
    }

    // Check against special accounts
    if (email.toLowerCase() == AppConstants.adminEmail.toLowerCase()) {
      return 'This account already exists';
    }

    if (email.toLowerCase() == AppConstants.driverEmail.toLowerCase()) {
      return 'This account already exists';
    }

    // Create new user
    final newUser = User(
      id: '',
      name: name,
      email: email,
      phone: phone,
      address: address ?? '',
      orders: 0,
      favorites: 0,
      isAdmin: false,
      isDriver: false,
    );

    _registeredUsers.add(newUser);

    // Auto-login after registration
    _user = newUser;
    _showLoginDialog = false;
    notifyListeners();

    return null; // Success
  }

  /// Login user (Supabase Auth + Supabase profiles for role detection)
  /// Returns null on success, error message on failure
  Future<String?> login(String email, String password) async {
    // Try Supabase Auth first
    try {
      await supabase.Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Fetch user profile from Supabase to get role and ID
      bool isAdmin = false;
      bool isDriver = false;
      String userId = '';

      try {
        final profileResponse = await supabase.Supabase.instance.client
            .from('profiles')
            .select('id, role')
            .eq('email', email)
            .maybeSingle();

        if (profileResponse != null) {
          final role = profileResponse['role'] as String?;
          userId = profileResponse['id'] as String? ?? '';
          isAdmin = role == 'admin';
          isDriver = role == 'driver';
          debugPrint('✅ User role fetched from Supabase: $role, ID: $userId');
        }
      } catch (e) {
        debugPrint('⚠️ Failed to fetch profile from Supabase: $e');
      }

      // If Supabase profile doesn't contain roles (e.g. demo/dev env), respect
      // the local demo emails defined in AppConstants so the admin/driver
      // accounts still work as expected.
      if (!isAdmin &&
          email.toLowerCase() == AppConstants.adminEmail.toLowerCase()) {
        isAdmin = true;
      }
      if (!isDriver &&
          email.toLowerCase() == AppConstants.driverEmail.toLowerCase()) {
        isDriver = true;
      }

      _user = User(
        id: userId,
        name: email.split('@').first,
        email: email,
        phone: '',
        address: '',
        orders: 0,
        favorites: 0,
        isAdmin: isAdmin,
        isDriver: isDriver,
      );
      _showLoginDialog = false;
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('Supabase login failed: $e');
    }

    // Fallback: Handle dedicated admin and driver accounts (for demo/testing)
    // Note: For demo accounts, use a simple password validation
    if (email.toLowerCase() == AppConstants.adminEmail.toLowerCase()) {
      if (password.isEmpty) {
        return 'Please enter a password';
      }
      _user = User(
        id: '',
        name: 'Admin',
        email: AppConstants.adminEmail,
        phone: '',
        address: '',
        orders: 0,
        favorites: 0,
        isAdmin: true,
        isDriver: false,
      );
      _showLoginDialog = false;
      notifyListeners();
      return null;
    }

    if (email.toLowerCase() == AppConstants.driverEmail.toLowerCase()) {
      if (password.isEmpty) {
        return 'Please enter a password';
      }
      _user = User(
        id: '',
        name: 'Driver',
        email: AppConstants.driverEmail,
        phone: '',
        address: '',
        orders: 0,
        favorites: 0,
        isAdmin: false,
        isDriver: true,
      );
      _showLoginDialog = false;
      notifyListeners();
      return null;
    }

    // Check if user exists in registered users
    final existingUser = _registeredUsers.firstWhere(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
      orElse: () => User(
        id: '',
        name: '',
        email: '',
        phone: '',
        address: '',
        orders: 0,
        favorites: 0,
        isAdmin: false,
        isDriver: false,
      ),
    );

    if (existingUser.email.isEmpty) {
      return 'No account associated with this email';
    }

    // Login successful
    _user = existingUser;
    _showLoginDialog = false;
    notifyListeners();
    return null;
  }

  void logout() {
    _user = null;
    notifyListeners();
  }

  void updateUserProfile(User updatedUser) {
    _user = updatedUser;
    notifyListeners();
  }

  void updatePhone(String phone) {
    if (_user != null) {
      _user = _user!.copyWith(phone: phone);
      notifyListeners();
    }
  }

  void updateAddress(String address) {
    if (_user != null) {
      _user = _user!.copyWith(address: address);
      notifyListeners();
    }
  }
}
