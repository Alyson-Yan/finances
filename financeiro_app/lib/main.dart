import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/app_config_model.dart';
import 'models/financeiro_model.dart';
import 'routes/app_routes.dart';
import 'screens/categoria_page.dart';
import 'screens/configuracoes_page.dart';
import 'screens/home_page.dart';
import 'screens/lancamentos_page.dart';
import 'screens/relatorio_anual_page.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final dadosSalvos = prefs.getString('financeiro');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FinanceiroModel(dadosSalvos)),
        ChangeNotifierProvider(create: (_) => AppConfigModel(prefs)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Controle Financeiro',
      theme: AppTheme.darkTheme,
      initialRoute: AppRoutes.inicio,
      routes: {
        AppRoutes.inicio: (_) => const HomePage(),
        AppRoutes.lancamentos: (_) => const LancamentosPage(),
        AppRoutes.relatorioAnual: (_) => const RelatorioAnualPage(),
        AppRoutes.categorias: (_) => const CategoriasPage(),
        AppRoutes.configuracoes: (_) => const ConfiguracoesPage(),
      },
    );
  }
}
