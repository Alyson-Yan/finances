import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/financeiro_model.dart';
import '../models/transacao.dart';
import '../theme/app_theme.dart';
import '../utils/formatadores.dart';
import '../widgets/app_drawer.dart';
import 'adicionar_transacao_page.dart';

enum FiltroPlanilha { todos, abertos, pagos, ganhos, gastos, parcelados }

class PlanilhaPage extends StatefulWidget {
  const PlanilhaPage({super.key});

  @override
  State<PlanilhaPage> createState() => _PlanilhaPageState();
}

class _PlanilhaPageState extends State<PlanilhaPage> {
  DateTime mesSelecionado = DateTime.now();
  FiltroPlanilha filtroSelecionado = FiltroPlanilha.todos;
  String filtroNome = '';

  void mesAnterior() {
    setState(() {
      mesSelecionado = DateTime(mesSelecionado.year, mesSelecionado.month - 1);
    });
  }

  void proximoMes() {
    setState(() {
      mesSelecionado = DateTime(mesSelecionado.year, mesSelecionado.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<FinanceiroModel>();

    final transacoesDoMes = model.getTransacoesDoMes(mesSelecionado);
    var transacoes = _aplicarFiltro(model, transacoesDoMes);
    transacoes = model.filtrarPorNome(transacoes, filtroNome);
    transacoes = model.ordenarTransacoes(transacoes, Ordenacao.valorMaior);

    final ganhos = model.totalGanhosDoMes(mesSelecionado);
    final gastos = model.totalGastosDoMes(mesSelecionado);
    final pago = model.totalPagoDoMes(mesSelecionado);
    final pendente = model.totalPendenteDoMes(mesSelecionado);

    return Scaffold(
      drawer: const AppDrawer(selectedItem: AppDrawerItem.planilha),
      appBar: AppBar(
        title: const Text('Planilha'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            8,
            6,
            8,
            MediaQuery.of(context).viewInsets.bottom > 0 ? 6 : 10,
          ),
          child: Column(
            children: [
              _buildPainelSuperior(
                quantidade: transacoesDoMes.length,
                ganhos: ganhos,
                gastos: gastos,
                pago: pago,
                pendente: pendente,
              ),
              const SizedBox(height: 8),
              Expanded(child: _buildTabelaAutoAjustavel(model, transacoes)),
            ],
          ),
        ),
      ),
    );
  }

  List<Transacao> _aplicarFiltro(
    FinanceiroModel model,
    List<Transacao> transacoes,
  ) {
    switch (filtroSelecionado) {
      case FiltroPlanilha.abertos:
        return transacoes
            .where((t) => t.tipo == 'Gasto' && !model.estaPago(t.id))
            .toList();
      case FiltroPlanilha.pagos:
        return transacoes
            .where((t) => t.tipo == 'Gasto' && model.estaPago(t.id))
            .toList();
      case FiltroPlanilha.ganhos:
        return transacoes.where((t) => t.tipo == 'Ganho').toList();
      case FiltroPlanilha.gastos:
        return transacoes.where((t) => t.tipo == 'Gasto').toList();
      case FiltroPlanilha.parcelados:
        return transacoes.where((t) => t.id.startsWith('parcelado_')).toList();
      case FiltroPlanilha.todos:
        return transacoes;
    }
  }

  Widget _buildPainelSuperior({
    required int quantidade,
    required double ganhos,
    required double gastos,
    required double pago,
    required double pendente,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: mesAnterior,
                  icon: const Icon(Icons.chevron_left),
                ),
              ),
              Expanded(
                child: Text(
                  nomeMesAno(mesSelecionado),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: proximoMes,
                  icon: const Icon(Icons.chevron_right),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(width: 128, child: _buildFiltroDropdown()),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 42,
            child: TextField(
              decoration: const InputDecoration(
                isDense: true,
                labelText: 'Buscar',
                prefixIcon: Icon(Icons.search, size: 18),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
              onChanged: (value) => setState(() => filtroNome = value),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildResumoMini('Itens', quantidade.toString(), AppColors.textPrimary)),
              Expanded(child: _buildResumoMini('Ganhos', formatarMoeda(ganhos), AppColors.success)),
              Expanded(child: _buildResumoMini('Gastos', formatarMoeda(gastos), AppColors.danger)),
              Expanded(child: _buildResumoMini('Pago', formatarMoeda(pago), AppColors.primaryBlue)),
              Expanded(child: _buildResumoMini('Aberto', formatarMoeda(pendente), AppColors.warning)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroDropdown() {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<FiltroPlanilha>(
          value: filtroSelecionado,
          isExpanded: true,
          iconSize: 18,
          dropdownColor: AppColors.surfaceLight,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
          onChanged: (value) {
            if (value == null) return;
            setState(() => filtroSelecionado = value);
          },
          items: FiltroPlanilha.values.map((filtro) {
            return DropdownMenuItem(
              value: filtro,
              child: Text(_textoFiltro(filtro), overflow: TextOverflow.ellipsis),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildResumoMini(String label, String valor, Color cor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                valor,
                maxLines: 1,
                style: TextStyle(
                  color: cor,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabelaAutoAjustavel(
    FinanceiroModel model,
    List<Transacao> transacoes,
  ) {
    if (transacoes.isEmpty) return _buildEstadoVazio();

    return LayoutBuilder(
      builder: (context, constraints) {
        final larguraTotal = constraints.maxWidth;
        final alturaTotal = constraints.maxHeight <= 0 ? 1.0 : constraints.maxHeight;
        final totalLinhas = transacoes.length + 1;
        final alturaLinha = (alturaTotal / totalLinhas).clamp(2.0, 42.0).toDouble();
        final fonte = (alturaLinha * 0.34).clamp(4.0, 12.0).toDouble();
        final fonteCabecalho = (fonte + 0.5).clamp(4.0, 12.0).toDouble();
        final larguras = _calcularLarguras(larguraTotal);

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: larguraTotal,
            height: alturaTotal,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildCabecalhoCelula('Desc', larguras[0], alturaLinha, fonteCabecalho),
                    _buildCabecalhoCelula('Tipo', larguras[1], alturaLinha, fonteCabecalho),
                    _buildCabecalhoCelula('Valor', larguras[2], alturaLinha, fonteCabecalho),
                    _buildCabecalhoCelula('Classe', larguras[3], alturaLinha, fonteCabecalho),
                    _buildCabecalhoCelula('Parc', larguras[4], alturaLinha, fonteCabecalho),
                    _buildCabecalhoCelula('Qtd', larguras[5], alturaLinha, fonteCabecalho),
                    _buildCabecalhoCelula('Atual', larguras[6], alturaLinha, fonteCabecalho),
                    _buildCabecalhoCelula('Status', larguras[7], alturaLinha, fonteCabecalho),
                  ],
                ),
                ...transacoes.map((t) {
                  return _buildLinhaTabela(
                    model: model,
                    t: t,
                    larguras: larguras,
                    alturaLinha: alturaLinha,
                    fonte: fonte,
                  );
                }),
                if ((totalLinhas * alturaLinha) < alturaTotal)
                  Expanded(
                    child: Container(color: AppColors.surface),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<double> _calcularLarguras(double larguraTotal) {
    final desc = larguraTotal * 0.22;
    final tipo = larguraTotal * 0.10;
    final valor = larguraTotal * 0.14;
    final classe = larguraTotal * 0.18;
    final parcelado = larguraTotal * 0.10;
    final qtd = larguraTotal * 0.09;
    final atual = larguraTotal * 0.09;
    final usados = desc + tipo + valor + classe + parcelado + qtd + atual;
    final status = larguraTotal - usados;

    return [desc, tipo, valor, classe, parcelado, qtd, atual, status];
  }

  Widget _buildCabecalhoCelula(
    String texto,
    double width,
    double height,
    double fontSize,
  ) {
    return _buildCelula(
      texto: texto,
      width: width,
      height: height,
      background: const Color(0xFF050506),
      textColor: AppColors.textPrimary,
      fontSize: fontSize,
      bold: true,
    );
  }

  Widget _buildLinhaTabela({
    required FinanceiroModel model,
    required Transacao t,
    required List<double> larguras,
    required double alturaLinha,
    required double fonte,
  }) {
    final isGasto = t.tipo == 'Gasto';
    final isGanho = t.tipo == 'Ganho';
    final pago = isGasto && model.estaPago(t.id);
    final parcelas = _parcelas(t);
    final corTipo = isGanho ? AppColors.success : AppColors.danger;
    final status = isGanho ? 'Entrada' : (pago ? 'Pago' : 'Aberto');

    return GestureDetector(
      onTap: () => _mostrarDetalhes(model, t),
      child: Row(
        children: [
          _buildCelula(
            texto: _nomeLimpo(t),
            width: larguras[0],
            height: alturaLinha,
            background: AppColors.surface,
            textColor: AppColors.textPrimary,
            fontSize: fonte,
            alignment: Alignment.centerLeft,
          ),
          _buildCelula(
            texto: t.tipo,
            width: larguras[1],
            height: alturaLinha,
            background: corTipo,
            textColor: Colors.white,
            fontSize: fonte,
            bold: true,
          ),
          _buildCelula(
            texto: formatarMoeda(t.valor),
            width: larguras[2],
            height: alturaLinha,
            background: pago ? AppColors.primaryBlue : AppColors.surfaceSoft,
            textColor: pago ? Colors.white : AppColors.textPrimary,
            fontSize: fonte,
            bold: pago,
            onTap: isGasto ? () => model.marcarComoPago(t.id) : null,
          ),
          _buildCelula(
            texto: t.categoria,
            width: larguras[3],
            height: alturaLinha,
            background: AppColors.surface,
            textColor: AppColors.textPrimary,
            fontSize: fonte,
          ),
          _buildCelula(
            texto: _parcelamentoInfo(t),
            width: larguras[4],
            height: alturaLinha,
            background: AppColors.surface,
            textColor: AppColors.textPrimary,
            fontSize: fonte,
          ),
          _buildCelula(
            texto: parcelas.total.toString(),
            width: larguras[5],
            height: alturaLinha,
            background: AppColors.surface,
            textColor: AppColors.textPrimary,
            fontSize: fonte,
          ),
          _buildCelula(
            texto: parcelas.atual.toString(),
            width: larguras[6],
            height: alturaLinha,
            background: pago ? AppColors.primaryBlue : AppColors.surface,
            textColor: pago ? Colors.white : AppColors.textPrimary,
            fontSize: fonte,
            bold: pago,
          ),
          _buildCelula(
            texto: status,
            width: larguras[7],
            height: alturaLinha,
            background: isGanho
                ? AppColors.success.withValues(alpha: 0.18)
                : (pago ? AppColors.primaryBlue : AppColors.surfaceSoft),
            textColor: isGanho
                ? AppColors.success
                : (pago ? Colors.white : AppColors.warning),
            fontSize: fonte,
            bold: true,
            onTap: isGasto ? () => model.marcarComoPago(t.id) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCelula({
    required String texto,
    required double width,
    required double height,
    required Color background,
    required Color textColor,
    required double fontSize,
    bool bold = false,
    Alignment alignment = Alignment.center,
    VoidCallback? onTap,
  }) {
    final paddingHorizontal = (height * 0.18).clamp(1.0, 6.0).toDouble();

    final child = Container(
      width: width,
      height: height,
      alignment: alignment,
      padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: AppColors.borderSoft, width: 0.6),
      ),
      child: Align(
        alignment: alignment,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignment,
          child: Text(
            texto,
            maxLines: 1,
            textAlign: alignment == Alignment.centerLeft ? TextAlign.left : TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
      ),
    );

    if (onTap == null) return child;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
    );
  }

  Widget _buildEstadoVazio() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.table_rows_outlined, color: AppColors.textMuted, size: 36),
          SizedBox(height: 12),
          Text(
            'Nenhum lançamento encontrado nesse filtro.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDetalhes(FinanceiroModel model, Transacao t) {
    final isGasto = t.tipo == 'Gasto';
    final pago = isGasto && model.estaPago(t.id);
    final parcelas = _parcelas(t);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_nomeLimpo(t)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetalheLinha('Tipo', t.tipo),
            _buildDetalheLinha('Categoria', t.categoria),
            _buildDetalheLinha('Valor', formatarMoeda(t.valor)),
            _buildDetalheLinha('Data', mesAnoCurto(t.data)),
            _buildDetalheLinha('Parcelado', _parcelamentoInfo(t)),
            _buildDetalheLinha('Qtd parcelas', parcelas.total.toString()),
            _buildDetalheLinha('Parcela atual', parcelas.atual.toString()),
            if (isGasto) _buildDetalheLinha('Status', pago ? 'Pago' : 'Aberto'),
            const SizedBox(height: 12),
            const Text(
              'Descrição detalhada:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              t.descricaoDetalhada.isEmpty ? 'Sem descrição.' : t.descricaoDetalhada,
            ),
          ],
        ),
        actions: [
          if (isGasto)
            TextButton(
              onPressed: () {
                model.marcarComoPago(t.id);
                Navigator.pop(context);
              },
              child: Text(pago ? 'Marcar aberto' : 'Marcar pago'),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdicionarTransacaoPage(transacao: t),
                ),
              );
            },
            child: const Text('Editar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalheLinha(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  String _textoFiltro(FiltroPlanilha filtro) {
    switch (filtro) {
      case FiltroPlanilha.todos:
        return 'Todos';
      case FiltroPlanilha.abertos:
        return 'Abertos';
      case FiltroPlanilha.pagos:
        return 'Pagos';
      case FiltroPlanilha.ganhos:
        return 'Ganhos';
      case FiltroPlanilha.gastos:
        return 'Gastos';
      case FiltroPlanilha.parcelados:
        return 'Parcelados';
    }
  }

  String _nomeLimpo(Transacao t) {
    if (!t.id.startsWith('parcelado_') && !t.id.startsWith('fixo_')) return t.nome;
    return t.nome.replaceFirst(RegExp(r'\s*\(\d{1,2}/\d{1,4}\)$'), '');
  }

  String _parcelamentoInfo(Transacao t) {
    if (t.id.startsWith('fixo_')) return 'Fixo';
    if (t.id.startsWith('parcelado_')) return 'Sim';
    return 'Não';
  }

  _InfoParcelas _parcelas(Transacao t) {
    if (!t.id.startsWith('parcelado_')) return const _InfoParcelas(atual: 0, total: 0);

    final match = RegExp(r'\((\d+)/(\d+)\)$').firstMatch(t.nome);
    if (match == null) return const _InfoParcelas(atual: 0, total: 0);

    return _InfoParcelas(
      atual: int.tryParse(match.group(1) ?? '') ?? 0,
      total: int.tryParse(match.group(2) ?? '') ?? 0,
    );
  }
}

class _InfoParcelas {
  final int atual;
  final int total;

  const _InfoParcelas({required this.atual, required this.total});
}
