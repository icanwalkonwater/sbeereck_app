import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mdi/mdi.dart';
import 'package:provider/provider.dart';
import 'package:routemaster/routemaster.dart';
import 'package:sbeereck_app/view/beer_list.dart';

import '../data/providers.dart';
import 'accounts/account_form.dart';
import 'accounts/accounts.dart';
import 'staff_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

enum _TabsIndex {
  accounts,
  beers,
  staffs,
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _tabController;

  // Used only for the bottom nav bar
  int _currentIndex = _TabsIndex.accounts.index;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: _TabsIndex.values.length, vsync: this);
    _tabController.addListener(
        () => setState(() => _currentIndex = _tabController.index));
  }

  void _handleDialogAddAccount(BuildContext context) {
    showDialog(
        context: context,
        useRootNavigator: false,
        barrierDismissible: false,
        builder: (ctx) =>
            AccountDetailsForm(onSubmit: (context, account) async {
              final id =
                  await context.read<FirestoreDataModel>().newAccount(account);
              Routemaster.of(context).push('/account/$id');
            }));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      // Top bar
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
          IconButton(
              icon: const Icon(Mdi.brightness6),
              onPressed: () async =>
                  await context.read<ThemeModel>().switchTheme()),
          IconButton(
            icon: const Icon(Mdi.logout),
            onPressed: () async => await context.read<AuthModel>().logout(),
          )
        ],
      ),

      // Body tabs
      body: TabBarView(controller: _tabController, children: [
        AccountList(),
        BeerList(),
        StaffList(),
      ]),

      // FAB
      floatingActionButton: _currentIndex == _TabsIndex.accounts.index
          ? FloatingActionButton(
              child: const Icon(Mdi.accountPlus),
              onPressed: () => _handleDialogAddAccount(context))
          : null,

      // Tab navigation
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Mdi.accountGroup), label: l10n.pageAccount),
          BottomNavigationBarItem(
              icon: const Icon(Mdi.glassMugVariant), label: l10n.pageBeers),
          BottomNavigationBarItem(
              icon: const Icon(Mdi.shieldAccount), label: 'Staffs'),
        ],
        onTap: _tabController.animateTo,
      ),
    );
  }
}
