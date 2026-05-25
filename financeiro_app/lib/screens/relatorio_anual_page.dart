import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/financeiro_model.dart';
import '../models/transacao.dart';
import '../theme/app_theme.dart';
import '../utils/formatadores.dart';
import '../widgets/app_drawer.dart';

class RelatorioAnualPage extends StatefulWidget {
  const RelatorioAnualPage({super.key});

  @override
  State<RelatorioAnualPage> createState() => _RelatorioAnualPageState();
}

class _RelatorioAnualPageState extends State<RelatorioAnualPage> {
  int anoSelecionado = DateTime.now().year;

  void _anoAnterior() => setState(() => anoSelecionado--);

  void _proximoAno() => setState(() => anoSelecionado++);

  Map<String, double> _gastosPorCategoriaAnual(FinanceiroModel model) {
    final resultado = <String, double>{};

    for (int mes = 1; mes <= 12; mes++) {
      final transacoes = model.getTransacoesDoMes(DateTime(anoSelecionado, mes));

      for (final Transacao t in transacoes) {
        if (t.tipo != 'Gasto') continue;
        if (t.isAutomatica) continue;

        resultado[t.categoria] = (resultado[t.categoria] ?? 0) + t.valor;
      }
    }

    final ordenado = resultado.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(ordenado);
  }

  Map<int, double> _gastosPorMes(FinanceiroModel model) {
    final resultado = <int, double>{};

    for (int mes = 1; mes <= 12; mes++) {
      final transacoes = model.getTransacoesDoMes(DateTime(anoSelecionado, mes));
      double total = 0;

      for (final Transacao t in transacoes) {
        if (t.tipo != 'Gasto') continue;
        if (t.isAutomatica) continue;
        total += t.valor;
      }

      resultado[mes] = total;
    }

    return resultado;
  }

  double _total(Map<String, double> dados) {
    return dados.values.fold(0.0, (soma, valor) => soma + valor);
  }

  String _nomeMes(int mes) {
    const meses = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];

    return meses[mes - 1];
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<FinanceiroModel>();

    final categorias = _gastosPorCategoriaAnual(model);
    final gastosMensais = _gastosPorMes(model);
    final totalAnual = _total(categorias);
    final mediaMensal = totalAnual / 12;
    final maiorMes = gastosMensais.entries.fold<MapEntry<int, double>?>(
      null,
      (maior, atual) => maior == null || atual.value > maior.value ? atual : maior,
    );

    return Scaffold(
      drawer: const AppDrawer(selectedItem: AppDrawerItem.relatorioAnual),
      appBar: AppBar(title: const Text('Relatório anual')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _buildSeletorAno(),
            const SizedBox(height: 14),
            _buildCardTotal(
              totalAnual: totalAnual,
              mediaMensal: mediaMensal,
              maiorMes: maiorMes,
            ),
            const SizedBox(height: 14),
            _buildGraficoPizza(categorias, totalAnual),
            const SizedBox(height: 14),
            _buildGraficoMensal(gastosMensais),
            const SizedBox(height: 14),
            _buildCategorias(categorias, totalAnual),
          ],
        ),
      ),
    );
  }

  Widget _buildSeletorAno() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          IconButton(onPressed: _anoAnterior, icon: const Icon(Icons.chevron_left)),
          Expanded(
            child: Text(
              anoSelecionado.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(onPressed: _proximoAno, icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }

  Widget _buildCardTotal({
    required double totalAnual,
    required double mediaMensal,
    required MapEntry<int, double>? maiorMes,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total gasto no ano',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatarMoeda(totalAnual),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildResumoChip(
                  titulo: 'Média mensal',
                  valor: formatarMoeda(mediaMensal),
                  icon: Icons.calendar_month_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildResumoChip(
                  titulo: 'Maior mês',
                  valor: maiorMes == null || maiorMes.value <= 0
                      ? 'Sem dados'
                      : '${_nomeMes(maiorMes.key)} · ${formatarMoeda(maiorMes.value)}',
                  icon: Icons.bolt_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumoChip({
    required String titulo,
    required String valor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accentBlue, size: 20),
          const SizedBox(height: 10),
          Text(
            titulo,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraficoPizza(Map<String, double> categorias, double total) {
    if (categorias.isEmpty) return _buildEstadoVazio();

    final top = categorias.entries.take(5).toList();

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
            'Distribuição por categoria',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              SizedBox(
                width: 136,
                height: 136,
                child: CustomPaint(
                  painter: _DonutChartPainter(dados: top, total: total),
                  child: Center(
                    child: Text(
                      '${top.length}\ncat.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: top.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final percentual = total <= 0 ? 0.0 : item.value / total;
                    return _buildLegendaCategoria(index, item.key, percentual);
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendaCategoria(int index, String nome, double percentual) {
    final cor = _chartColors[index % _chartColors.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              nome,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '${(percentual * 100).toStringAsFixed(1)}%',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraficoMensal(Map<int, double> gastosMensais) {
    final maiorValor = gastosMensais.values.isEmpty
        ? 0.0
        : gastosMensais.values.reduce((a, b) => a > b ? a : b);

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
            'Evolução mensal',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          ...gastosMensais.entries.map((entry) {
            final porcentagem = maiorValor <= 0 ? 0.0 : entry.value / maiorValor;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 38,
                    child: Text(
                      _nomeMes(entry.key),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: porcentagem,
                        minHeight: 9,
                        backgroundColor: AppColors.surfaceSoft,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 92,
                    child: Text(
                      formatarMoeda(entry.value),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
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

  Widget _buildCategorias(Map<String, double> categorias, double total) {
    if (categorias.isEmpty) return const SizedBox.shrink();

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
            'Ranking de categorias',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          ...categorias.entries.map((entry) {
            final percentual = total <= 0 ? 0.0 : entry.value / total;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildCategoriaItem(
                nome: entry.key,
                valor: entry.value,
                percentual: percentual,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoriaItem({
    required String nome,
    required double valor,
    required double percentual,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              formatarMoeda(valor),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: percentual,
            minHeight: 9,
            backgroundColor: AppColors.surfaceSoft,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '${(percentual * 100).toStringAsFixed(1)}% dos gastos do ano',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildEstadoVazio() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.insights_outlined, color: AppColors.textMuted, size: 38),
          SizedBox(height: 12),
          Text(
            'Nenhum gasto encontrado neste ano.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

const List<Color> _chartColors = [
  AppColors.primaryBlue,
  AppColors.accentBlue,
  AppColors.success,
  AppColors.warning,
  AppColors.danger,
];

class _DonutChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> dados;
  final double total;

  _DonutChartPainter({
    required this.dados,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final strokeWidth = size.width * 0.18;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (total <= 0 || dados.isEmpty) {
      paint.color = AppColors.surfaceSoft;
      canvas.drawArc(rect.deflate(strokeWidth / 2), 0, math.pi * 2, false, paint);
      return;
    }

    double start = -math.pi / 2;

    for (int i = 0; i < dados.length; i++) {
      final sweep = (dados[i].value / total) * math.pi * 2;
      paint.color = _chartColors[i % _chartColors.length];
      canvas.drawArc(rect.deflate(strokeWidth / 2), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.dados != dados || oldDelegate.total != total;
  }
}
