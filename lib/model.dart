import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthModel extends ChangeNotifier {
  FirebaseAuth? _auth;

  // Currently logged in user
  User? _user;

  User? get user => _user;

  set user(User? value) {
    _user = value;
    notifyListeners();
  }

  void initFirebaseAuth() {
    if (_auth != null) return;

    _auth = FirebaseAuth.instance;
    _auth!.authStateChanges().listen((user) => this.user = user);
  }

  void login(User user) {
    _user = user;
    notifyListeners();
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}

class FirestoreDataModel extends ChangeNotifier {
  // TODO
}
