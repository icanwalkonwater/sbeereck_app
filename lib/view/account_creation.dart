import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:sbeereck_app/data/model/account.dart';

class AccountCreationForm extends StatefulWidget {
  const AccountCreationForm({Key? key}) : super(key: key);

  @override
  State<AccountCreationForm> createState() => _AccountCreationFormState();
}

class _AccountCreationFormState extends State<AccountCreationForm> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final i10n = AppLocalizations.of(context)!;
    final gInt = MaterialLocalizations.of(context);
    return AlertDialog(
      title: Text(i10n.formAccountCreationName),
      scrollable: true,
      content: FormBuilder(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            // Last name
            FormBuilderTextField(
              name: 'first_name',
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: i10n.accountFirstName),
              validator: FormBuilderValidators.required(context),
            ),

            // First name
            FormBuilderTextField(
              name: 'last_name',
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: i10n.accountLastName),
              validator: FormBuilderValidators.required(context),
            ),

            // School
            FormBuilderChoiceChip(
              name: 'school',
              decoration: InputDecoration(
                  labelText: i10n.accountSchool, border: InputBorder.none),
              spacing: 5,
              options: [
                FormBuilderFieldOption(
                  value: CustomerSchool.Ensimag,
                  child: Text(i10n.schoolEnsimag),
                ),
                FormBuilderFieldOption(
                  value: CustomerSchool.Phelma,
                  child: Text(i10n.schoolPhelma),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text(gInt.cancelButtonLabel),
          onPressed: () {
            _formKey.currentState!.reset();
            Navigator.pop(context);
          },
        ),
        TextButton(
          child: Text(gInt.okButtonLabel),
          onPressed: () {
            _formKey.currentState!.save();
            if (_formKey.currentState!.validate()) {
              // Valid
              print(_formKey.currentState!.value);
              Navigator.pop(context);
            } else {
              print('Validation failed');
            }
          },
        ),
      ],
    );
  }
}
