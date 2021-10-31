import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import 'package:routemaster/routemaster.dart';

import 'data/providers.dart';
import 'view/home.dart';
import 'view/login.dart';

final _routes = RouteMap(
  onUnknownRoute: (route) => const Redirect('/'),
  routes: {
    '/': (_) => const MaterialPage(child: HomePage()),
  }
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (ctx) {
      final model = ThemeModel();
      model.init();
      return model;
    }),
    ChangeNotifierProvider(create: (ctx) => AuthModel()),
    ChangeNotifierProvider(create: (ctx) => FirestoreDataModel()),
  ], child: const SbeereckApp()));
}

class SbeereckApp extends StatelessWidget {
  const SbeereckApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.select((ThemeModel theme) => theme.theme);
    final loggedIn = context.select((AuthModel auth) => auth.loggedIn);

    return MaterialApp.router(
      title: "S'Beer Eck",
      theme: ThemeData(brightness: theme),
      supportedLocales: const [Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FormBuilderLocalizations.delegate
      ],
      routerDelegate: RoutemasterDelegate(routesBuilder: (ctx) {
        if (!loggedIn) {
          return RouteMap(
              routes: {'/': (_) => const MaterialPage(child: LoginPage())});
        } else {
          return _routes;
        }
      }),
      routeInformationParser: const RoutemasterParser(),
    );
  }
}
