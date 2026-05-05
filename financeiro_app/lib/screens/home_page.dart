import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/financeiro_model.dart';
import '../models/transacao.dart';
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

  Ordenacao ordenacaoSelecionada = Ordenacao.dataMaisRecente;
  String filtroNome = '';

  

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

  List<Transacao> transacoes =
      model.getTransacoesAteMes(mesSelecionado);

// =============================
// FILTRO
// =============================
if (filtroNome.isNotEmpty) {
  transacoes = transacoes
      .where((t) =>
          t.nome.toLowerCase().contains(filtroNome.toLowerCase()))
      .toList();
}

// =============================
// ORDENAÇÃO
// =============================
switch (ordenacaoSelecionada) {
  case Ordenacao.valorMaior:
    transacoes.sort((a, b) => b.valor.compareTo(a.valor));
    break;

  case Ordenacao.valorMenor:
    transacoes.sort((a, b) => a.valor.compareTo(b.valor));
    break;

  case Ordenacao.dataMaisRecente:
    transacoes.sort((a, b) => b.data.compareTo(a.data));
    break;

  case Ordenacao.dataMaisAntiga:
    transacoes.sort((a, b) => a.data.compareTo(b.data));
    break;

  case Ordenacao.nomeAZ:
    transacoes.sort((a, b) => a.nome.compareTo(b.nome));
    break;

  case Ordenacao.nomeZA:
    transacoes.sort((a, b) => b.nome.compareTo(a.nome));
    break;
}

    final saldo = model.saldoAteMes(mesSelecionado);
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


Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: Column(
    children: [

      // 🔎 CAMPO DE FILTRO
      TextField(
        decoration: const InputDecoration(
          labelText: "Filtrar por nome",
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (value) {
          setState(() {
            filtroNome = value;
          });
        },
      ),

      const SizedBox(height: 10),

      // 🔃 ORDENAÇÃO
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Ordenar por:"),

          DropdownButton<Ordenacao>(
            value: ordenacaoSelecionada,
            onChanged: (value) {
              setState(() {
                ordenacaoSelecionada = value!;
              });
            },
            items: const [
              DropdownMenuItem(
                value: Ordenacao.dataMaisRecente,
                child: Text("Data ↓"),
              ),
              DropdownMenuItem(
                value: Ordenacao.dataMaisAntiga,
                child: Text("Data ↑"),
              ),
              DropdownMenuItem(
                value: Ordenacao.valorMaior,
                child: Text("Valor ↓"),
              ),
              DropdownMenuItem(
                value: Ordenacao.valorMenor,
                child: Text("Valor ↑"),
              ),
              DropdownMenuItem(
                value: Ordenacao.nomeAZ,
                child: Text("Nome A-Z"),
              ),
              DropdownMenuItem(
                value: Ordenacao.nomeZA,
                child: Text("Nome Z-A"),
              ),
            ],
          ),
        ],
      ),
    ],
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
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: ListTile(
                            leading: Icon(
                              t.isAutomatica
                                  ? Icons.autorenew
                                  : (t.tipo == "Ganho"
                                      ? Icons.trending_up
                                      : Icons.trending_down),
                              color: t.isAutomatica
                                  ? Colors.blue
                                  : (t.tipo == "Ganho" ? Colors.green : Colors.red),
                            ),

                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.nome,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    decoration: t.pago ? TextDecoration.lineThrough : null,
                                    color: t.pago ? Colors.grey : null,
                                    fontWeight:
                                        t.isAutomatica ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),

                                if (t.tipo == "Gasto" &&
                                    !t.pago &&
                                    (t.data.year < mesSelecionado.year ||
                                        (t.data.year == mesSelecionado.year &&
                                            t.data.month < mesSelecionado.month)))
                                  const Text(
                                    "⚠️ Dívida acumulada",
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),

                            subtitle: Text(
                              t.isAutomatica ? "Automático" : t.tipo,
                            ),

                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 💰 VALOR
                                Text(
                                  "R\$ ${t.valor.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    color: t.tipo == "Ganho" ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    decoration:
                                        t.pago ? TextDecoration.lineThrough : null,
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // ✅ CHECKBOX (AGORA REALMENTE CLICÁVEL)
                                if (t.tipo == "Gasto" && !t.isAutomatica)
                                  InkWell(
                                    onTap: () {
                                      model.marcarComoPago(t.id);
                                    },
                                    child: Checkbox(
                                      value: t.pago,
                                      onChanged: (_) {
                                        model.marcarComoPago(t.id);
                                      },
                                    ),
                                  ),

                                // ✏️ AÇÕES
                                if (!t.isAutomatica) ...[
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
                                      model.removerItem(t.id);
                                    },
                                  ),
                                ]
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