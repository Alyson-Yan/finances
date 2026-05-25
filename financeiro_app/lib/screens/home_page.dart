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

    final ganhos = model.totalGanhosDoMes(mesSelecionado);
    final gastos = model.totalGastosDoMes(mesSelecionado);
    final pago = model.totalPagoDoMes(mesSelecionado);
    final pendenteMes = model.totalPendenteDoMes(mesSelecionado);
    final pendenteTotal = model.totalPendenteAteMes(mesSelecionado);
    final saldoDisponivel = model.saldoAcumuladoDisponivel(mesSelecionado);
    final saldoPrevisto = model.saldoAcumuladoPrevisto(mesSelecionado);
    final saldoDoMes = model.saldoDoMesPrevisto(mesSelecionado);
    final pendencias = model.getPendenciasAteMes(mesSelecionado);
    final categorias = _gastosPorCategoria(model.getTransacoesDoMes(mesSelecionado));

    return Scaffold(
      drawer: const AppDrawer(selectedItem: AppDrawerItem.inicio),
      appBar: AppBar(
        title: const Text('Início'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            _buildHeader(config),
            const SizedBox(height: 14),
            _buildSeletorMes(),
            const SizedBox(height: 14),
            _buildHeroSaldo(
              saldoDisponivel: saldoDisponivel,
              saldoPrevisto: saldoPrevisto,
              saldoDoMes: saldoDoMes,
            ),
            const SizedBox(height: 14),
            _buildGridIndicadores(
              ganhos: ganhos,
              gastos: gastos,
              pago: pago,
              pendenteMes: pendenteMes,
            ),
            const SizedBox(height: 14),
            _buildSaudeFinanceira(
              saldoDisponivel: saldoDisponivel,
              pendenteTotal: pendenteTotal,
            ),
            if (pendencias.isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildPendenciasCard(pendencias, pendenteTotal),
            ],
            const SizedBox(height: 14),
            _buildCategoriaPreview(categorias),
            const SizedBox(height: 14),
            _buildAtalhos(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdicionarTransacaoPage(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader(AppConfigModel config) {
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
          'Veja o estado do seu mês em poucos segundos.',
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                fontSize: 17,
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

  Widget _buildHeroSaldo({
    required double saldoDisponivel,
    required double saldoPrevisto,
    required double saldoDoMes,
  }) {
    final positivo = saldoDisponivel >= 0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.accentBlue,
                ),
              ),
              const Spacer(),
              _buildStatusPill(
                texto: positivo ? 'positivo' : 'atenção',
                cor: positivo ? AppColors.success : AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Saldo disponível',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatarMoeda(saldoDisponivel),
            style: TextStyle(
              color: positivo ? AppColors.textPrimary : AppColors.warning,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Resultado acumulado previsto: ${formatarMoeda(saldoPrevisto)}',
            style: TextStyle(
              color: saldoPrevisto >= 0 ? AppColors.success : AppColors.danger,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Resultado do mês: ${formatarMoeda(saldoDoMes)}',
            style: TextStyle(
              color: saldoDoMes >= 0 ? AppColors.success : AppColors.danger,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridIndicadores({
    required double ganhos,
    required double gastos,
    required double pago,
    required double pendenteMes,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildIndicador(
                titulo: 'Entradas',
                valor: ganhos,
                icon: Icons.trending_up,
                cor: AppColors.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildIndicador(
                titulo: 'Saídas',
                valor: gastos,
                icon: Icons.trending_down,
                cor: AppColors.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildIndicador(
                titulo: 'Pago',
                valor: pago,
                icon: Icons.check_circle_outline,
                cor: AppColors.accentBlue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildIndicador(
                titulo: 'Em aberto',
                valor: pendenteMes,
                icon: Icons.warning_amber_rounded,
                cor: AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIndicador({
    required String titulo,
    required double valor,
    required IconData icon,
    required Color cor,
  }) {
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
          Icon(icon, color: cor, size: 22),
          const SizedBox(height: 12),
          Text(
            titulo,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            formatarMoeda(valor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

  Widget _buildSaudeFinanceira({
    required double saldoDisponivel,
    required double pendenteTotal,
  }) {
    final semPendencia = pendenteTotal <= 0;
    final cobrePendencias = saldoDisponivel >= pendenteTotal;
    final seguro = semPendencia || cobrePendencias;

    final mensagem = semPendencia
        ? 'Sem contas em aberto até este mês.'
        : cobrePendencias
            ? 'Seu dinheiro disponível cobre as contas em aberto.'
            : 'As contas abertas passam do dinheiro disponível.';

    return _buildInfoCard(
      icon: seguro ? Icons.verified_outlined : Icons.error_outline,
      iconColor: seguro ? AppColors.success : AppColors.warning,
      title: 'Saúde financeira',
      subtitle: mensagem,
    );
  }

  Widget _buildPendenciasCard(List<Transacao> pendencias, double pendenteTotal) {
    final principais = pendencias.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${pendencias.length} pendência(s) aberta(s)',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                formatarMoeda(pendenteTotal),
                style: const TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...principais.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      t.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    formatarMoeda(t.valor),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PendenciasPage(mesSelecionado: mesSelecionado),
                  ),
                );
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Ver pendências'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriaPreview(Map<String, double> categorias) {
    if (categorias.isEmpty) {
      return _buildInfoCard(
        icon: Icons.category_outlined,
        iconColor: AppColors.textMuted,
        title: 'Categorias do mês',
        subtitle: 'Nenhum gasto categorizado neste mês.',
      );
    }

    final principais = categorias.entries.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Maiores gastos do mês',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          ...principais.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      e.key,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    formatarMoeda(e.value),
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                Navigator.pushReplacementNamed(context, AppRoutes.relatorioAnual);
              },
              icon: const Icon(Icons.insights_outlined),
              label: const Text('Abrir relatório completo'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAtalhos() {
    return Row(
      children: [
        Expanded(
          child: _buildAtalho(
            icon: Icons.receipt_long_outlined,
            title: 'Lançamentos',
            subtitle: 'Ver lista completa',
            route: AppRoutes.lancamentos,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildAtalho(
            icon: Icons.insights_outlined,
            title: 'Relatórios',
            subtitle: 'Analisar gastos',
            route: AppRoutes.relatorioAnual,
          ),
        ),
      ],
    );
  }

  Widget _buildAtalho({
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => Navigator.pushReplacementNamed(context, route),
      child: Container(
        padding: const EdgeInsets.all(16),
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
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
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

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
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

  Widget _buildStatusPill({
    required String texto,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cor.withValues(alpha: 0.4)),
      ),
      child: Text(
        texto.toUpperCase(),
        style: TextStyle(
          color: cor,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
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
