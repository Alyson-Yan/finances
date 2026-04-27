import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/financeiro_model.dart';
import 'adicionar_transacao_page.dart';
import 'categoria_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});


  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  void _mostrarDetalhes(BuildContext context, dynamic t) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Detalhes da Transação"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Nome: ${t.nome}"),
          const SizedBox(height: 8),
          Text("Tipo: ${t.tipo}"),
          const SizedBox(height: 8),
          Text("Valor: R\$ ${t.valor.toStringAsFixed(2)}"),
          const SizedBox(height: 8),
          Text(
              "Data: ${t.data.day}/${t.data.month}/${t.data.year}"),
          const SizedBox(height: 12),
          const Text(
            "Descrição detalhada:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            t.descricaoDetalhada.isEmpty
                ? "Sem descrição."
                : t.descricaoDetalhada,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Fechar"),
        ),
      ],
    ),
  );
}


  DateTime mesSelecionado = DateTime.now();

  void mesAnterior() {
    setState(() {
      mesSelecionado =
          DateTime(mesSelecionado.year, mesSelecionado.month - 1);
    });
  }

  void proximoMes() {
    setState(() {
      mesSelecionado =
          DateTime(mesSelecionado.year, mesSelecionado.month + 1);
    });
  }

  String nomeMes(DateTime data) {
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
      'Dezembro'
    ];

    return "${meses[data.month - 1]} ${data.year}";
  }

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<FinanceiroModel>(context);

    final transacoes = model.getTransacoesDoMes(mesSelecionado);

    final saldo = model.saldoDoMes(mesSelecionado);
    final ganhos = model.totalGanhosDoMes(mesSelecionado);
    final gastos = model.totalGastosDoMes(mesSelecionado);

    return Scaffold(
    appBar: AppBar(
      title: const Text("Financeiro"),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.category),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CategoriasPage(),
              ),
            );
          },
        ),
      ],
    ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          // =============================
          // SELETOR DE MÊS
          // =============================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: mesAnterior,
                icon: const Icon(Icons.arrow_back),
              ),
              Text(
                nomeMes(mesSelecionado),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: proximoMes,
                icon: const Icon(Icons.arrow_forward),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // =============================
          // RESUMO
          // =============================
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      "Saldo do Mês",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "R\$ ${saldo.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Ganhos: R\$ ${ganhos.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "Gastos: R\$ ${gastos.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // =============================
          // LISTA
          // =============================
          Expanded(
            child: transacoes.isEmpty
                ? const Center(
                    child: Text(
                      "Nenhuma transação neste mês.",
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: transacoes.length,
                    itemBuilder: (context, index) {
                      final t = transacoes[index];
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: ListTile(
                          title: Text(
                            t.nome,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(t.tipo),

                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [

                              Text(
                                "R\$ ${t.valor.toStringAsFixed(2)}",
                                style: TextStyle(
                                  color: t.tipo == "Ganho"
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(width: 8),

                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AdicionarTransacaoPage(transacao: t),
                                    ),
                                  );
                                },
                              ),

                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  model.removerTransacao(t.id);
                                },
                              ),
                            ],
                          ),

                          onTap: () {
                            _mostrarDetalhes(context, t);
                          },
                        ),
                      );
                                          },
                                        ),
                                ),
                              ],
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
                      }