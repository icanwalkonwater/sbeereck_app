import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mdi/mdi.dart';
import 'package:provider/provider.dart';
import 'package:routemaster/routemaster.dart';

import '../../data/models.dart';
import '../../data/providers.dart';
import '../../utils.dart';
import 'account_detail_recharge_form.dart';
import 'account_form.dart';

class _AccountWithMoreStats {
  final CustomerAccount account;
  final CustomerStat stats;

  _AccountWithMoreStats(this.account, this.stats);
}

class AccountDetailPage extends StatelessWidget {
  final String id;

  const AccountDetailPage({Key? key, required this.id}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final i10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(i10n.accountDetailTitle),
        actions: [
          IconButton(
              icon: const Icon(Mdi.brightness6),
              onPressed: () async =>
                  await context.read<ThemeModel>().switchTheme())
        ],
      ),
      body: SingleChildScrollView(
          child: Selector<FirestoreDataModel, _AccountWithMoreStats>(
              selector: (_, model) => _AccountWithMoreStats(
                  model.accountById(id),
                  model.computeAccountStatsForCurrentEvent(id)),
              builder: (_, account, __) => _AccountDetail(
                  account: account.account, statsForEvent: account.stats))),
    );
  }
}

class _AccountDetail extends StatelessWidget {
  final CustomerAccount account;
  final CustomerStat statsForEvent;

  const _AccountDetail(
      {Key? key, required this.account, required this.statsForEvent})
      : super(key: key);

  void _onRecharge(BuildContext context) {
    showDialog(
        context: context,
        builder: (ctx) => AccountRechargeForm(callback: (recharge) {
              final model = context.read<FirestoreDataModel>();
              model.handleTransaction(
                  account,
                  EventTransactionRecharge.blueprint(
                      account, model.currentStaff, (recharge * 100).round()));
            }));
  }

  void _onPay(BuildContext context) {
    Routemaster.of(context).push('order');
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

    final l10n = AppLocalizations.of(context)!;

    showSimpleDialog(
        context: context,
        title: l10n.accountDeleteConfirmTitle,
        popOnAction: true,
        onOk: (ctx) {
          showSimpleDialog(
              context: ctx,
              title: l10n.accountDeleteConfirmTitle2,
              popOnAction: true,
              onOk: (ctx) {
                // Navigate to home just to be safe
                Routemaster.of(ctx).replace('/');
                ctx.read<FirestoreDataModel>().deleteAccount(account.id);
              });
        });
  }

  void _onMakeMember(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showSimpleDialog(
        context: context,
        title: l10n.accountMakeMemberTitle,
        popOnAction: true,
        onOk: (ctx) {
          ctx.read<FirestoreDataModel>().makeAccountMember(account.id);
        });
  }

  @override
  Widget build(BuildContext context) {
    return _AccountBodyWrapper(children: [
      _AccountHeader(account: account),
      _AccountBalance(account: account, onRecharge: () => _onRecharge(context)),
      if (!account.isMember)
        _AccountMakeMember(onMakeMember: () => _onMakeMember(context)),
      if (account.isMember)
        _AccountActions(
          account: account,
          onPay: () => _onPay(context),
          onEdit: () => _onEdit(context),
          onDelete: () => _onDelete(context),
        ),
      _AccountStats(account: account, statsForEvent: statsForEvent),
    ]);
  }
}

class _AccountBodyWrapper extends StatelessWidget {
  final List<Widget> children;

  const _AccountBodyWrapper({Key? key, required this.children})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
        children: children
            .map((child) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: child,
                ))
            .toList(growable: false));
  }
}

class _AccountHeader extends StatelessWidget {
  final CustomerAccount account;

  const _AccountHeader({Key? key, required this.account}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final image = AssetImage(account.school.assetLogo());
    final name = '${account.firstName} ${account.lastName.toUpperCase()}';
    final id = account.id;

    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(foregroundImage: image, radius: 40.0),
            ),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: theme.textTheme.headline5),
                  Text(id, style: theme.textTheme.overline),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountBalance extends StatelessWidget {
  final CustomerAccount account;
  final VoidCallback onRecharge;

  const _AccountBalance(
      {Key? key, required this.account, required this.onRecharge})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final balance = moneyFormatter.format(account.balanceReal);

    final theme = Theme.of(context);
    final bgColor =
        account.isPoor ? theme.colorScheme.error : theme.colorScheme.primary;
    final fgColor = account.isPoor ? Colors.white : theme.colorScheme.onPrimary;

    return ElevatedButton(
      onPressed: onRecharge,
      style: ElevatedButton.styleFrom(primary: bgColor, onPrimary: fgColor),
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
                  balance,
                  style: theme.textTheme.headline3?.apply(color: fgColor),
                )),
              ],
            ),
            Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.accountDetailRecharge)),
          ],
        ),
      ),
    );
  }
}

class _AccountMakeMember extends StatelessWidget {
  final VoidCallback onMakeMember;

  const _AccountMakeMember({Key? key, required this.onMakeMember})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final theme = Theme.of(context);
    final bgColor = theme.colorScheme.error;
    final fgColor = Colors.white;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(primary: bgColor, onPrimary: fgColor),
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
                    child: Text(l10n.accountDetailNotMemberTitle,
                        style:
                            theme.textTheme.headline5?.apply(color: fgColor))),
              ],
            ),
            Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.accountDetailNotMemberHint)),
          ],
        ),
      ),
    );
  }
}

class _AccountActions extends StatelessWidget {
  final CustomerAccount account;
  final VoidCallback onPay;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AccountActions(
      {Key? key,
      required this.account,
      required this.onPay,
      required this.onEdit,
      required this.onDelete})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final theme = Theme.of(context);
    final btnStylePay = ElevatedButton.styleFrom();
    final btnStyleEdit = ElevatedButton.styleFrom(
        primary: theme.colorScheme.surface,
        onPrimary: theme.colorScheme.onSurface);
    final btnStyleDelete = ElevatedButton.styleFrom(
      primary: theme.colorScheme.error,
      onPrimary: Colors.white,
    );

    return Row(
      children: [
        Flexible(
            fit: FlexFit.tight,
            child: _AccountAction(
                icon: Mdi.glassMugVariant,
                label: l10n.accountDetailActionCollect,
                style: btnStylePay,
                onPressed: onPay,
                enabled: !account.isPoor)),
        const SizedBox(width: 8.0, height: 0.0),
        Flexible(
            fit: FlexFit.tight,
            child: _AccountAction(
                icon: Mdi.pencil,
                label: l10n.accountDetailActionEdit,
                style: btnStyleEdit,
                onPressed: onEdit)),
        const SizedBox(width: 8.0),
        Flexible(
            fit: FlexFit.tight,
            child: _AccountAction(
                icon: Mdi.deleteForever,
                label: l10n.accountDetailActionDelete,
                style: btnStyleDelete,
                onPressed: onDelete)),
      ],
    );
  }
}

class _AccountAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final ButtonStyle? style;
  final bool enabled;

  const _AccountAction(
      {Key? key,
      required this.icon,
      required this.label,
      this.style,
      required this.onPressed,
      this.enabled = true})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: style,
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
          child: Column(children: [
            Icon(icon, size: 48.0),
            Text(label),
          ]),
        ));
  }
}

class _AccountStats extends StatelessWidget {
  final CustomerAccount account;
  final CustomerStat statsForEvent;

  const _AccountStats(
      {Key? key, required this.account, required this.statsForEvent})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // We can do it here because the widget will be updated anyway when a transaction is submitted
    final spentOnDrinkTonight = context
        .read<FirestoreDataModel>()
        .computeMoneySpentInDrinkForCurrentEventForAccount(account.id);

    return _AccountStatsLayout(title: l10n.accountStatsTitle, rowOne: [
      _AccountStatModule(
        icon: Mdi.beer,
        label: l10n.accountStatsDrinkTotal,
        value: beerQuantityFormatter.format(account.stats.quantityDrank),
      ),
      _AccountStatModule(
        icon: Mdi.beerOutline,
        label: l10n.accountStatsDrinkToday,
        value: beerQuantityFormatter.format(statsForEvent.quantityDrank),
      ),
    ], rowTwo: [
      _AccountStatModule(
        icon: Mdi.piggyBank,
        label: l10n.accountStatsSpentTotal,
        value: moneyFormatter.format(account.stats.totalMoneyReal),
      ),
      _AccountStatModule(
        icon: Mdi.piggyBankOutline,
        label: l10n.accountStatsRechargeToday,
        value: moneyFormatter.format(statsForEvent.totalMoneyReal),
      ),
    ], rowThree: [
      _AccountStatModule(
        icon: Mdi.glassMugVariant,
        label: l10n.accountStatsSpentToday,
        value: moneyFormatter.format(spentOnDrinkTonight),
      ),
    ]);
  }
}

class _AccountStatsLayout extends StatelessWidget {
  final String title;
  final List<Widget> rowOne;
  final List<Widget> rowTwo;
  final List<Widget> rowThree;

  const _AccountStatsLayout(
      {Key? key,
      required this.title,
      required this.rowOne,
      required this.rowTwo,
      required this.rowThree})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.headline6),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: rowOne),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: rowTwo),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: rowThree),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountStatModule extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AccountStatModule(
      {Key? key, required this.icon, required this.label, required this.value})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
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
}
