import 'package:flutter/material.dart';

class AccountList extends StatelessWidget {
  const AccountList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: DataTable(
          columns: const [
            DataColumn(label: Text('Nom')),
            DataColumn(label: Text('Prénom')),
            DataColumn(label: Text('Membre')),
            DataColumn(label: Text('Solde')),
          ],
          rows: List.generate(
              50,
              (index) => const DataRow(cells: [
                    DataCell(Text('Barbaza')),
                    DataCell(Text('Valentin')),
                    DataCell(Checkbox(value: true, onChanged: null)),
                    DataCell(Text('10.5€')),
                  ]))),
    );
  }
}
