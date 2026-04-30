import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/financeiro_model.dart';
import 'screens/home_page.dart';

void main() async {
  // Garante a inicialização dos bindings do Flutter
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  
  // Como o seu Model agrupa tudo (transações, categorias, parcelas) 
  // em um único JSON, só precisamos buscar a chave 'financeiro'.
  final dadosSalvos = prefs.getString('financeiro');

  runApp(
    ChangeNotifierProvider(
      // Passamos os dados recuperados para o construtor do Model
      create: (_) => FinanceiroModel(dadosSalvos),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Controle Financeiro',
      home: HomePage(),
    );
  }
}