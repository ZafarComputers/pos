import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'dart:io';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  UserProfile? _userProfile;
  bool _isLoading = false;
  int _imageVersion = 0;

  User? get user => _user;
  String? get token => _token;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null && _user != null;
  int get imageVersion => _imageVersion;

  void incrementImageVersion() {
    _imageVersion++;
    notifyListeners();
  }

  // Initialize auth state
  Future<void> initAuth() async {
    _token = await ApiService.getToken();
    if (_token != null) {
      // TODO: You might want to validate token or fetch user profile here
      // For now, we'll just check if token exists
      notifyListeners();
    }
  }

  // Login method
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    print('🚀 AuthProvider: Starting login process for $email');

    try {
      final response = await ApiService.login(email, password);
      _token = response['token'];
      _user = User.fromJson(response['user']);

      print('✅ AuthProvider: Login successful for user: ${_user?.fullName}');

      // Load user profile after login
      await getUserProfile();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ AuthProvider: Login failed with error: $e');

      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout method
  Future<void> logout() async {
    await ApiService.logout();
    _user = null;
    _token = null;
    _userProfile = null;
    notifyListeners();
  }

  // Get user profile
  Future<bool> getUserProfile() async {
    if (_user == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      print('👤 AuthProvider: Fetching user profile');
      final profileData = await ApiService.getProfile(_user!.id);

      if (profileData.isNotEmpty) {
        // The response has 'data' with user and profile
        final actualData = profileData['data'];
        if (actualData != null) {
          // Update user if needed
          if (actualData['role'] != null) {
            // Update user role if changed
            _user = User.fromJson(actualData);
          }
          final actualProfileData = actualData['profile'];
          if (actualProfileData != null) {
            _userProfile = UserProfile.fromJson(
              actualProfileData,
              currentUser: _user,
            );
            print(
              '✅ AuthProvider: Profile loaded for user: ${_userProfile?.user.fullName}',
            );
            // Check for local profile picture if not set
            if (_userProfile!.profilePicture == null) {
              String localPath =
                  '${Directory.current.path}/assets/images/profiles/profile_${_user!.id}.jpg';
              if (File(localPath).existsSync()) {
                _userProfile!.profilePicture =
                    'assets/images/profiles/profile_${_user!.id}.jpg';
                _imageVersion++;
              }
            }
          } else {
            print('⚠️ AuthProvider: Profile data is null');
            _userProfile = null;
          }
        } else {
          print('⚠️ AuthProvider: Data is null');
          _userProfile = null;
        }
      } else {
        print('⚠️ AuthProvider: No profile data found');
        _userProfile = null;
      }

      _isLoading = false;
      notifyListeners();
      return _userProfile != null;
    } catch (e) {
      print('❌ AuthProvider: Failed to load profile: $e');
      _userProfile = null; // Set to null on error
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Create user profile
  Future<bool> createUserProfile(Map<String, dynamic> profileData) async {
    if (_user == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      print('📝 AuthProvider: Creating user profile');
      final response = await ApiService.createProfile(profileData);

      // Check if the response has a 'data' key or is the profile data directly
      final actualProfileData = response.containsKey('data')
          ? response['data']
          : response;

      if (actualProfileData != null) {
        _userProfile = UserProfile.fromJson(
          actualProfileData,
          currentUser: _user,
        );
        // Check for local profile picture if not set
        if (_userProfile!.profilePicture == null) {
          String localPath =
              '${Directory.current.path}/assets/images/profiles/profile_${_user!.id}.jpg';
          if (File(localPath).existsSync()) {
            _userProfile!.profilePicture =
                'assets/images/profiles/profile_${_user!.id}.jpg';
            _imageVersion++;
          }
        }
        print('✅ AuthProvider: Profile created successfully');
      } else {
        print('⚠️ AuthProvider: Profile creation response invalid');
        _userProfile = null;
      }
      _isLoading = false;
      notifyListeners();
      return _userProfile != null;
    } catch (e) {
      print('❌ AuthProvider: Failed to create profile: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(Map<String, dynamic> profileData) async {
    if (_user == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      print('📝 AuthProvider: Updating user profile');
      final oldProfilePicture = _userProfile?.profilePicture;
      final response = await ApiService.updateProfile(_user!.id, profileData);

      // Update local profile data
      final actualProfileData = response.containsKey('data')
          ? response['data']
          : response;
      if (actualProfileData != null) {
        _userProfile = UserProfile.fromJson(
          actualProfileData,
          currentUser: _user,
        );
        // Retain local profile picture if backend returns HTTP URL
        if (_userProfile!.profilePicture == null && oldProfilePicture != null) {
          _userProfile!.profilePicture = oldProfilePicture;
        }
        _imageVersion++;
      }

      print('✅ AuthProvider: Profile updated successfully');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // If profile doesn't exist (404), try to create it
      if (e.toString().contains('404') ||
          e.toString().contains('No query results')) {
        print(
          '⚠️ AuthProvider: Profile not found, attempting to create new profile',
        );
        try {
          final createResponse = await ApiService.createProfile(profileData);
          final actualCreateData = createResponse.containsKey('data')
              ? createResponse['data']
              : createResponse;
          if (actualCreateData != null) {
            _userProfile = UserProfile.fromJson(
              actualCreateData,
              currentUser: _user,
            );
            print('✅ AuthProvider: Profile created successfully');
            _isLoading = false;
            notifyListeners();
            return true;
          } else {
            print('⚠️ AuthProvider: Profile creation response invalid');
            _isLoading = false;
            notifyListeners();
            return false;
          }
        } catch (createError) {
          print('❌ AuthProvider: Failed to create profile: $createError');
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        print('❌ AuthProvider: Failed to update profile: $e');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    }
  }

  // Upload profile picture
  Future<bool> uploadProfilePicture(String imagePath) async {
    if (_user == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      print('🖼️ AuthProvider: Uploading profile picture');
      final response = await ApiService.uploadProfilePicture(
        _user!.id,
        imagePath,
      );

      // Update local profile data if needed
      if (_userProfile != null && response.containsKey('data')) {
        _userProfile = UserProfile.fromJson(response['data']);
      }

      print('✅ AuthProvider: Profile picture uploaded successfully');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ AuthProvider: Failed to upload profile picture: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete user account
  Future<bool> deleteUser() async {
    if (_user == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      print('🗑️ AuthProvider: Deleting user account');
      await ApiService.deleteUser(_user!.id);

      // Clear all user data
      _user = null;
      _token = null;
      _userProfile = null;

      print('✅ AuthProvider: User account deleted successfully');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ AuthProvider: Failed to delete user account: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get auth headers for API calls
  Map<String, String> getAuthHeaders() {
    if (_token == null) return {};
    return {
      'Authorization': 'Bearer $_token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }
}
