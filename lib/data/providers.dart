import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sbeereck_app/data/model/account.dart';
import 'package:shared_preferences/shared_preferences.dart';

const themeKey = 'theme';

class ThemeModel extends ChangeNotifier {
  Future init() async {
    _storage = await SharedPreferences.getInstance();
    if (_storage.containsKey(themeKey)) {
      _mode = Brightness.values[_storage.getInt(themeKey)!];
    }
  }

  late SharedPreferences _storage;

  Brightness _mode = Brightness.light;

  Brightness get theme => _mode;

  Future switchTheme() async {
    if (_mode == Brightness.light) {
      _mode = Brightness.dark;
    } else {
      _mode = Brightness.light;
    }

    await _storage.setInt('theme', _mode.index);
    notifyListeners();
  }
}

class AuthModel extends ChangeNotifier {
  AuthModel() {
    // initFirebaseAuth();
    FirebaseAuth.instance.authStateChanges().listen((user) => this.user = user);
  }

  // Currently logged in user
  User? _user;

  User? get user => _user;

  set user(User? value) {
    _user = value;
    notifyListeners();
  }

  bool get loggedIn => _user != null;

  Future logout() async {
    await FirebaseAuth.instance.signOut();
  }
}

class FirestoreDataModel extends ChangeNotifier {
  final List<CustomerAccount> _accounts = [];

  List<CustomerAccount> get accounts => _accounts;

  void Function(QuerySnapshot<T>) handleChangesFactory<T>(List<T> dest) {
    return (snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.oldIndex != -1) {
          dest.removeAt(change.oldIndex);
        }
        if (change.newIndex != -1) {
          dest.insert(change.newIndex, change.doc.data()!);
        }
      }
      notifyListeners();
    };
  }

  void logError(dynamic err, dynamic stacktrace) =>
      log("Firebase error !", error: err, stackTrace: stacktrace);

  FirestoreDataModel() {
    // Setup accounts stream
    FirebaseFirestore.instance
        .collection('accounts')
        .withConverter<CustomerAccount>(
            fromFirestore: (snapshot, a) =>
                CustomerAccount.fromJson(snapshot.id, snapshot.data()!),
            toFirestore: (account, a) => account.toJson())
        .snapshots()
        // When accounts are updated
        .listen(handleChangesFactory<CustomerAccount>(_accounts),
            onError: logError);
  }
}
