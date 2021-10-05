import 'package:flutter/material.dart';
import 'package:sbeereck_app/accounts.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("S'Beer Eck"),
      ),
      body: const AccountList(),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_rounded), label: 'Comptes'),
          BottomNavigationBarItem(icon: Icon(Icons.anchor), label: 'Bières')
        ],
      ),
    );
  }
}
