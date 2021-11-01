import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:sbeereck_app/data/models.dart';

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
    final i10n = AppLocalizations.of(context)!;
    final gInt = MaterialLocalizations.of(context);

    return AlertDialog(
      title: Text(i10n.formAccountCreationName),
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
              decoration: InputDecoration(labelText: i10n.accountFirstName),
              validator: FormBuilderValidators.required(context),
            ),

            // First name
            FormBuilderTextField(
              name: 'lastName',
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: i10n.accountLastName),
              validator: FormBuilderValidators.required(context),
            ),

            // School
            FormBuilderChoiceChip(
              name: 'school',
              decoration: InputDecoration(
                  labelText: i10n.accountSchool, border: InputBorder.none),
              spacing: 3,
              runSpacing: 0,
              options: [
                FormBuilderFieldOption(
                  value: CustomerSchool.ensimag,
                  child: Text(i10n.schoolEnsimag),
                ),
                FormBuilderFieldOption(
                  value: CustomerSchool.phelma,
                  child: Text(i10n.schoolPhelma),
                ),
                FormBuilderFieldOption(
                  value: CustomerSchool.e3,
                  child: Text(i10n.schoolE3),
                ),
                FormBuilderFieldOption(
                  value: CustomerSchool.papet,
                  child: Text(i10n.schoolPapet),
                ),
                FormBuilderFieldOption(
                  value: CustomerSchool.gi,
                  child: Text(i10n.schoolGi),
                ),
                FormBuilderFieldOption(
                  value: CustomerSchool.polytech,
                  child: Text(i10n.schoolPolytech),
                ),
                FormBuilderFieldOption(
                  value: CustomerSchool.esisar,
                  child: Text(i10n.schoolEsisar),
                ),
                FormBuilderFieldOption(
                  value: CustomerSchool.iae,
                  child: Text(i10n.schoolIae),
                ),
                FormBuilderFieldOption(
                  value: CustomerSchool.uga,
                  child: Text(i10n.schoolUga),
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
