import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Stolen straight from the docs
Future<UserCredential?> signInWithGoogleNative() async {
  final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
  if (googleUser == null) {
    return null;
  }

  final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

  final credentials = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );

  return await FirebaseAuth.instance.signInWithCredential(credentials);
}

Future<UserCredential> signInWithGoogleWeb() async {
  GoogleAuthProvider googleProvider = GoogleAuthProvider();

  googleProvider.addScope('https://www.googleapis.com/auth/contacts.readonly');

  return await FirebaseAuth.instance.signInWithPopup(googleProvider);
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final Future<UserCredential?> _credentials = Platform.isAndroid
      ? signInWithGoogleNative()
      : signInWithGoogleWeb();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _credentials,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            log('Data: ' + snapshot.requireData.toString());
            return const Center(child: Text('Connected'));
          } else {
            return const Center(child: Text('WTF'));
          }
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
