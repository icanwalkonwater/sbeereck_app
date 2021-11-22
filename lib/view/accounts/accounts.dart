import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:routemaster/routemaster.dart';

import '../../data/providers.dart';
import '../../utils.dart';

class AccountList extends StatefulWidget {
  const AccountList({Key? key}) : super(key: key);

  @override
  State<AccountList> createState() => _AccountListState();
}

class _AccountListState extends State<AccountList> {
  var _searchTerm = '';

  List<DataRow> _buildRows(BuildContext ctx, FirestoreDataModel model) {
    // For an account to show it needs to contains every non-empty search term in its first/last name or school

    // Prepare terms
    final searchTerms = _searchTerm.toLowerCase().split(' ');
    searchTerms.removeWhere((element) => element.isEmpty);

    // Remove non valid terms
    final sorted = searchTerms.isNotEmpty
        ? model.accounts.where((account) {
            final query = searchTerms.toList();

            for (var candidate in [
              account.firstName.toLowerCase(),
              account.lastName.toLowerCase(),
              account.school.toString().toLowerCase(),
            ]) {
              query.removeWhere((term) => candidate.contains(term));
            }

            // If the query is empty, every search term is there
            return query.isEmpty;
          }).toList(growable: false)
        : model.accounts.toList(growable: false);

    final colorPoor = MaterialStateProperty.all(Theme.of(context).errorColor);
    return sorted
        .map((account) => DataRow(
            key: ValueKey(account.id),
            color: account.isVeryPoor ? colorPoor : null,
            cells: [
              DataCell(Text(
                account.lastName,
              )),
              DataCell(Text(account.firstName)),
              DataCell(Checkbox(value: account.isMember, onChanged: null)),
              DataCell(Text(moneyFormatter.format(account.balanceReal))),
            ],
            onSelectChanged: (_) =>
                Routemaster.of(ctx).push('/account/${account.id}')))
        .toList(growable: false);
  }

  void _onSearchInput(String val) => setState(() => _searchTerm = val);

  @override
  Widget build(BuildContext context) {
    final i10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 16.0),
          child: TextField(
            onChanged:
                debounce(const Duration(milliseconds: 200), _onSearchInput),
            decoration: InputDecoration(
              labelText: i10n.searchBarHint,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
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
          ),
        ),
      ],
    );
  }
}
