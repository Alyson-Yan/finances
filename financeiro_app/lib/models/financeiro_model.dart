import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'categoria.dart';
import 'parcelado.dart';
import 'recorrencia.dart';
import 'transacao.dart';

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

  /// Estado operacional de pagamento.
  /// A transação pode ser real ou virtual, mas o pagamento é controlado pelo ID.
  Map<String, bool> pagamentos = {};

  FinanceiroModel(String? savedData) {
    if (savedData == null || savedData.isEmpty) {
      return;
    }

    final decoded = jsonDecode(savedData);

    if (decoded is! Map<String, dynamic>) {
      return;
    }

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

    if (decoded['pagamentos'] != null) {
      pagamentos = Map<String, bool>.from(decoded['pagamentos']);
    }
  }

  // ================================
  // PERSISTÊNCIA
  // ================================

  Future<void> _salvarDados() async {
    final prefs = await SharedPreferences.getInstance();

    final data = {
      'transacoes': transacoes.map((t) => t.toMap()).toList(),
      'recorrentes': recorrentes.map((r) => r.toMap()).toList(),
      'parcelados': parcelados.map((p) => p.toMap()).toList(),
      'categorias': categorias.map((c) => c.toMap()).toList(),
      'pagamentos': pagamentos,
    };

    await prefs.setString('financeiro', jsonEncode(data));
  }

  // ================================
  // TRANSAÇÃO NORMAL
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

    if (index == -1) {
      return;
    }

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

  void removerTransacao(String id) {
    transacoes.removeWhere((t) => t.id == id);
    pagamentos.remove(id);
    _salvarDados();
    notifyListeners();
  }

  // ================================
  // PARCELADO
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

  void removerParcelado(String id) {
    parcelados.removeWhere((p) => p.id == id);
    pagamentos.removeWhere((key, _) => key.startsWith('parcelado_${id}_'));
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

  void removerRecorrencia(String id) {
    recorrentes.removeWhere((r) => r.id == id);
    pagamentos.removeWhere((key, _) => key.startsWith('fixo_${id}_'));
    _salvarDados();
    notifyListeners();
  }

  // ================================
  // REMOÇÃO GENÉRICA
  // ================================

  void removerItem(String id) {
    if (id.startsWith('parcelado_')) {
      final parceladoId = id.split('_')[1];
      removerParcelado(parceladoId);
      return;
    }

    if (id.startsWith('fixo_')) {
      final recorrenteId = id.split('_')[1];
      removerRecorrencia(recorrenteId);
      return;
    }

    removerTransacao(id);
  }

  // ================================
  // PAGAMENTOS
  // ================================

  bool estaPago(String id) {
    return pagamentos[id] ?? false;
  }

  void marcarComoPago(String id) {
    pagamentos[id] = !estaPago(id);

    _salvarDados();
    notifyListeners();
  }

  void marcarListaComoPaga(List<Transacao> lista) {
    for (final t in lista) {
      if (t.tipo == 'Gasto') {
        pagamentos[t.id] = true;
      }
    }

    _salvarDados();
    notifyListeners();
  }

  // ================================
  // MOTOR CENTRAL MENSAL
  // ================================

  List<Transacao> _getTransacoesDoMesBase(DateTime mesSelecionado) {
    final lista = <Transacao>[];

    lista.addAll(
      transacoes.where(
        (t) =>
            t.data.year == mesSelecionado.year &&
            t.data.month == mesSelecionado.month,
      ),
    );

    for (final p in parcelados) {
      final parcelas = p.gerarParcelas();

      for (final parcela in parcelas) {
        if (parcela.data.year == mesSelecionado.year &&
            parcela.data.month == mesSelecionado.month) {
          lista.add(
            Transacao(
              id: 'parcelado_${p.id}_${parcela.numero}',
              nome: '${p.descricao} (${parcela.numero}/${p.totalParcelas})',
              descricaoDetalhada: '',
              valor: parcela.valor,
              tipo: p.tipo == TipoTransacao.ganho ? 'Ganho' : 'Gasto',
              categoria: 'Sem categoria',
              data: parcela.data,
            ),
          );
        }
      }
    }

    for (final r in recorrentes) {
      final iniciouAntesOuNoMes =
          mesSelecionado.year > r.dataInicio.year ||
          (mesSelecionado.year == r.dataInicio.year &&
              mesSelecionado.month >= r.dataInicio.month);

      if (iniciouAntesOuNoMes) {
        lista.add(
          Transacao(
            id: 'fixo_${r.id}_${mesSelecionado.month}_${mesSelecionado.year}',
            nome: '${r.descricao} (${mesSelecionado.month}/${mesSelecionado.year})',
            descricaoDetalhada: '',
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

  List<Transacao> getTransacoesDoMes(DateTime mesSelecionado) {
    return _getTransacoesDoMesBase(mesSelecionado);
  }

  List<Transacao> getTransacoesAteMes(DateTime mesSelecionado) {
    final lista = <Transacao>[];
    var cursor = _primeiroMesComDados();
    final limite = DateTime(mesSelecionado.year, mesSelecionado.month);

    while (_mesMenorOuIgual(cursor, limite)) {
      lista.addAll(_getTransacoesDoMesBase(cursor));
      cursor = DateTime(cursor.year, cursor.month + 1);
    }

    return lista;
  }

  DateTime _primeiroMesComDados() {
    final datas = <DateTime>[
      ...transacoes.map((t) => DateTime(t.data.year, t.data.month)),
      ...recorrentes.map((r) => DateTime(r.dataInicio.year, r.dataInicio.month)),
      ...parcelados.map((p) => DateTime(p.dataInicio.year, p.dataInicio.month)),
    ];

    if (datas.isEmpty) {
      return DateTime(DateTime.now().year, DateTime.now().month);
    }

    datas.sort((a, b) => a.compareTo(b));
    return datas.first;
  }

  bool _mesMenorOuIgual(DateTime a, DateTime b) {
    return a.year < b.year || (a.year == b.year && a.month <= b.month);
  }

  // ================================
  // TOTAIS DO MÊS
  // ================================

  double totalGanhosDoMes(DateTime mes) {
    return getTransacoesDoMes(mes)
        .where((t) => t.tipo == 'Ganho')
        .fold(0.0, (sum, t) => sum + t.valor);
  }

  double totalGastosDoMes(DateTime mes) {
    return getTransacoesDoMes(mes)
        .where((t) => t.tipo == 'Gasto')
        .fold(0.0, (sum, t) => sum + t.valor);
  }

  double totalPagoDoMes(DateTime mes) {
    return getTransacoesDoMes(mes)
        .where((t) => t.tipo == 'Gasto' && estaPago(t.id))
        .fold(0.0, (sum, t) => sum + t.valor);
  }

  double totalPendenteDoMes(DateTime mes) {
    return getTransacoesDoMes(mes)
        .where((t) => t.tipo == 'Gasto' && !estaPago(t.id))
        .fold(0.0, (sum, t) => sum + t.valor);
  }

  // ================================
  // SALDOS
  // ================================

  double saldoDoMesPrevisto(DateTime mes) {
    return totalGanhosDoMes(mes) - totalGastosDoMes(mes);
  }

  double saldoDoMesDisponivel(DateTime mes) {
    return totalGanhosDoMes(mes) - totalPagoDoMes(mes);
  }

  double saldoAcumuladoDisponivel(DateTime mes) {
    return getTransacoesAteMes(mes).fold(0.0, (saldo, t) {
      if (t.tipo == 'Ganho') {
        return saldo + t.valor;
      }

      if (estaPago(t.id)) {
        return saldo - t.valor;
      }

      return saldo;
    });
  }

  double saldoAcumuladoPrevisto(DateTime mes) {
    return getTransacoesAteMes(mes).fold(0.0, (saldo, t) {
      if (t.tipo == 'Ganho') {
        return saldo + t.valor;
      }

      return saldo - t.valor;
    });
  }

  double totalPendenteAteMes(DateTime mes) {
    return getPendenciasAteMes(mes).fold(0.0, (sum, t) => sum + t.valor);
  }

  // Compatibilidade com nomes antigos usados pela UI atual.
  double saldoPrevisto(DateTime mes) => saldoDoMesPrevisto(mes);

  double saldoDisponivel(DateTime mes) => saldoDoMesDisponivel(mes);

  double saldoAteMes(DateTime mes) => saldoAcumuladoDisponivel(mes);

  double saldoDoMes(DateTime mes) => saldoDoMesPrevisto(mes);

  // ================================
  // PENDÊNCIAS
  // ================================

  List<Transacao> getPendenciasAteMes(DateTime mes) {
    final pendencias = getTransacoesAteMes(mes).where((t) {
      return t.tipo == 'Gasto' && !estaPago(t.id);
    }).toList();

    pendencias.sort((a, b) => a.data.compareTo(b.data));
    return pendencias;
  }

  Map<DateTime, List<Transacao>> getPendenciasAgrupadasPorMes(DateTime mes) {
    final grupos = <DateTime, List<Transacao>>{};

    for (final t in getPendenciasAteMes(mes)) {
      final chave = DateTime(t.data.year, t.data.month);
      grupos.putIfAbsent(chave, () => []);
      grupos[chave]!.add(t);
    }

    return grupos;
  }

  double totalPendenciasDoGrupo(List<Transacao> pendencias) {
    return pendencias.fold(0.0, (sum, t) => sum + t.valor);
  }

  // ================================
  // CATEGORIAS
  // ================================

  bool categoriaJaExiste(String nome) {
    return categorias.any((c) => c.nome.toLowerCase() == nome.toLowerCase());
  }

  String? adicionarCategoria(String nome) {
    final nomeLimpo = nome.trim();

    if (nomeLimpo.isEmpty) {
      return 'Digite um nome.';
    }

    if (nomeLimpo.length < 3) {
      return 'Nome muito curto.';
    }

    if (categoriaJaExiste(nomeLimpo)) {
      return 'Já existe.';
    }

    final nova = Categoria(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nome: nomeLimpo,
    );

    categorias.add(nova);
    _salvarDados();
    notifyListeners();

    return null;
  }

  void editarCategoria(String id, String novoNome) {
    final index = categorias.indexWhere((c) => c.id == id);

    if (index == -1 || novoNome.isEmpty) {
      return;
    }

    categorias[index] = Categoria(id: categorias[index].id, nome: novoNome);

    _salvarDados();
    notifyListeners();
  }

  void removerCategoria(String id) {
    categorias.removeWhere((c) => c.id == id);
    _salvarDados();
    notifyListeners();
  }

  // ================================
  // FILTROS / ORDENAÇÃO
  // ================================

  List<Transacao> ordenarTransacoes(List<Transacao> lista, Ordenacao ordenacao) {
    final copia = List<Transacao>.from(lista);

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

  List<Transacao> filtrarPorNome(List<Transacao> lista, String filtro) {
    if (filtro.isEmpty) {
      return lista;
    }

    return lista
        .where((t) => t.nome.toLowerCase().contains(filtro.toLowerCase()))
        .toList();
  }
}
