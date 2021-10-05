import 'package:flutter/material.dart';
import 'package:mdi/mdi.dart';
import 'package:provider/provider.dart';
import 'package:sbeereck_app/data/providers.dart';
import 'package:sbeereck_app/view/accounts.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("S'Beer Eck"),
        actions: [
          Consumer<ThemeModel>(
              builder: (ctx, model, w) => IconButton(
                  icon: const Icon(Mdi.brightness6),
                  onPressed: () => model.switchTheme())),
        ],
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
