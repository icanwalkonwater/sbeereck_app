import 'package:checkbox_formfield/checkbox_formfield.dart';
import 'package:flutter/material.dart';
import 'package:sbeereck_app/data/models.dart';

const _fieldRequired = 'Champs requis';

class AccountCreationForm extends StatefulWidget {
  const AccountCreationForm({Key? key}) : super(key: key);

  @override
  State<AccountCreationForm> createState() => _AccountCreationFormState();
}

class _AccountCreationFormState extends State<AccountCreationForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Creation compte'),
      scrollable: true,
      content: Form(
          key: _formKey,
          child: Column(children: [

            // Last name
            TextFormField(
              textCapitalization: TextCapitalization.words,
              validator: (value) =>
                  (value?.isNotEmpty ?? false) ? null : _fieldRequired,
              decoration: const InputDecoration(
                  labelText: 'Prénom'),
            ),

            // First name
            TextFormField(
              textCapitalization: TextCapitalization.words,
              validator: (value) => (value?.isNotEmpty ?? false) ? null : _fieldRequired,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),

            // School
            DropdownButtonFormField(
              decoration: const InputDecoration(labelText: 'Ecole'),
                onChanged: (a) {},
                items: const [
              DropdownMenuItem(child: Text('Ensimag'), value: CustomerSchool.Ensimag),
              DropdownMenuItem(child: Text('Phelma'), value: CustomerSchool.Phelma),
            ]),

            CheckboxListTileFormField(
              title: const Text('Adhésion payée ?'),
            ),

          ])),
      actions: [
        TextButton(
          child: const Text('Annuler'),
          onPressed: () => Navigator.pop(context),
        ),
        TextButton(
          child: const Text('Ok'),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // Valid
              Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }
}
