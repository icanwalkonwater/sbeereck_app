import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mdi/mdi.dart';
import 'package:provider/provider.dart';
import 'package:sbeereck_app/data/model/account.dart';
import 'package:sbeereck_app/data/provider/firestore.dart';
import 'package:sbeereck_app/data/providers.dart';

class AccountDetailPage extends StatelessWidget {
  final String id;

  const AccountDetailPage({Key? key, required this.id}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final i10n = AppLocalizations.of(context)!;
    final account =
        context.select((FirestoreDataModel model) => model.accountById(id));

    return Scaffold(
      appBar: AppBar(title: Text(i10n.accountDetailTitle), actions: [Consumer<ThemeModel>(
          builder: (ctx, model, w) => IconButton(
              icon: const Icon(Mdi.brightness6),
              onPressed: () async => await model.switchTheme()))],),
      body: SingleChildScrollView(child: _AccountDetail(account: account)),
      floatingActionButton: const FloatingActionButton(
          child: Icon(Mdi.currencyEur), onPressed: null),
    );
  }
}

class _AccountDetail extends StatelessWidget {
  final CustomerAccount account;

  const _AccountDetail({Key? key, required this.account}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: _buildHeader(context, account),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: _buildActions(context, account),
      ),
    ]);
  }
}

Widget _buildHeader(BuildContext context, CustomerAccount account) {
  final theme = Theme.of(context);
  return Card(
    elevation: 2.0,
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
                foregroundImage: AssetImage(account.school.assetLogo()),
                radius: 40.0),
          ),
          Flexible(
            child: Text(
                '${account.firstName} ${account.lastName.toUpperCase()}',
                style: theme.textTheme.headline5),
          ),
        ],
      ),
    ),
  );
}

Widget _buildActions(BuildContext context, CustomerAccount account) {
  final i10n = AppLocalizations.of(context)!;
  final theme = Theme.of(context);
  final btnTheme = theme.buttonTheme;
  final style = ButtonStyle(backgroundColor: MaterialStateProperty.all(theme.colorScheme.secondaryVariant));
  return Row(
    children: [
      Flexible(
        fit: FlexFit.tight,
        child: _buildAction(
            Mdi.currencyEur, i10n.accountDetailActionCollect, () {}, style),
      ),
      const SizedBox(width: 8.0, height: 0.0),
      Flexible(
        fit: FlexFit.tight,
        child:
            _buildAction(Mdi.accountEdit, i10n.accountDetailActionEdit, () {}, null),
      ),
      const SizedBox(width: 8.0, height: 0.0),
      Flexible(
          fit: FlexFit.tight,
          child: _buildAction(
              Mdi.accountEdit, i10n.accountDetailActionEdit, () {}, null)),
    ],
  );
}

Widget _buildAction(
    IconData icon, String label, VoidCallback cb, ButtonStyle? style) {
  return ElevatedButton(
    onPressed: () {},
    style: style,
    child: Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Column(children: [
        Icon(icon, size: 48.0),
        Text(label),
      ]),
    ),
  );
}
