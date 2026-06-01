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
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            14,
            8,
            14,
            MediaQuery.of(context).viewInsets.bottom + 110,
          ),
          children: [
            _buildCabecalho(),
            const SizedBox(height: 14),
            _buildSeletorMes(),
            const SizedBox(height: 14),
            _buildResumo(
              ganhos: ganhos,
              gastos: gastos,
              pago: pago,
              pendente: pendente,
              quantidade: transacoesDoMes.length,
            ),
            const SizedBox(height: 14),
            _buildLegenda(),
            const SizedBox(height: 14),
            _buildBusca(),
            const SizedBox(height: 12),
            _buildFiltrosRapidos(),
            const SizedBox(height: 14),
            _buildTabela(model, transacoes),
          ],
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

  Widget _buildCabecalho() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Modo planilha',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Visualização em bloquinhos coloridos, parecida com sua planilha original.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Toque em um gasto para abrir detalhes. Toque no valor ou no status para alternar entre aberto e pago.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeletorMes() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: mesAnterior,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              nomeMesAno(mesSelecionado),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            onPressed: proximoMes,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildResumo({
    required double ganhos,
    required double gastos,
    required double pago,
    required double pendente,
    required int quantidade,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(child: _buildResumoItem('Itens', quantidade.toString(), AppColors.textPrimary)),
          Expanded(child: _buildResumoItem('Ganhos', formatarMoeda(ganhos), AppColors.success)),
          Expanded(child: _buildResumoItem('Gastos', formatarMoeda(gastos), AppColors.danger)),
          Expanded(child: _buildResumoItem('Pago', formatarMoeda(pago), AppColors.primaryBlue)),
          Expanded(child: _buildResumoItem('Aberto', formatarMoeda(pendente), AppColors.warning)),
        ],
      ),
    );
  }

  Widget _buildResumoItem(String label, String valor, Color cor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: cor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegenda() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: const [
          _LegendaItem(texto: 'Ganho', cor: AppColors.success),
          _LegendaItem(texto: 'Gasto', cor: AppColors.danger),
          _LegendaItem(texto: 'Pago', cor: AppColors.primaryBlue),
          _LegendaItem(texto: 'Aberto', cor: AppColors.surfaceSoft),
        ],
      ),
    );
  }

  Widget _buildBusca() {
    return TextField(
      decoration: const InputDecoration(
        labelText: 'Buscar na planilha',
        prefixIcon: Icon(Icons.search),
      ),
      onChanged: (value) => setState(() => filtroNome = value),
    );
  }

  Widget _buildFiltrosRapidos() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFiltroChip('Todos', FiltroPlanilha.todos),
          _buildFiltroChip('Abertos', FiltroPlanilha.abertos),
          _buildFiltroChip('Pagos', FiltroPlanilha.pagos),
          _buildFiltroChip('Ganhos', FiltroPlanilha.ganhos),
          _buildFiltroChip('Gastos', FiltroPlanilha.gastos),
          _buildFiltroChip('Parcelados', FiltroPlanilha.parcelados),
        ],
      ),
    );
  }

  Widget _buildFiltroChip(String texto, FiltroPlanilha filtro) {
    final selecionado = filtroSelecionado == filtro;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selecionado,
        label: Text(texto),
        selectedColor: AppColors.primaryBlue.withValues(alpha: 0.22),
        backgroundColor: AppColors.surface,
        side: BorderSide(
          color: selecionado ? AppColors.accentBlue : AppColors.border,
        ),
        labelStyle: TextStyle(
          color: selecionado ? AppColors.textPrimary : AppColors.textSecondary,
          fontWeight: FontWeight.w800,
        ),
        onSelected: (_) => setState(() => filtroSelecionado = filtro),
      ),
    );
  }

  Widget _buildTabela(FinanceiroModel model, List<Transacao> transacoes) {
    if (transacoes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(18),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildCabecalhoCelula('Descrição', 150),
                  _buildCabecalhoCelula('Tipo', 94),
                  _buildCabecalhoCelula('Valor', 112),
                  _buildCabecalhoCelula('Classificação', 140),
                  _buildCabecalhoCelula('Parcelado', 100),
                  _buildCabecalhoCelula('Qtd Parcelas', 112),
                  _buildCabecalhoCelula('Parcela Atual', 112),
                  _buildCabecalhoCelula('Status', 98),
                ],
              ),
              ...transacoes.map((t) => _buildLinhaTabela(model, t)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinhaTabela(FinanceiroModel model, Transacao t) {
    final isGasto = t.tipo == 'Gasto';
    final isGanho = t.tipo == 'Ganho';
    final pago = isGasto && model.estaPago(t.id);
    final parcelamento = _parcelamentoInfo(t);
    final parcelas = _parcelas(t);
    final corTipo = isGanho ? AppColors.success : AppColors.danger;
    final corValor = pago ? AppColors.primaryBlue : AppColors.surfaceSoft;
    final status = isGanho ? 'Entrada' : (pago ? 'Pago' : 'Aberto');

    return InkWell(
      onTap: () => _mostrarDetalhes(model, t),
      child: Row(
        children: [
          _buildCelula(
            _nomeLimpo(t),
            150,
            background: AppColors.surface,
            textColor: AppColors.textPrimary,
            alignment: Alignment.centerLeft,
          ),
          _buildCelula(
            t.tipo,
            94,
            background: corTipo,
            textColor: Colors.white,
            bold: true,
          ),
          _buildCelula(
            formatarMoeda(t.valor),
            112,
            background: corValor,
            textColor: pago ? Colors.white : AppColors.textPrimary,
            bold: pago,
            onTap: isGasto ? () => model.marcarComoPago(t.id) : null,
          ),
          _buildCelula(
            t.categoria,
            140,
            background: AppColors.surface,
            textColor: AppColors.textPrimary,
          ),
          _buildCelula(
            parcelamento,
            100,
            background: AppColors.surface,
            textColor: AppColors.textPrimary,
          ),
          _buildCelula(
            parcelas.total.toString(),
            112,
            background: AppColors.surface,
            textColor: AppColors.textPrimary,
          ),
          _buildCelula(
            parcelas.atual.toString(),
            112,
            background: pago ? AppColors.primaryBlue : AppColors.surface,
            textColor: pago ? Colors.white : AppColors.textPrimary,
            bold: pago,
          ),
          _buildCelula(
            status,
            98,
            background: isGanho
                ? AppColors.success.withValues(alpha: 0.18)
                : (pago ? AppColors.primaryBlue : AppColors.surfaceSoft),
            textColor: isGanho
                ? AppColors.success
                : (pago ? Colors.white : AppColors.warning),
            bold: true,
            onTap: isGasto ? () => model.marcarComoPago(t.id) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCabecalhoCelula(String texto, double width) {
    return _buildCelula(
      texto,
      width,
      height: 38,
      background: const Color(0xFF050506),
      textColor: AppColors.textPrimary,
      bold: true,
    );
  }

  Widget _buildCelula(
    String texto,
    double width, {
    double height = 42,
    required Color background,
    required Color textColor,
    bool bold = false,
    Alignment alignment = Alignment.center,
    VoidCallback? onTap,
  }) {
    final child = Container(
      width: width,
      height: height,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: AppColors.borderSoft, width: 0.65),
      ),
      child: Text(
        texto,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: alignment == Alignment.centerLeft ? TextAlign.left : TextAlign.center,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
        ),
      ),
    );

    if (onTap == null) return child;

    return InkWell(
      onTap: onTap,
      child: child,
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

class _LegendaItem extends StatelessWidget {
  final String texto;
  final Color cor;

  const _LegendaItem({
    required this.texto,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cor == AppColors.surfaceSoft ? cor : cor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: cor == AppColors.surfaceSoft ? AppColors.border : cor.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(
              color: cor == AppColors.surfaceSoft ? AppColors.textSecondary : cor,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoParcelas {
  final int atual;
  final int total;

  const _InfoParcelas({required this.atual, required this.total});
}
