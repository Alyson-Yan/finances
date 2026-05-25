import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfigModel extends ChangeNotifier {
  static const String _chaveNomeUsuario = 'nome_usuario';

  final SharedPreferences prefs;

  AppConfigModel(this.prefs) {
    _nomeUsuario = prefs.getString(_chaveNomeUsuario) ?? '';
  }

  String _nomeUsuario = '';

  String get nomeUsuario => _nomeUsuario;

  String get saudacao {
    final nome = _nomeUsuario.trim();

    if (nome.isEmpty) {
      return 'Olá';
    }

    return 'Olá, $nome';
  }

  Future<void> atualizarNomeUsuario(String nome) async {
    _nomeUsuario = nome.trim();
    await prefs.setString(_chaveNomeUsuario, _nomeUsuario);
    notifyListeners();
  }

  Future<void> limparNomeUsuario() async {
    _nomeUsuario = '';
    await prefs.remove(_chaveNomeUsuario);
    notifyListeners();
  }
}
