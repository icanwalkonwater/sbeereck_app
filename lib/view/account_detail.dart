import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:mdi/mdi.dart';
import 'package:provider/provider.dart';
import 'package:routemaster/routemaster.dart';
import 'package:sbeereck_app/data/models.dart';
import 'package:sbeereck_app/data/providers.dart';
import 'package:sbeereck_app/view/account_form.dart';

import 'account_detail_recharge_form.dart';

class AccountDetailPage extends StatelessWidget {
  final String id;

  const AccountDetailPage({Key? key, required this.id}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final i10n = AppLocalizations.of(context)!;
    final account =
        context.select((FirestoreDataModel model) => model.accountById(id));

    return Scaffold(
      appBar: AppBar(
        title: Text(i10n.accountDetailTitle),
        actions: [
          Consumer<ThemeModel>(
              builder: (ctx, model, w) => IconButton(
                  icon: const Icon(Mdi.brightness6),
                  onPressed: () async => await model.switchTheme()))
        ],
      ),
      body: SingleChildScrollView(child: _AccountDetail(account: account)),
    );
  }
}

class _AccountDetail extends StatelessWidget {
  final CustomerAccount account;

  const _AccountDetail({Key? key, required this.account}) : super(key: key);

  void _onRecharge(BuildContext context) {
    showDialog(
        context: context,
        builder: (ctx) => AccountRechargeForm(callback: (recharge) {
              context
                  .read<FirestoreDataModel>()
                  // Fixed point decimal math
                  .rechargeAccount(
                      account.id, account.balance + (recharge * 100).round());
            }));
  }

  void _onPay(BuildContext context) {
    final model = context.read<FirestoreDataModel>();

    final transaction = EventTransactionDrink.blueprint(
      beerRef: model.beers.first.asRef,
      price: 100,
      customerRef: account.asRef,
      staffRef: model.currentStaff.asRef,
      created: Timestamp.now(),
    );

    model.newTransaction(transaction);
  }

  void _onEdit(BuildContext context) {
    showDialog(
        context: context,
        builder: (_) => AccountDetailsForm(
              onSubmit: (ctx, changes) => ctx
                  .read<FirestoreDataModel>()
                  .editAccount(account.id, changes),
              initialValues: account.toJsonEditable(),
            ));
  }

  void _onDelete(BuildContext context) {
    // Triggers 2 dialog confirmation boxes for fun then deletes

    final i10n = AppLocalizations.of(context)!;
    final gInt = MaterialLocalizations.of(context);

    // Separate inner dialog for clarity
    void _innerDialog() {
      showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
                title: Text(i10n.accountDeleteConfirmTitle2),
                actions: [
                  TextButton(
                    child: Text(gInt.cancelButtonLabel),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                  TextButton(
                    child: Text(i10n.accountDeleteConfirmOk2),
                    onPressed: () {
                      Navigator.pop(ctx);

                      // Navigate to home just to be safe
                      Routemaster.of(context).replace('/');

                      ctx.read<FirestoreDataModel>().deleteAccount(account.id);
                    },
                  )
                ],
              ));
    }

    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(i10n.accountDeleteConfirmTitle),
              actions: [
                TextButton(
                    child: Text(gInt.cancelButtonLabel),
                    onPressed: () => Navigator.pop(ctx)),
                TextButton(
                    child: Text(gInt.okButtonLabel),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _innerDialog();
                    })
              ],
            ));
  }

  void _onMakeMember(BuildContext context) {
    final i10n = AppLocalizations.of(context)!;
    final gInt = MaterialLocalizations.of(context);

    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(i10n.accountMakeMemberTitle),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(gInt.cancelButtonLabel),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context
                        .read<FirestoreDataModel>()
                        .makeAccountMember(account.id);
                  },
                  child: Text(gInt.okButtonLabel),
                )
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: _buildHeader(context, account),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: _buildBalance(context, account,
            onRecharge: () => _onRecharge(context)),
      ),
      if (account.isMember)
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: _buildActions(context, account,
              onPay: () => _onPay(context),
              onEdit: () => _onEdit(context),
              onDelete: () => _onDelete(context)),
        ),
      if (!account.isMember)
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: _buildNotMember(context,
              onMakeMember: () => _onMakeMember(context)),
        ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: _buildStats(context, account),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${account.firstName} ${account.lastName.toUpperCase()}',
                    style: theme.textTheme.headline5),
                Text(account.id, style: theme.textTheme.overline),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildBalance(BuildContext context, CustomerAccount account,
    {required VoidCallback onRecharge}) {
  final i10n = AppLocalizations.of(context)!;
  final formatter = NumberFormat.currency(symbol: '€');

  final theme = Theme.of(context);
  final color =
      account.isPoor ? theme.colorScheme.error : theme.colorScheme.primary;
  final onColor = account.isPoor ? Colors.white : theme.colorScheme.onPrimary;

  return ElevatedButton(
    style: ElevatedButton.styleFrom(primary: color, onPrimary: onColor),
    onPressed: onRecharge,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                account.isPoor ? Mdi.alert : Mdi.wallet,
                size: 48.0,
              ),
              const SizedBox(width: 8.0),
              Center(
                  child: Text(
                formatter.format(account.balanceReal),
                style: theme.textTheme.headline3?.apply(color: onColor),
              )),
            ],
          ),
          Align(
              alignment: Alignment.centerLeft,
              child: Text(i10n.accountDetailRecharge)),
        ],
      ),
    ),
  );
}

Widget _buildNotMember(BuildContext context,
    {required VoidCallback onMakeMember}) {
  final i10n = AppLocalizations.of(context)!;

  final theme = Theme.of(context);
  final color = theme.colorScheme.error;
  final onColor = Colors.white;

  return ElevatedButton(
    style: ElevatedButton.styleFrom(primary: color, onPrimary: onColor),
    onPressed: onMakeMember,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Mdi.closeThick, size: 48.0),
              const SizedBox(width: 8.0),
              Flexible(
                  child: Text(i10n.accountDetailNotMemberTitle,
                      style: theme.textTheme.headline5?.apply(color: onColor))),
            ],
          ),
          Align(
              alignment: Alignment.centerLeft,
              child: Text(i10n.accountDetailNotMemberHint)),
        ],
      ),
    ),
  );
}

Widget _buildActions(BuildContext context, CustomerAccount account,
    {required VoidCallback onPay,
    required VoidCallback onEdit,
    required VoidCallback onDelete}) {
  final i10n = AppLocalizations.of(context)!;

  final theme = Theme.of(context);
  final styleNormal = ElevatedButton.styleFrom(
      primary: theme.colorScheme.surface,
      onPrimary: theme.colorScheme.onSurface);
  final styleDelete = ElevatedButton.styleFrom(
      primary: theme.colorScheme.error, onPrimary: Colors.white);

  return Row(
    children: [
      Flexible(
        fit: FlexFit.tight,
        child: _buildAction(
            Mdi.glassMugVariant, i10n.accountDetailActionCollect, onPay,
            enabled: !account.isPoor),
      ),
      const SizedBox(width: 8.0, height: 0.0),
      Flexible(
        fit: FlexFit.tight,
        child: _buildAction(Mdi.pencil, i10n.accountDetailActionEdit, onEdit,
            style: styleNormal),
      ),
      const SizedBox(width: 8.0),
      Flexible(
          fit: FlexFit.tight,
          child: _buildAction(
              Mdi.deleteForever, i10n.accountDetailActionDelete, onDelete,
              style: styleDelete)),
    ],
  );
}

Widget _buildAction(IconData icon, String label, VoidCallback cb,
    {ButtonStyle? style, bool enabled = true}) {
  return ElevatedButton(
    onPressed: enabled ? cb : null,
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

Widget _buildStats(BuildContext context, CustomerAccount account) {
  final formatterQty = NumberFormat('#.0 L');
  final formatterMoney = NumberFormat.currency(symbol: '€');
  final theme = Theme.of(context);

  final l10n = AppLocalizations.of(context)!;

  return Card(
    elevation: 2.0,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.accountStatsTitle, style: theme.textTheme.headline6),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatModule(context,
                      icon: Mdi.beer,
                      value: formatterQty.format(account.stats.quantityDrank),
                      label: l10n.accountStatsDrinkTotal),
                  _buildStatModule(context,
                      icon: Mdi.beerOutline,
                      value: 'XX.X L',
                      label: l10n.accountStatsDrinkToday),
                ]),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatModule(context,
                      icon: Mdi.piggyBank,
                      value:
                          formatterMoney.format(account.stats.totalMoneyReal),
                      label: l10n.accountStatsSpentTotal),
                  _buildStatModule(context,
                      icon: Mdi.piggyBankOutline,
                      value: 'XX €',
                      label: l10n.accountStatsSpentToday),
                ]),
          ),
        ],
      ),
    ),
  );
}

Widget _buildStatModule(BuildContext context,
    {required IconData icon, required String value, required String label}) {
  final theme = Theme.of(context);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Row(
        children: [
          Icon(icon, size: 32.0),
          Text(value, style: theme.textTheme.headline5),
        ],
      ),
      const SizedBox(height: 4.0),
      Text(label),
    ],
  );
}
