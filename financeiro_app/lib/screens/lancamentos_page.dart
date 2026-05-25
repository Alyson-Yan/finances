import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/financeiro_model.dart';
import '../models/transacao.dart';
import '../theme/app_theme.dart';
import '../utils/formatadores.dart';
import '../widgets/app_drawer.dart';
import 'adicionar_transacao_page.dart';

enum FiltroLancamentos { todos, abertos, pagos, ganhos, gastos, parcelados }

class LancamentosPage extends StatefulWidget {
  const LancamentosPage({super.key});

  @override
  State<LancamentosPage> createState() => _LancamentosPageState();
}

class _LancamentosPageState extends State<LancamentosPage> {
  Ordenacao ordenacaoSelecionada = Ordenacao.dataMaisRecente;
  FiltroLancamentos filtroSelecionado = FiltroLancamentos.todos;
  String filtroNome = '';
  DateTime mesSelecionado = DateTime.now();

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

  Future<void> _confirmarExclusao(FinanceiroModel model, Transacao t) async {
    final removeGrupo = t.id.startsWith('parcelado_') || t.id.startsWith('fixo_');

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir lançamento?'),
        content: Text(
          removeGrupo
              ? 'Isso removerá este lançamento e suas ocorrências relacionadas. Essa ação não pode ser desfeita.'
              : 'Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Excluir',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmou == true) {
      model.removerItem(t.id);
    }
  }

  void _mostrarDetalhes(FinanceiroModel model, Transacao t) {
    final pago = model.estaPago(t.id);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.nome),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetalheLinha('Tipo', t.tipo),
            _buildDetalheLinha('Categoria', t.categoria),
            _buildDetalheLinha('Valor', formatarMoeda(t.valor)),
            _buildDetalheLinha('Data', mesAnoCurto(t.data)),
            _buildDetalheLinha('Parcelamento', _parcelamentoInfo(t)),
            if (t.tipo == 'Gasto')
              _buildDetalheLinha('Status', pago ? 'Pago' : 'Em aberto'),
            const SizedBox(height: 12),
            const Text(
              'Descrição detalhada:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(t.descricaoDetalhada.isEmpty ? 'Sem descrição.' : t.descricaoDetalhada),
          ],
        ),
        actions: [
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
            width: 115,
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

  List<Transacao> _aplicarFiltroStatus(
    FinanceiroModel model,
    List<Transacao> transacoes,
  ) {
    switch (filtroSelecionado) {
      case FiltroLancamentos.abertos:
        return transacoes.where((t) => t.tipo == 'Gasto' && !model.estaPago(t.id)).toList();
      case FiltroLancamentos.pagos:
        return transacoes.where((t) => t.tipo == 'Gasto' && model.estaPago(t.id)).toList();
      case FiltroLancamentos.ganhos:
        return transacoes.where((t) => t.tipo == 'Ganho').toList();
      case FiltroLancamentos.gastos:
        return transacoes.where((t) => t.tipo == 'Gasto').toList();
      case FiltroLancamentos.parcelados:
        return transacoes.where((t) => t.id.startsWith('parcelado_')).toList();
      case FiltroLancamentos.todos:
        return transacoes;
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<FinanceiroModel>();

    final transacoesDoMes = model.getTransacoesDoMes(mesSelecionado);
    List<Transacao> transacoes = _aplicarFiltroStatus(model, transacoesDoMes);
    transacoes = model.filtrarPorNome(transacoes, filtroNome);
    transacoes = model.ordenarTransacoes(transacoes, ordenacaoSelecionada);

    final ganhos = model.totalGanhosDoMes(mesSelecionado);
    final gastos = model.totalGastosDoMes(mesSelecionado);
    final saldo = model.saldoDoMesPrevisto(mesSelecionado);
    final abertas = transacoesDoMes
        .where((t) => t.tipo == 'Gasto' && !model.estaPago(t.id))
        .length;
    final parceladas = transacoesDoMes
        .where((t) => t.id.startsWith('parcelado_'))
        .length;

    return Scaffold(
      drawer: const AppDrawer(selectedItem: AppDrawerItem.lancamentos),
      appBar: AppBar(title: const Text('Lançamentos')),
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            MediaQuery.of(context).viewInsets.bottom + 120,
          ),
          children: [
            _buildSeletorMes(),
            const SizedBox(height: 14),
            _buildResumoPlanilha(
              ganhos: ganhos,
              gastos: gastos,
              saldo: saldo,
              totalLancamentos: transacoesDoMes.length,
              abertas: abertas,
              parceladas: parceladas,
            ),
            const SizedBox(height: 14),
            _buildBusca(),
            const SizedBox(height: 12),
            _buildFiltrosRapidos(),
            const SizedBox(height: 12),
            _buildOrdenacao(),
            const SizedBox(height: 14),
            _buildTituloLista(transacoes.length),
            const SizedBox(height: 10),
            if (transacoes.isEmpty)
              _buildEstadoVazio()
            else
              ...transacoes.map((t) => _buildTransacaoCard(model, t)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdicionarTransacaoPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSeletorMes() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          IconButton(onPressed: mesAnterior, icon: const Icon(Icons.chevron_left)),
          Expanded(
            child: Text(
              nomeMesAno(mesSelecionado),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(onPressed: proximoMes, icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }

  Widget _buildResumoPlanilha({
    required double ganhos,
    required double gastos,
    required double saldo,
    required int totalLancamentos,
    required int abertas,
    required int parceladas,
  }) {
    final corSaldo = saldo >= 0 ? AppColors.success : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumo do mês',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          _buildLinhaResumo('Total de ganhos', ganhos, AppColors.success),
          _buildLinhaResumo('Total de gastos', gastos, AppColors.danger),
          _buildLinhaResumo('Saldo final estimado', saldo, corSaldo),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Row(
              children: [
                Expanded(child: _buildContador('Itens', totalLancamentos.toString())),
                Expanded(child: _buildContador('Abertos', abertas.toString())),
                Expanded(child: _buildContador('Parcelados', parceladas.toString())),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinhaResumo(String label, double valor, Color cor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            formatarMoeda(valor),
            style: TextStyle(
              color: cor,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContador(String label, String valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          valor,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildBusca() {
    return TextField(
      decoration: const InputDecoration(
        labelText: 'Buscar lançamento',
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
          _buildFiltroChip('Todos', FiltroLancamentos.todos),
          _buildFiltroChip('Abertos', FiltroLancamentos.abertos),
          _buildFiltroChip('Pagos', FiltroLancamentos.pagos),
          _buildFiltroChip('Ganhos', FiltroLancamentos.ganhos),
          _buildFiltroChip('Gastos', FiltroLancamentos.gastos),
          _buildFiltroChip('Parcelados', FiltroLancamentos.parcelados),
        ],
      ),
    );
  }

  Widget _buildFiltroChip(String texto, FiltroLancamentos filtro) {
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

  Widget _buildOrdenacao() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Ordenacao>(
          value: ordenacaoSelecionada,
          isExpanded: true,
          dropdownColor: AppColors.surfaceLight,
          onChanged: (value) {
            if (value == null) return;
            setState(() => ordenacaoSelecionada = value);
          },
          items: const [
            DropdownMenuItem(value: Ordenacao.dataMaisRecente, child: Text('Data mais recente')),
            DropdownMenuItem(value: Ordenacao.dataMaisAntiga, child: Text('Data mais antiga')),
            DropdownMenuItem(value: Ordenacao.valorMaior, child: Text('Maior valor')),
            DropdownMenuItem(value: Ordenacao.valorMenor, child: Text('Menor valor')),
            DropdownMenuItem(value: Ordenacao.nomeAZ, child: Text('Nome A-Z')),
            DropdownMenuItem(value: Ordenacao.nomeZA, child: Text('Nome Z-A')),
          ],
        ),
      ),
    );
  }

  Widget _buildTituloLista(int quantidade) {
    return Row(
      children: [
        const Text(
          'Lista do mês',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        Text(
          '$quantidade item(ns)',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildEstadoVazio() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox_outlined, color: AppColors.textMuted, size: 36),
          SizedBox(height: 12),
          Text(
            'Nenhum lançamento encontrado.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransacaoCard(FinanceiroModel model, Transacao t) {
    final pago = model.estaPago(t.id);
    final isGasto = t.tipo == 'Gasto';
    final cor = isGasto ? AppColors.danger : AppColors.success;
    final parcelamento = _parcelamentoInfo(t);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _mostrarDetalhes(model, t),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 10,
                    height: 54,
                    decoration: BoxDecoration(
                      color: cor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: pago ? AppColors.textMuted : AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            decoration: pago ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${t.tipo} · ${t.categoria}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatarMoeda(t.valor),
                        style: TextStyle(
                          color: cor,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          decoration: pago ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      _buildStatusPill(
                        text: isGasto ? (pago ? 'Pago' : 'Aberto') : 'Entrada',
                        color: isGasto ? (pago ? AppColors.success : AppColors.warning) : AppColors.success,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildMiniCampo('Classificação', t.categoria)),
                    Expanded(child: _buildMiniCampo('Parcelado', parcelamento)),
                    if (isGasto && !t.isAutomatica)
                      Checkbox(
                        value: pago,
                        onChanged: (_) => model.marcarComoPago(t.id),
                      ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'editar') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdicionarTransacaoPage(transacao: t),
                            ),
                          );
                          return;
                        }

                        if (value == 'excluir') _confirmarExclusao(model, t);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'editar', child: Text('Editar')),
                        PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniCampo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPill({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  String _parcelamentoInfo(Transacao t) {
    if (t.id.startsWith('fixo_')) return 'Fixo mensal';
    if (!t.id.startsWith('parcelado_')) return 'Não';

    final inicio = t.nome.lastIndexOf('(');
    final fim = t.nome.lastIndexOf(')');

    if (inicio == -1 || fim == -1 || fim <= inicio) return 'Sim';

    return t.nome.substring(inicio + 1, fim);
  }
}
