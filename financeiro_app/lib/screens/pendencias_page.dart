import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/financeiro_model.dart';
import '../models/transacao.dart';
import '../utils/formatadores.dart';

class PendenciasPage extends StatelessWidget {
  final DateTime mesSelecionado;

  const PendenciasPage({
    super.key,
    required this.mesSelecionado,
  });

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<FinanceiroModel>(context);
    final grupos = model.getPendenciasAgrupadasPorMes(mesSelecionado);
    final pendencias = model.getPendenciasAteMes(mesSelecionado);
    final total = model.totalPendenteAteMes(mesSelecionado);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pendências abertas'),
        centerTitle: true,
      ),
      body: pendencias.isEmpty
          ? const Center(
              child: Text(
                'Nenhuma pendência aberta.',
                style: TextStyle(fontSize: 16),
              ),
            )
          : Column(
              children: [
                _buildResumo(total, pendencias.length),
                Expanded(
                  child: ListView(
                    children: grupos.entries.map((grupo) {
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
                    }).toList(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildResumo(double total, int quantidade) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'Contas em aberto',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formatarMoeda(total),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$quantidade pendência(s) até ${nomeMesAno(mesSelecionado)}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: ExpansionTile(
          initiallyExpanded: true,
          title: Text(
            '${nomeMesAno(mes)} · ${pendencias.length} pendência(s)',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            formatarMoeda(totalMes),
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
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
            ),
            ...pendencias.map((t) {
              return ListTile(
                title: Text(
                  t.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'Vencimento: ${mesAnoCurto(t.data)} · ${formatarMoeda(t.valor)}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Pago',
                      style: TextStyle(fontSize: 12),
                    ),
                    Checkbox(
                      value: model.estaPago(t.id),
                      onChanged: (_) {
                        model.marcarComoPago(t.id);
                      },
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
