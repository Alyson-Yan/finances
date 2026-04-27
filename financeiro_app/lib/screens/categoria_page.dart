import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/financeiro_model.dart';

class CategoriasPage extends StatefulWidget {
  const CategoriasPage({super.key});

  @override
  State<CategoriasPage> createState() => _CategoriasPageState();
}

class _CategoriasPageState extends State<CategoriasPage> {
  final _controller = TextEditingController();

  void _adicionarCategoria() {
    final nome = _controller.text.trim();

    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Digite um nome para a categoria")),
      );
      return;
    }

    final model = context.read<FinanceiroModel>();
    final erro = model.adicionarCategoria(nome);

    if (erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro)),
      );
    } else {
      _controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Categoria criada com sucesso")),
      );
    }
  }

  void _editarCategoria(BuildContext context, String id, String nomeAtual) {
    final controller = TextEditingController(text: nomeAtual);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Editar categoria"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Novo nome",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              final novoNome = controller.text.trim();

              if (novoNome.isEmpty) return;

              context
                  .read<FinanceiroModel>()
                  .editarCategoria(id, novoNome);

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Categoria atualizada")),
              );
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  void _confirmarExclusao(String id, String nome) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Excluir categoria"),
        content: Text("Deseja realmente excluir \"$nome\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              context.read<FinanceiroModel>().removerCategoria(id);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Categoria removida")),
              );
            },
            child: const Text("Excluir"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<FinanceiroModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Categorias"),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("O que são categorias?"),
                  content: const Text(
                    "Categorias servem para organizar suas transações "
                    "como Alimentação, Transporte, Salário, etc. "
                    "Isso permite filtrar dados e gerar gráficos.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Entendi"),
                    )
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "Nova categoria",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _adicionarCategoria,
                child: const Text("Adicionar"),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            Expanded(
              child: model.categorias.isEmpty
                  ? const Center(
                      child: Text("Nenhuma categoria criada"),
                    )
                  : ListView.builder(
                      itemCount: model.categorias.length,
                      itemBuilder: (context, index) {
                        final categoria = model.categorias[index];

                        return Card(
                          child: ListTile(
                            title: Text(categoria.nome),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () {
                                    _editarCategoria(
                                      context,
                                      categoria.id,
                                      categoria.nome,
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    _confirmarExclusao(
                                      categoria.id,
                                      categoria.nome,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}