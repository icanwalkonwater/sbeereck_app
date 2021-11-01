import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:routemaster/routemaster.dart';
import 'package:sbeereck_app/data/providers.dart';

final _moneyFormat = NumberFormat.currency(symbol: '€', decimalDigits: 2);

class AccountList extends StatelessWidget {
  const AccountList({Key? key}) : super(key: key);

  List<DataRow> _buildRows(BuildContext ctx, FirestoreDataModel model) {
    final sorted = model.accounts.toList(growable: false);
    sorted.sort((a, b) => a.lastName.compareTo(b.lastName));

    return sorted
        .map((account) => DataRow(
            key: ValueKey(account.id),
            cells: [
              DataCell(Text(account.lastName)),
              DataCell(Text(account.firstName)),
              DataCell(Checkbox(value: account.isMember, onChanged: null)),
              DataCell(Text(_moneyFormat.format(account.balanceReal))),
            ],
            onSelectChanged: (_) =>
                Routemaster.of(ctx).push('/account/${account.id}')))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final i10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      child: FittedBox(
        child: Consumer<FirestoreDataModel>(
          builder: (ctx, model, w) => DataTable(
            columns: [
              DataColumn(label: Text(i10n.accountLastName)),
              DataColumn(label: Text(i10n.accountFirstName)),
              DataColumn(label: Text(i10n.accountIsMember)),
              DataColumn(label: Text(i10n.accountBalance)),
            ],
            rows: _buildRows(context, model),
            showCheckboxColumn: false,
          ),
        ),
      ),
    );
  }
}
