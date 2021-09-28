import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Stolen straight from the docs
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
  final GoogleSignIn _google = GoogleSignIn.standard(scopes: ['email']);
  Future<User?>? _credentials;

  _LoginPageState() {
    // if (_google.currentUser != null) {
    //   // If the currentUser is already there, calling this should be instantaneous.
    //   setState(() {
    //     _credentials = _signInWithGoogleNative();
    //   });
    // }
  }

  Future<User?> _signInWithGoogleNative() async {
    if (FirebaseAuth.instance.currentUser != null) {
      return FirebaseAuth.instance.currentUser;
    }

    final GoogleSignInAccount? googleUser = await _google.signIn();
    if (googleUser == null) {
      return null;
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credentials = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return (await FirebaseAuth.instance.signInWithCredential(credentials)).user;
  }

  void _onClickLogin() {
    setState(() {
      _credentials = _signInWithGoogleNative();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _credentials,
      builder: (context, AsyncSnapshot<User?> snapshot) {
        // If no logging process
        if (snapshot.connectionState == ConnectionState.none) {
          return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            FractionallySizedBox(
              widthFactor: 0.5,
              child: Image.asset('assets/logo.png'),
            ),
            FractionallySizedBox(heightFactor: 0.1, child: Container()),
            FractionallySizedBox(
              widthFactor: 0.6,
              child: SignInButton(Buttons.GoogleDark, onPressed: _onClickLogin),
            )
          ]);

          return Center(
              child: IntrinsicHeight(
                  child: SignInButton(Buttons.GoogleDark,
                      onPressed: _onClickLogin)));
        }

        // If done
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            log('Data: ' + snapshot.data.toString());
            return const Center(child: Text('Connected'));
          } else if (snapshot.hasError) {
            log('Error', error: snapshot.error);
            return const Center(child: Text('Error ! See console'));
          } else {
            return const Center(child: Text('WTF, no data'));
          }
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
