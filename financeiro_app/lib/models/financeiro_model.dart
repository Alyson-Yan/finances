import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'transacao.dart';
import 'recorrencia.dart';
import 'categoria.dart';
import 'parcelado.dart';

class FinanceiroModel extends ChangeNotifier {
  List<Transacao> transacoes = [];
  List<Recorrencia> recorrentes = [];
  List<Parcelado> parcelados = [];
  List<Categoria> categorias = [];

  FinanceiroModel(String? savedData) {
    if (savedData != null && savedData.isNotEmpty) {
      final decoded = jsonDecode(savedData);

      if (decoded is Map<String, dynamic>) {
        if (decoded['transacoes'] != null) {
          transacoes = (decoded['transacoes'] as List)
              .map((e) => Transacao.fromMap(e))
              .toList();
        }

        if (decoded['recorrentes'] != null) {
          recorrentes = (decoded['recorrentes'] as List)
              .map((e) => Recorrencia.fromMap(e))
              .toList();
        }

        if (decoded['parcelados'] != null) {
          parcelados = (decoded['parcelados'] as List)
              .map((e) => Parcelado.fromMap(e))
              .toList();
        }

        if (decoded['categorias'] != null) {
          categorias = (decoded['categorias'] as List)
              .map((e) => Categoria.fromMap(e))
              .toList();
        }
      }
    }
  }


void editarTransacao({
  required String id,
  required String nome,
  required String descricaoDetalhada,
  required double valor,
  required String tipo,
  required String categoria,
  required DateTime data,
}) {
  final index = transacoes.indexWhere((t) => t.id == id);

  if (index != -1) {
    transacoes[index] = Transacao(
      id: id,
      nome: nome,
      descricaoDetalhada: descricaoDetalhada,
      valor: valor,
      tipo: tipo,
      categoria: categoria,
      data: data,
    );

    _salvarDados();
    notifyListeners();
  }
}

void editarCategoria(String id, String novoNome) {
  final index = categorias.indexWhere((c) => c.id == id);

  if (index != -1 && novoNome.isNotEmpty) {
    categorias[index] = Categoria(
      id: categorias[index].id,
      nome: novoNome,
    );

    _salvarDados();
    notifyListeners();
  }
}

  // ================================
  // SALVAR DADOS
  // ================================
  Future<void> _salvarDados() async {
    final prefs = await SharedPreferences.getInstance();

    final data = {
      'transacoes': transacoes.map((t) => t.toMap()).toList(),
      'recorrentes': recorrentes.map((r) => r.toMap()).toList(),
      'parcelados': parcelados.map((p) => p.toMap()).toList(),
      'categorias': categorias.map((c) => c.toMap()).toList(),
    };

    await prefs.setString('financeiro', jsonEncode(data));
  }

  // ================================
  // TRANSACAO NORMAL
  // ================================
  void adicionarTransacao(
    String nome,
    String descricaoDetalhada,
    double valor,
    String tipo,
    String categoria,
  ) {
    final nova = Transacao(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nome: nome,
      descricaoDetalhada: descricaoDetalhada,
      valor: valor,
      tipo: tipo,
      categoria: categoria,
      data: DateTime.now(),
    );

    transacoes.add(nova);
    _salvarDados();
    notifyListeners();
  }

  // ================================
  // PARCELADO (CORRIGIDO)
  // ================================
  void adicionarParcelado({
    required String nome,
    required String descricaoDetalhada,
    required double valorTotal,
    required TipoTransacao tipo,
    required String categoria,
    required int parcelas,
    required DateTime dataInicial,
  }) {
    final novo = Parcelado(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      descricao: nome,
      valorTotal: valorTotal,
      totalParcelas: parcelas,
      tipo: tipo,
      dataInicio: dataInicial,
    );

    parcelados.add(novo);
    _salvarDados();
    notifyListeners();
  }

  // ================================
  // FIXO MENSAL
  // ================================
  void adicionarFixo({
    required String nome,
    required String descricaoDetalhada,
    required double valor,
    required String tipo,
    required String categoria,
    required DateTime dataInicio,
  }) {
    final nova = Recorrencia(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      descricao: nome,
      valor: valor,
      tipo: tipo,
      categoria: categoria,
      dataInicio: dataInicio,
    );

    recorrentes.add(nova);
    _salvarDados();
    notifyListeners();
  }

  // ================================
  // REMOVER
  // ================================
  void removerTransacao(String id) {
    transacoes.removeWhere((t) => t.id == id);
    _salvarDados();
    notifyListeners();
  }

  void removerRecorrencia(String id) {
    recorrentes.removeWhere((r) => r.id == id);
    _salvarDados();
    notifyListeners();
  }

  void removerParcelado(String id) {
    parcelados.removeWhere((p) => p.id == id);
    _salvarDados();
    notifyListeners();
  }

  // ================================
  // MOTOR CENTRAL (MENSAL)
  // ================================
  List<Transacao> getTransacoesDoMes(DateTime mesSelecionado) {
    List<Transacao> lista = [];

    // 1. Transações normais
    lista.addAll(transacoes.where((t) =>
        t.data.year == mesSelecionado.year &&
        t.data.month == mesSelecionado.month));

    // 2. Parcelados (DINÂMICO)
    for (var p in parcelados) {
      final parcelas = p.gerarParcelas();

      for (var parcela in parcelas) {
        if (parcela.data.year == mesSelecionado.year &&
            parcela.data.month == mesSelecionado.month) {
          lista.add(
            Transacao(
              id: "parcelado_${p.id}_${parcela.numero}",
              nome: "${p.descricao} (${parcela.numero}/${p.totalParcelas})",
              descricaoDetalhada: "",
              valor: parcela.valor,
              tipo: p.tipo == TipoTransacao.ganho ? 'Ganho' : 'Gasto',
              categoria: "Sem categoria",
              data: parcela.data,
            ),
          );
        }
      }
    }

    // 3. Recorrentes
    for (var r in recorrentes) {
      if (mesSelecionado.isAfter(r.dataInicio) ||
          (mesSelecionado.year == r.dataInicio.year &&
              mesSelecionado.month == r.dataInicio.month)) {
        lista.add(
          Transacao(
            id: "fixo_${r.id}_${mesSelecionado.month}_${mesSelecionado.year}",
            nome: "${r.descricao} (Fixo)",
            descricaoDetalhada: "",
            valor: r.valor,
            tipo: r.tipo,
            categoria: r.categoria,
            data: DateTime(
              mesSelecionado.year,
              mesSelecionado.month,
              r.dataInicio.day,
            ),
          ),
        );
      }
    }

    return lista;
  }

  // ================================
  // CÁLCULOS
  // ================================
  double totalGanhosDoMes(DateTime mes) =>
      getTransacoesDoMes(mes)
          .where((t) => t.tipo == 'Ganho')
          .fold(0.0, (sum, t) => sum + t.valor);

  double totalGastosDoMes(DateTime mes) =>
      getTransacoesDoMes(mes)
          .where((t) => t.tipo == 'Gasto')
          .fold(0.0, (sum, t) => sum + t.valor);

  double saldoDoMes(DateTime mes) =>
      totalGanhosDoMes(mes) - totalGastosDoMes(mes);

  // ================================
  // CATEGORIAS
  // ================================
  bool categoriaJaExiste(String nome) {
    return categorias.any(
      (c) => c.nome.toLowerCase() == nome.toLowerCase(),
    );
  }

  String? adicionarCategoria(String nome) {
    final nomeLimpo = nome.trim();

    if (nomeLimpo.isEmpty) return "Digite um nome.";
    if (nomeLimpo.length < 3) return "Nome muito curto.";
    if (categoriaJaExiste(nomeLimpo)) return "Já existe.";

    final nova = Categoria(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nome: nomeLimpo,
    );

    categorias.add(nova);
    _salvarDados();
    notifyListeners();

    return null;
  }

  void removerCategoria(String id) {
    categorias.removeWhere((c) => c.id == id);
    _salvarDados();
    notifyListeners();
  }
}