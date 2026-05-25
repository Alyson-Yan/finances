import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/financeiro_model.dart';
import '../models/transacao.dart';
import '../theme/app_theme.dart';
import '../utils/formatadores.dart';

class PendenciasPage extends StatelessWidget {
  final DateTime mesSelecionado;

  const PendenciasPage({
    super.key,
    required this.mesSelecionado,
  });

  @override
  Widget build(BuildContext context) {
    final model = context.watch<FinanceiroModel>();
    final grupos = model.getPendenciasAgrupadasPorMes(mesSelecionado);
    final pendencias = model.getPendenciasAteMes(mesSelecionado);
    final total = model.totalPendenteAteMes(mesSelecionado);

    return Scaffold(
      appBar: AppBar(title: const Text('Pendências abertas')),
      body: SafeArea(
        child: pendencias.isEmpty
            ? _buildVazio()
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _buildResumo(total, pendencias.length),
                  const SizedBox(height: 14),
                  ...grupos.entries.map((grupo) {
                    final mes = grupo.key;
                    final itens = grupo.value;
                    final totalMes = model.totalPendenciasDoGrupo(itens);

                    return _buildGrupoPendencias(
                      context: context,
                      model: model,
                      mes: mes,
                      pendencias: itens,
                      totalMes: totalMes,
                    );
                  }),
                ],
              ),
      ),
    );
  }

  Widget _buildVazio() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.success, size: 42),
            SizedBox(height: 12),
            Text(
              'Nenhuma pendência aberta.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumo(double total, int quantidade) {
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
            'Contas em aberto',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatarMoeda(total),
            style: const TextStyle(
              color: AppColors.warning,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$quantidade pendência(s) até ${nomeMesAno(mesSelecionado)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrupoPendencias({
    required BuildContext context,
    required FinanceiroModel model,
    required DateTime mes,
    required List<Transacao> pendencias,
    required double totalMes,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Text(
            '${nomeMesAno(mes)} · ${pendencias.length} pendência(s)',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Text(
            formatarMoeda(totalMes),
            style: const TextStyle(
              color: AppColors.warning,
              fontWeight: FontWeight.w800,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  model.marcarListaComoPaga(pendencias);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Pendências de ${nomeMesAno(mes)} marcadas como pagas.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Marcar mês como pago'),
              ),
            ),
            ...pendencias.map((t) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
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
                          const SizedBox(height: 4),
                          Text(
                            'Vencimento: ${mesAnoCurto(t.data)} · ${formatarMoeda(t.valor)}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Checkbox(
                      value: model.estaPago(t.id),
                      onChanged: (_) => model.marcarComoPago(t.id),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
