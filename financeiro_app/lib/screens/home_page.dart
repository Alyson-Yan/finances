import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_config_model.dart';
import '../models/financeiro_model.dart';
import '../models/transacao.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../utils/formatadores.dart';
import '../widgets/app_drawer.dart';
import 'adicionar_transacao_page.dart';
import 'pendencias_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

  @override
  Widget build(BuildContext context) {
    final model = context.watch<FinanceiroModel>();
    final config = context.watch<AppConfigModel>();

    final transacoes = model.getTransacoesDoMes(mesSelecionado);
    final ganhos = model.totalGanhosDoMes(mesSelecionado);
    final gastos = model.totalGastosDoMes(mesSelecionado);
    final saldo = model.saldoDoMesPrevisto(mesSelecionado);
    final pago = model.totalPagoDoMes(mesSelecionado);
    final pendenteMes = model.totalPendenteDoMes(mesSelecionado);
    final pendenteAteMes = model.totalPendenteAteMes(mesSelecionado);
    final pendencias = model.getPendenciasAteMes(mesSelecionado);
    final gastosPorCategoria = _gastosPorCategoria(transacoes);

    final ultimos = model.ordenarTransacoes(
      transacoes,
      Ordenacao.dataMaisRecente,
    ).take(5).toList();

    return Scaffold(
      drawer: const AppDrawer(selectedItem: AppDrawerItem.inicio),
      appBar: AppBar(
        title: const Text('Início'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
          children: [
            _buildBoasVindas(config),
            const SizedBox(height: 14),
            _buildSeletorMes(),
            const SizedBox(height: 14),
            _buildResumoPlanilha(
              ganhos: ganhos,
              gastos: gastos,
              saldo: saldo,
              pago: pago,
              pendenteMes: pendenteMes,
            ),
            const SizedBox(height: 14),
            _buildStatusDoMes(saldo, pendenteAteMes),
            const SizedBox(height: 14),
            _buildAcoesRapidas(context),
            const SizedBox(height: 14),
            if (pendencias.isNotEmpty)
              _buildPendenciasCard(
                total: pendenteAteMes,
                quantidade: pendencias.length,
              ),
            if (pendencias.isNotEmpty) const SizedBox(height: 14),
            _buildCategoriasResumo(gastosPorCategoria),
            const SizedBox(height: 14),
            _buildUltimosLancamentos(ultimos),
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

  Widget _buildBoasVindas(AppConfigModel config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          config.saudacao,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Resumo direto do seu mês financeiro.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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

  Widget _buildResumoPlanilha({
    required double ganhos,
    required double gastos,
    required double saldo,
    required double pago,
    required double pendenteMes,
  }) {
    final saldoPositivo = saldo >= 0;
    final corSaldo = saldoPositivo ? AppColors.success : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saldo final estimado',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formatarMoeda(saldo),
            style: TextStyle(
              color: corSaldo,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            saldoPositivo
                ? 'Você está fechando o mês no positivo.'
                : 'Os gastos passaram dos ganhos neste mês.',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildMetricaCompacta(
                  titulo: 'Ganhos',
                  valor: ganhos,
                  cor: AppColors.success,
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricaCompacta(
                  titulo: 'Gastos',
                  valor: gastos,
                  cor: AppColors.danger,
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricaCompacta(
                  titulo: 'Pago',
                  valor: pago,
                  cor: AppColors.primaryBlue,
                  icon: Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricaCompacta(
                  titulo: 'Em aberto',
                  valor: pendenteMes,
                  cor: AppColors.warning,
                  icon: Icons.pending_actions_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricaCompacta({
    required String titulo,
    required double valor,
    required Color cor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: cor, size: 16),
              const SizedBox(width: 6),
              Text(
                titulo,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatarMoeda(valor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: cor,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDoMes(double saldo, double pendenteAteMes) {
    final saldoNegativo = saldo < 0;
    final temPendencia = pendenteAteMes > 0;

    final icon = saldoNegativo || temPendencia
        ? Icons.warning_amber_rounded
        : Icons.verified_outlined;

    final cor = saldoNegativo
        ? AppColors.danger
        : temPendencia
            ? AppColors.warning
            : AppColors.success;

    final titulo = saldoNegativo
        ? 'Atenção no fechamento'
        : temPendencia
            ? 'Existem contas em aberto'
            : 'Mês controlado';

    final mensagem = saldoNegativo
        ? 'Faltam ${formatarMoeda(saldo.abs())} para o mês ficar zerado.'
        : temPendencia
            ? 'Há ${formatarMoeda(pendenteAteMes)} em pendências até este mês.'
            : 'Ganhos, gastos e pendências estão sob controle.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: cor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mensagem,
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

  Widget _buildAcoesRapidas(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildAcaoRapida(
            titulo: 'Lançamentos',
            subtitulo: 'Ver lista completa',
            icon: Icons.receipt_long_outlined,
            onTap: () => Navigator.pushNamed(context, AppRoutes.lancamentos),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildAcaoRapida(
            titulo: 'Relatórios',
            subtitulo: 'Analisar gastos',
            icon: Icons.insights_outlined,
            onTap: () => Navigator.pushNamed(context, AppRoutes.relatorioAnual),
          ),
        ),
      ],
    );
  }

  Widget _buildAcaoRapida({
    required String titulo,
    required String subtitulo,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.accentBlue),
            const SizedBox(height: 12),
            Text(
              titulo,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitulo,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendenciasCard({
    required double total,
    required int quantidade,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PendenciasPage(mesSelecionado: mesSelecionado),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$quantidade pendência(s) abertas',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total em aberto: ${formatarMoeda(total)}',
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriasResumo(Map<String, double> categorias) {
    if (categorias.isEmpty) {
      return const SizedBox.shrink();
    }

    final principais = categorias.entries.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Maiores gastos do mês',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ...principais.map((entry) {
            final maior = principais.first.value;
            final percentual = maior <= 0 ? 0.0 : entry.value / maior;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        formatarMoeda(entry.value),
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: percentual,
                      minHeight: 8,
                      backgroundColor: AppColors.surfaceSoft,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildUltimosLancamentos(List<Transacao> transacoes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Últimos lançamentos',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.lancamentos),
                child: const Text('Ver todos'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (transacoes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  'Nenhum lançamento neste mês.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            ...transacoes.map(_buildLancamentoCompacto),
        ],
      ),
    );
  }

  Widget _buildLancamentoCompacto(Transacao t) {
    final isGasto = t.tipo == 'Gasto';
    final cor = isGasto ? AppColors.danger : AppColors.success;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 38,
            decoration: BoxDecoration(
              color: cor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${t.tipo} · ${t.categoria}',
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
          Text(
            formatarMoeda(t.valor),
            style: TextStyle(
              color: cor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, double> _gastosPorCategoria(List<Transacao> transacoes) {
    final gastos = <String, double>{};

    for (final t in transacoes) {
      if (t.tipo != 'Gasto') continue;
      gastos[t.categoria] = (gastos[t.categoria] ?? 0) + t.valor;
    }

    return Map.fromEntries(
      gastos.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }
}
