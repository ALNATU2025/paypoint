import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/routes.dart';
import 'core/theme.dart';
import 'state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(PaypointApp(state: AppState()));
}

class PaypointApp extends StatelessWidget {
  const PaypointApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'Paypoint',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        initialRoute: Routes.splash,
        onGenerateRoute: Routes.onGenerate,
      ),
    );
  }
}
