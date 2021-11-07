import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../data/models.dart';

class AccountDetailsForm extends StatefulWidget {
  final void Function(BuildContext, NewCustomerAccount) onSubmit;
  final Map<String, dynamic>? initialValues;

  const AccountDetailsForm(
      {Key? key, required this.onSubmit, this.initialValues})
      : super(key: key);

  @override
  State<AccountDetailsForm> createState() => _AccountDetailsFormState();
}

class _AccountDetailsFormState extends State<AccountDetailsForm> {
  final _formKey = GlobalKey<FormBuilderState>();
  var _lockForm = false;

  void _onFormConfirm(BuildContext context) {
    setState(() {
      _lockForm = true;
    });

    final raw = _formKey.currentState!.value;
    final account = NewCustomerAccount(
        firstName: raw['firstName'],
        lastName: raw['lastName'],
        school: raw['school']);

    // Trigger listener
    Navigator.pop(context);
    widget.onSubmit(context, account);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gInt = MaterialLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.formAccountCreationName),
      scrollable: true,
      content: FormBuilder(
        key: _formKey,
        enabled: !_lockForm,
        initialValue: widget.initialValues ?? {},
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            // Last name
            FormBuilderTextField(
              name: 'firstName',
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.accountFirstName),
              validator: FormBuilderValidators.required(context),
            ),

            // First name
            FormBuilderTextField(
              name: 'lastName',
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.accountLastName),
              validator: FormBuilderValidators.required(context),
            ),

            // School
            FormBuilderChoiceChip(
              name: 'school',
              decoration: InputDecoration(
                  labelText: l10n.accountSchool, border: InputBorder.none),
              spacing: 3,
              runSpacing: 0,
              options: [
                FormBuilderFieldOption(
                  value: CustomerSchool.ensimag,
                  child: Text(l10n.schoolEnsimag),
                ),
                FormBuilderFieldOption(
                  value: CustomerSchool.phelma,
                  child: Text(l10n.schoolPhelma),
                ),
                FormBuilderFieldOption(
                  value: CustomerSchool.e3,
                  child: Text(l10n.schoolE3),
                ),
                FormBuilderFieldOption(
                  value: CustomerSchool.papet,
                  child: Text(l10n.schoolPapet),
                ),
                FormBuilderFieldOption(
                  value: CustomerSchool.gi,
                  child: Text(l10n.schoolGi),
                ),
                FormBuilderFieldOption(
                  value: CustomerSchool.polytech,
                  child: Text(l10n.schoolPolytech),
                ),
                FormBuilderFieldOption(
                  value: CustomerSchool.esisar,
                  child: Text(l10n.schoolEsisar),
                ),
                FormBuilderFieldOption(
                  value: CustomerSchool.iae,
                  child: Text(l10n.schoolIae),
                ),
                FormBuilderFieldOption(
                  value: CustomerSchool.uga,
                  child: Text(l10n.schoolUga),
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
              _onFormConfirm(context);
            }
          },
        ),
      ],
    );
  }
}
