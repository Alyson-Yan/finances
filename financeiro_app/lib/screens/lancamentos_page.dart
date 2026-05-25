import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/financeiro_model.dart';
import '../models/transacao.dart';
import '../theme/app_theme.dart';
import '../utils/formatadores.dart';
import '../widgets/app_drawer.dart';
import 'adicionar_transacao_page.dart';

enum FiltroLancamentos { todos, abertos, pagos, ganhos, gastos }

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
            child: const Text('Excluir', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmou == true) {
      model.removerItem(t.id);
    }
  }

  void _mostrarDetalhes(Transacao t) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Detalhes da transação'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nome: ${t.nome}'),
            const SizedBox(height: 8),
            Text('Tipo: ${t.tipo}'),
            const SizedBox(height: 8),
            Text('Categoria: ${t.categoria}'),
            const SizedBox(height: 8),
            Text('Valor: ${formatarMoeda(t.valor)}'),
            const SizedBox(height: 8),
            Text('Data: ${mesAnoCurto(t.data)}'),
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

  List<Transacao> _aplicarFiltroStatus(
    FinanceiroModel model,
    List<Transacao> transacoes,
  ) {
    switch (filtroSelecionado) {
      case FiltroLancamentos.abertos:
        return transacoes
            .where((t) => t.tipo == 'Gasto' && !model.estaPago(t.id))
            .toList();
      case FiltroLancamentos.pagos:
        return transacoes
            .where((t) => t.tipo == 'Gasto' && model.estaPago(t.id))
            .toList();
      case FiltroLancamentos.ganhos:
        return transacoes.where((t) => t.tipo == 'Ganho').toList();
      case FiltroLancamentos.gastos:
        return transacoes.where((t) => t.tipo == 'Gasto').toList();
      case FiltroLancamentos.todos:
        return transacoes;
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<FinanceiroModel>();

    List<Transacao> transacoes = model.getTransacoesDoMes(mesSelecionado);
    transacoes = _aplicarFiltroStatus(model, transacoes);
    transacoes = model.filtrarPorNome(transacoes, filtroNome);
    transacoes = model.ordenarTransacoes(transacoes, ordenacaoSelecionada);

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
            MediaQuery.of(context).viewInsets.bottom + 100,
          ),
          children: [
            _buildSeletorMes(),
            const SizedBox(height: 14),
            _buildResumoLista(model),
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

  Widget _buildResumoLista(FinanceiroModel model) {
    final total = model.getTransacoesDoMes(mesSelecionado).length;
    final abertas = model
        .getTransacoesDoMes(mesSelecionado)
        .where((t) => t.tipo == 'Gasto' && !model.estaPago(t.id))
        .length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_outlined, color: AppColors.accentBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$total lançamento(s) no mês',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$abertas gasto(s) ainda em aberto',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
        onSelected: (_) {
          setState(() => filtroSelecionado = filtro);
        },
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
    final podeEditar = !t.id.startsWith('parcelado_') && !t.id.startsWith('fixo_');
    final isGasto = t.tipo == 'Gasto';
    final cor = isGasto ? AppColors.danger : AppColors.success;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _mostrarDetalhes(t),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  t.isAutomatica
                      ? Icons.autorenew
                      : (isGasto ? Icons.trending_down : Icons.trending_up),
                  color: cor,
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
                        fontWeight: FontWeight.w900,
                        decoration: pago ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtituloTransacao(t, pago),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      decoration: pago ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isGasto && !t.isAutomatica)
                        Checkbox(
                          value: pago,
                          onChanged: (_) => model.marcarComoPago(t.id),
                        ),
                      if (!t.isAutomatica)
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'editar' && podeEditar) {
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
                          itemBuilder: (_) => [
                            if (podeEditar)
                              const PopupMenuItem(value: 'editar', child: Text('Editar')),
                            const PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtituloTransacao(Transacao t, bool pago) {
    if (t.tipo == 'Gasto') {
      return '${t.categoria} · ${pago ? 'pago' : 'em aberto'}';
    }

    return t.isAutomatica ? 'Automático' : t.categoria;
  }
}
