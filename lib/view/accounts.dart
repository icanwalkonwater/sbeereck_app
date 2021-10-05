import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sbeereck_app/data/providers.dart';

class AccountList extends StatelessWidget {
  const AccountList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // return SingleChildScrollView(
    //   child: FittedBox(
    //     child: DataTable(
    //         columns: const [
    //           DataColumn(label: Text('Nom')),
    //           DataColumn(label: Text('Prénom')),
    //           DataColumn(label: Text('Membre')),
    //           DataColumn(label: Text('Solde')),
    //         ],
    //         rows: List.generate(
    //             50,
    //             (index) => DataRow(
    //               key: ValueKey(index),
    //                 cells: const [
    //                   DataCell(Text('Barbaza')),
    //                   DataCell(Text('Valentin')),
    //                   DataCell(Checkbox(value: true, onChanged: null)),
    //                   DataCell(Text('10.5€')),
    //                 ]))),
    //   ),
    // );

    // TODO: something pretty
    return SingleChildScrollView(
      child: Consumer<FirestoreDataModel>(
          builder: (ctx, model, w) => Column(
                children:
                    model.accounts.map((e) => Text(e.toString())).toList(),
              )),
    );
  }
}
