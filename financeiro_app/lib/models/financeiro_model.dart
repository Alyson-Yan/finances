import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'transacao.dart';
import 'recorrencia.dart';
import 'categoria.dart';
import 'parcelado.dart';

enum Ordenacao {
  dataMaisRecente,
  dataMaisAntiga,
  valorMaior,
  valorMenor,
  nomeAZ,
  nomeZA,
}

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

void removerItem(String id) {
  if (id.startsWith('parcelado_')) {
    final parceladoId = id.split('_')[1];
    removerParcelado(parceladoId);

  } else if (id.startsWith('fixo_')) {
    final recorrenteId = id.split('_')[1];
    removerRecorrencia(recorrenteId);

  } else if (id.startsWith('saldo_')) {
    // não remove saldo automático

  } else {
    removerTransacao(id);
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
  // caixa de pagamento
  // ================================

void marcarComoPago(String id) {
  final index = transacoes.indexWhere((t) => t.id == id);

  if (index != -1) {
  transacoes[index].pago = !transacoes[index].pago;

  if (transacoes[index].pago) {
    transacoes[index].dataPagamento = DateTime.now();
  } else {
    transacoes[index].dataPagamento = null;
  }

    _salvarDados();
    notifyListeners();
  }
}

// ================================
// MOTOR CENTRAL (MENSAL)
// ================================

List<Transacao> _getTransacoesDoMesBase(DateTime mesSelecionado) {
  List<Transacao> lista = [];

  // Transações normais
  lista.addAll(transacoes.where((t) =>
      t.data.year == mesSelecionado.year &&
      t.data.month == mesSelecionado.month));

  // Parcelados
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

  // Recorrentes
  for (var r in recorrentes) {
    if (mesSelecionado.isAfter(r.dataInicio) ||
        (mesSelecionado.year == r.dataInicio.year &&
            mesSelecionado.month == r.dataInicio.month)) {
      lista.add(
        Transacao(
          id: "fixo_${r.id}_${mesSelecionado.month}_${mesSelecionado.year}",
          nome: "${r.descricao} (${mesSelecionado.month}/${mesSelecionado.year})",
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
List<Transacao> getTransacoesAteMes(DateTime mesSelecionado) {
  List<Transacao> lista = [];

  DateTime cursor = DateTime(2000, 1);

  while (cursor.isBefore(mesSelecionado) ||
      (cursor.year == mesSelecionado.year &&
      cursor.month == mesSelecionado.month)) {

    lista.addAll(_getTransacoesDoMesBase(cursor));

    cursor = DateTime(cursor.year, cursor.month + 1);
  }

  return lista;
}
// 🔥 MÉTODO PRINCIPAL (ESTAVA FALTANDO / QUEBRADO)
List<Transacao> getTransacoesDoMes(DateTime mesSelecionado) {
  List<Transacao> lista = _getTransacoesDoMesBase(mesSelecionado);

  double saldoAnterior = 0;

  final mesAnterior = DateTime(
    mesSelecionado.year,
    mesSelecionado.month - 1,
  );

  final listaAnterior = getTransacoesAteMes(mesAnterior);

  for (var t in listaAnterior) {
    if (t.tipo == 'Ganho') {
      saldoAnterior += t.valor;
    } else {
      saldoAnterior -= t.valor;
    }
  }

  if (saldoAnterior != 0) {
    lista.insert(
      0,
      Transacao(
        id: 'saldo_${mesSelecionado.month}_${mesSelecionado.year}',
        nome: saldoAnterior > 0
            ? 'Saldo anterior (${mesAnterior.month}/${mesAnterior.year})'
            : 'Débito anterior (${mesAnterior.month}/${mesAnterior.year})',
        descricaoDetalhada: 'Gerado automaticamente',
        valor: saldoAnterior.abs(),
        tipo: saldoAnterior > 0 ? 'Ganho' : 'Gasto',
        categoria: 'Sistema',
        data: DateTime(
          mesSelecionado.year,
          mesSelecionado.month,
          1,
        ),
        isAutomatica: true,
      ),
    );
  }

  return lista;
}

// ================================
// CÁLCULOS
// ================================
double totalGanhosDoMes(DateTime mes) =>
    getTransacoesDoMes(mes)
        .where((t) => t.tipo == 'Ganho' && !t.isAutomatica)
        .fold(0.0, (sum, t) => sum + t.valor);

double totalGastosDoMes(DateTime mes) =>
    getTransacoesDoMes(mes)
        .where((t) => t.tipo == 'Gasto' && !t.isAutomatica)
        .fold(0.0, (sum, t) => sum + t.valor);

// mantém para referência (mês isolado)
double saldoDoMes(DateTime mes) =>
    totalGanhosDoMes(mes) - totalGastosDoMes(mes);

// 🔥 NOVO: saldo acumulado com controle de pagamento
double saldoAteMes(DateTime mes) {
  double saldo = 0;

  final limite = DateTime(mes.year, mes.month + 1, 0);

  // 🔥 pega TODAS as transações até o mês
  List<Transacao> todas = [];

  DateTime cursor = DateTime(2000, 1);

  while (cursor.isBefore(limite) ||
      (cursor.year == limite.year && cursor.month == limite.month)) {

    todas.addAll(_getTransacoesDoMesBase(cursor));

    cursor = DateTime(cursor.year, cursor.month + 1);
  }

  for (var t in todas) {
    if (t.tipo == 'Ganho') {
      saldo += t.valor;
    } else {
      saldo -= t.valor;
    }
  }

  return saldo;
}

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

  // ================================
  // FILTRO
  // ================================

List<Transacao> ordenarTransacoes(
  List<Transacao> lista,
  Ordenacao ordenacao,
) {
  List<Transacao> copia = List.from(lista);

  switch (ordenacao) {
    case Ordenacao.dataMaisRecente:
      copia.sort((a, b) => b.data.compareTo(a.data));
      break;

    case Ordenacao.dataMaisAntiga:
      copia.sort((a, b) => a.data.compareTo(b.data));
      break;

    case Ordenacao.valorMaior:
      copia.sort((a, b) => b.valor.compareTo(a.valor));
      break;

    case Ordenacao.valorMenor:
      copia.sort((a, b) => a.valor.compareTo(b.valor));
      break;

    case Ordenacao.nomeAZ:
      copia.sort((a, b) => a.nome.compareTo(b.nome));
      break;

    case Ordenacao.nomeZA:
      copia.sort((a, b) => b.nome.compareTo(a.nome));
      break;
  }

  return copia;
}

List<Transacao> filtrarPorNome(
  List<Transacao> lista,
  String filtro,
) {
  if (filtro.isEmpty) return lista;

  return lista
      .where((t) =>
          t.nome.toLowerCase().contains(filtro.toLowerCase()))
      .toList();
}