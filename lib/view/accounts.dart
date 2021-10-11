import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sbeereck_app/data/providers.dart';

class AccountList extends StatelessWidget {
  const AccountList({Key? key}) : super(key: key);

  List<DataRow> _buildRows(FirestoreDataModel model) {
    return model.accounts
        .map((account) => DataRow(key: ValueKey(account.id), cells: [
              DataCell(Text(account.firstName)),
              DataCell(Text(account.lastName)),
              DataCell(Checkbox(value: account.isMember, onChanged: null)),
              DataCell(Text('${account.balance}€')),
            ]))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: FittedBox(
        child: Consumer<FirestoreDataModel>(
          builder: (ctx, model, w) => DataTable(
            columns: const [
              DataColumn(label: Text('Nom')),
              DataColumn(label: Text('Prénom')),
              DataColumn(label: Text('Membre?')),
              DataColumn(label: Text('Solde')),
            ],
            rows: _buildRows(model),
          ),
        ),
      ),
    );
  }
}
