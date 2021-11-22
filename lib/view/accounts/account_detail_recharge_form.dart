import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class AccountRechargeForm extends StatefulWidget {
  final void Function(num) callback;

  const AccountRechargeForm({Key? key, required this.callback})
      : super(key: key);

  @override
  State<AccountRechargeForm> createState() => _AccountRechargeFormState();
}

class _AccountRechargeFormState extends State<AccountRechargeForm> {
  final _formKey = GlobalKey<FormBuilderState>();
  var _lockForm = false;

  void _onFormConfirm(BuildContext context) {
    setState(() {
      _lockForm = true;
    });

    Navigator.pop(context);
    widget.callback(num.parse(_formKey.currentState!.value['recharge']));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gInt = MaterialLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.accountRechargeTitle),
      content: FormBuilder(
        key: _formKey,
        enabled: !_lockForm,
        autovalidateMode: AutovalidateMode.disabled,
        child: FormBuilderTextField(
          name: 'recharge',
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l10n.accountRechargeField),
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(context),
            FormBuilderValidators.numeric(context),
          ]),
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
