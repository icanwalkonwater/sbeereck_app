import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:mdi/mdi.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/providers.dart';
import '../utils.dart';

class OrderPage extends StatelessWidget {
  final String id;

  const OrderPage({Key? key, required this.id}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final account =
        context.select((FirestoreDataModel model) => model.accountById(id));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.orderFormTitle),
        actions: [
          Consumer<ThemeModel>(
              builder: (ctx, model, w) => IconButton(
                  icon: const Icon(Mdi.brightness6),
                  onPressed: () async => await model.switchTheme()))
        ],
      ),
      body: SingleChildScrollView(child: OrderForm(account: account)),
    );
  }
}

class OrderForm extends StatefulWidget {
  final CustomerAccount account;

  const OrderForm({Key? key, required this.account}) : super(key: key);

  @override
  _OrderFormState createState() => _OrderFormState();
}

class _OrderFormState extends State<OrderForm> {
  final _formKey = GlobalKey<FormBuilderState>();

  Beer? get _beer => _formKey.currentState?.value['beer'];

  BeerTypeAddon? get _addon => _formKey.currentState?.value['addon'];

  int get _qty => _formKey.currentState?.value['quantity'] ?? 1;

  // Extra ugly
  void _invalidateWidget() {
    _formKey.currentState?.save();
    setState(() {});
  }

  void _onSubmit(FirestoreDataModel model, int total) async {
    final beer = _beer!;
    final transaction = EventTransactionDrink.blueprint(widget.account, beer,
        _addon != null ? [_addon!.id] : [], _qty, total, model.currentStaff);

    await model.handleTransaction(widget.account, transaction);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    log('Rebuild order form');
    // Only react to changes on beers
    final model = context.read<FirestoreDataModel>();
    final beers = context
        .select((FirestoreDataModel model) => model.beers)
        .where((b) => b.available);

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Bit ugly but hey
    final beerType = _beer?.typeCached(model);
    final total = ((beerType?.price ?? 0) * _qty) + (_addon?.price ?? 0);

    return FormBuilder(
        key: _formKey,
        autovalidateMode: AutovalidateMode.always,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildBeerField(context, l10n, beers, theme, model),
          ),
          if (beerType?.addons.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildAddonField(l10n, beerType),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildQuantityField(theme, l10n),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _formKey.currentState?.validate() ?? false
                    ? () => _onSubmit(model, total)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          l10n.orderFormTotal.replaceFirst(
                              '%total', moneyFormatter.format(total / 100)),
                          style: theme.textTheme.headline5),
                      const Icon(
                        Mdi.chevronRightCircle,
                        size: 32.0,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ]));
  }

  FormBuilderField<Beer> _buildBeerField(
      BuildContext context,
      AppLocalizations l10n,
      Iterable<Beer> beers,
      ThemeData theme,
      FirestoreDataModel model) {
    return FormBuilderField<Beer>(
      name: 'beer',
      validator: FormBuilderValidators.required(context),
      onChanged: (_) => _invalidateWidget(),
      builder: (field) => InputDecorator(
        decoration: InputDecoration(
            border: InputBorder.none, labelText: l10n.orderFormChooseBeer),
        child: Column(
          children: beers
              .map((beer) => _buildBeerItem(theme, beer, beer.typeCached(model),
                      field.value?.id == beer.id, () {
                    field.didChange(beer);
                    _formKey.currentState!.patchValue({'addon': null});
                  }))
              .toList(growable: false),
        ),
      ),
    );
  }

  Card _buildBeerItem(ThemeData theme, Beer beer, BeerType type, bool selected,
      GestureTapCallback onTap) {
    final color = theme.colorScheme.primary;
    return Card(
      elevation: selected ? 5.0 : null,
      color: selected ? color : null,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          foregroundImage:
              beer.image != null ? AssetImage(beer.assetFile!) : null,
          child: beer.image == null ? Text(beer.name[0].toUpperCase()) : null,
        ),
        title: Text(beer.name),
        subtitle: Align(
          alignment: Alignment.centerLeft,
          child: Chip(
              label: Text(
                  '${type.name} ${moneyFormatter.format(type.priceReal)}')),
        ),
        isThreeLine: true,
      ),
    );
  }

  FormBuilderChoiceChip<BeerTypeAddon> _buildAddonField(
      AppLocalizations l10n, BeerType? beerType) {
    return FormBuilderChoiceChip(
        name: 'addon',
        decoration: InputDecoration(
            labelText: l10n.orderFormChooseAddon, border: InputBorder.none),
        onChanged: (_) => _invalidateWidget(),
        options: beerType!.addons
            .map((e) => FormBuilderFieldOption(
                value: e,
                child:
                    Text('${e.name} +${moneyFormatter.format(e.priceReal)}')))
            .toList());
  }

  FormBuilderField<int> _buildQuantityField(
      ThemeData theme, AppLocalizations l10n) {
    return FormBuilderField<int>(
      name: 'quantity',
      initialValue: _qty,
      onChanged: (_) => _invalidateWidget(),
      builder: (field) => InputDecorator(
        decoration: InputDecoration(
            border: InputBorder.none, labelText: l10n.orderFormChooseQuantity),
        child: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Expanded(
                  child: _makeQuantityItem(
                      field, theme, Mdi.beer, l10n.orderFormQuantityOne, 1)),
              const SizedBox(
                width: 8.0,
              ),
              Expanded(
                  child: _makeQuantityItem(field, theme, Mdi.glassMug,
                      l10n.orderFormQuantityTwo, 2)),
            ],
          ),
        ),
      ),
    );
  }

  ElevatedButton _makeQuantityItem(FormFieldState<int?> field, ThemeData theme,
      IconData icon, String text, int value) {
    final style = ElevatedButton.styleFrom(
        primary: theme.colorScheme.surface,
        onPrimary: theme.colorScheme.onSurface);
    return ElevatedButton(
        onPressed: () => field.didChange(value),
        style: field.value != value ? style : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            children: [
              Icon(icon, size: 64.0),
              Text(text),
            ],
          ),
        ));
  }
}
