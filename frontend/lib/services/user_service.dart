import 'dart:math';
import 'package:flutter/foundation.dart';

class UserService extends ChangeNotifier {
  String displayName = 'Benki';
  String email = 'player@gmail.com';
  bool isLoggedIn = false;
  int avatarIndex = 0;

  void completeGoogleSignIn({
    required String enteredEmail,
    required String enteredName,
    required int selectedAvatar,
  }) {
    email = enteredEmail.trim().isEmpty ? 'player@gmail.com' : enteredEmail.trim();
    displayName = enteredName.trim().isEmpty ? 'Player' : enteredName.trim();
    avatarIndex = selectedAvatar;
    isLoggedIn = true;
    notifyListeners();
  }

  void loginAsGuest() {
    final suffix = 100 + Random().nextInt(900);
    email = 'guest_$suffix@guest.local';
    displayName = 'Guest_$suffix';
    avatarIndex = Random().nextInt(6);
    isLoggedIn = true;
    notifyListeners();
  }

  void updateProfile({required String newName, required int newAvatarIndex}) {
    displayName = newName.trim().isEmpty ? displayName : newName.trim();
    avatarIndex = newAvatarIndex;
    notifyListeners();
  }

  void randomizeAvatar() {
    avatarIndex = (avatarIndex + 1) % 6;
    notifyListeners();
  }

  void logout() {
    isLoggedIn = false;
    notifyListeners();
  }
}