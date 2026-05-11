import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/financeiro_model.dart';
import '../models/transacao.dart';

class PendenciasPage extends StatelessWidget {
  final DateTime mesSelecionado;

  const PendenciasPage({
    super.key,
    required this.mesSelecionado,
  });

  String _nomeMes(DateTime data) {
    const meses = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];

    return "${meses[data.month - 1]} ${data.year}";
  }

  Map<String, List<Transacao>> _agruparPorMes(List<Transacao> pendencias) {
    final Map<String, List<Transacao>> grupos = {};

    for (final t in pendencias) {
      final chave = _nomeMes(DateTime(t.data.year, t.data.month));

      if (!grupos.containsKey(chave)) {
        grupos[chave] = [];
      }

      grupos[chave]!.add(t);
    }

    return grupos;
  }

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<FinanceiroModel>(context);
    final pendencias = model.getPendenciasAteMes(mesSelecionado);
    final total = model.totalPendenteAteMes(mesSelecionado);
    final grupos = _agruparPorMes(pendencias);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pendências abertas"),
        centerTitle: true,
      ),
      body: pendencias.isEmpty
          ? const Center(
              child: Text(
                "Nenhuma pendência aberta.",
                style: TextStyle(fontSize: 16),
              ),
            )
          : Column(
              children: [
                Padding(
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
                            "Total em aberto",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "R\$ ${total.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: ListView(
                    children: grupos.entries.map((grupo) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ExpansionTile(
                            initiallyExpanded: true,
                            title: Text(
                              grupo.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            children: grupo.value.map((t) {
                              return ListTile(
                                title: Text(
                                  t.nome,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  "R\$ ${t.valor.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                trailing: Checkbox(
                                  value: model.estaPago(t.id),
                                  onChanged: (_) {
                                    model.marcarComoPago(t.id);
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
    );
  }
}