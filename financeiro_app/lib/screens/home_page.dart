import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/financeiro_model.dart';
import '../models/transacao.dart';
import '../utils/formatadores.dart';
import 'adicionar_transacao_page.dart';
import 'categoria_page.dart';
import 'pendencias_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Ordenacao ordenacaoSelecionada = Ordenacao.dataMaisRecente;
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

  void _mostrarDetalhes(BuildContext context, Transacao t) {
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
            Text('Valor: ${formatarMoeda(t.valor)}'),
            const SizedBox(height: 8),
            Text('Data: ${mesAnoCurto(t.data)}'),
            const SizedBox(height: 12),
            const Text(
              'Descrição detalhada:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              t.descricaoDetalhada.isEmpty
                  ? 'Sem descrição.'
                  : t.descricaoDetalhada,
            ),
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

  Future<void> _confirmarExclusao(
    FinanceiroModel model,
    Transacao t,
  ) async {
    final bool removeGrupo =
        t.id.startsWith('parcelado_') || t.id.startsWith('fixo_');

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
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmou == true) {
      model.removerItem(t.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<FinanceiroModel>(context);

    List<Transacao> transacoes = model.getTransacoesDoMes(mesSelecionado);
    final relatorioCategorias = _gastosPorCategoria(transacoes);
    transacoes = model.filtrarPorNome(transacoes, filtroNome);
    transacoes = model.ordenarTransacoes(transacoes, ordenacaoSelecionada);

    final saldoDoMes = model.saldoDoMesPrevisto(mesSelecionado);
    final saldoAcumuladoDisponivel =
        model.saldoAcumuladoDisponivel(mesSelecionado);
    final saldoAcumuladoPrevisto = model.saldoAcumuladoPrevisto(mesSelecionado);
    final ganhos = model.totalGanhosDoMes(mesSelecionado);
    final gastos = model.totalGastosDoMes(mesSelecionado);
    final saldoDisponivelDoMes = model.saldoDoMesDisponivel(mesSelecionado);
    final pendente = model.totalPendenteAteMes(mesSelecionado);
    final pendencias = model.getPendenciasAteMes(mesSelecionado);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financeiro'),
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
          _buildSeletorMes(),
          const SizedBox(height: 10),
          _buildResumoCard(
            saldoAcumuladoDisponivel: saldoAcumuladoDisponivel,
            saldoAcumuladoPrevisto: saldoAcumuladoPrevisto,
            saldoDoMes: saldoDoMes,
            saldoDisponivelDoMes: saldoDisponivelDoMes,
            pendente: pendente,
            ganhos: ganhos,
            gastos: gastos,
          ),
          _buildFiltros(),
          Expanded(
            child: ListView(
              children: [
                _buildSaudeFinanceira(
                  saldoAcumuladoDisponivel,
                  pendente,
                ),
                _buildRelatorioCategorias(relatorioCategorias),
                if (pendencias.isNotEmpty)
                  _buildPendenciasCard(
                    pendencias: pendencias,
                    pendente: pendente,
                  ),
                if (transacoes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text(
                        'Nenhuma transação neste mês.',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  )
                else
                  ...transacoes.map((t) => _buildTransacaoCard(model, t)),
              ],
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

  Widget _buildSeletorMes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        IconButton(
          onPressed: mesAnterior,
          icon: const Icon(Icons.arrow_back),
        ),
        Text(
          nomeMesAno(mesSelecionado),
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
    );
  }

  Widget _buildResumoCard({
    required double saldoAcumuladoDisponivel,
    required double saldoAcumuladoPrevisto,
    required double saldoDoMes,
    required double saldoDisponivelDoMes,
    required double pendente,
    required double ganhos,
    required double gastos,
  }) {
    return Padding(
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
                'Você tem disponível',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formatarMoeda(saldoAcumuladoDisponivel),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Resultado acumulado: ${formatarMoeda(saldoAcumuladoPrevisto)}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color:
                      saldoAcumuladoPrevisto >= 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black12,
                ),
                child: Column(
                  children: [
                    _buildResumoLinha(
                      label: 'Resultado deste mês',
                      valor: saldoDoMes,
                    ),
                    const SizedBox(height: 8),
                    _buildResumoLinha(
                      label: 'Dinheiro livre este mês',
                      valor: saldoDisponivelDoMes,
                    ),
                    const SizedBox(height: 8),
                    _buildResumoLinha(
                      label: 'Contas em aberto',
                      valor: pendente,
                      cor: pendente > 0 ? Colors.orange : Colors.green,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Entradas: ${formatarMoeda(ganhos)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Saídas: ${formatarMoeda(gastos)}',
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
    );
  }

  Widget _buildResumoLinha({
    required String label,
    required double valor,
    Color? cor,
  }) {
    final corValor = cor ?? (valor >= 0 ? Colors.green : Colors.red);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Text(
          formatarMoeda(valor),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: corValor,
          ),
        ),
      ],
    );
  }

  Widget _buildSaudeFinanceira(double disponivel, double pendente) {
    final semPendencia = pendente <= 0;
    final cobrePendencias = disponivel >= pendente;

    final mensagem = semPendencia
        ? 'Sem contas em aberto até este mês.'
        : cobrePendencias
            ? 'Seu dinheiro disponível cobre as contas em aberto.'
            : 'Atenção: contas em aberto passam do dinheiro disponível.';

    final cor = semPendencia || cobrePendencias ? Colors.green : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        child: ListTile(
          leading: Icon(
            semPendencia || cobrePendencias
                ? Icons.check_circle_outline
                : Icons.error_outline,
            color: cor,
          ),
          title: const Text(
            'Saúde financeira',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(mensagem),
        ),
      ),
    );
  }

  Widget _buildRelatorioCategorias(Map<String, double> categorias) {
    if (categorias.isEmpty) {
      return const SizedBox.shrink();
    }

    final principais = categorias.entries.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Maiores gastos do mês',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...principais.map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key),
                      Text(
                        formatarMoeda(e.value),
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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

  Widget _buildFiltros() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Filtrar por nome',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() {
                filtroNome = value;
              });
            },
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ordenar por:'),
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
                    child: Text('Data ↓'),
                  ),
                  DropdownMenuItem(
                    value: Ordenacao.dataMaisAntiga,
                    child: Text('Data ↑'),
                  ),
                  DropdownMenuItem(
                    value: Ordenacao.valorMaior,
                    child: Text('Valor ↓'),
                  ),
                  DropdownMenuItem(
                    value: Ordenacao.valorMenor,
                    child: Text('Valor ↑'),
                  ),
                  DropdownMenuItem(
                    value: Ordenacao.nomeAZ,
                    child: Text('Nome A-Z'),
                  ),
                  DropdownMenuItem(
                    value: Ordenacao.nomeZA,
                    child: Text('Nome Z-A'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendenciasCard({
    required List<Transacao> pendencias,
    required double pendente,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 3,
        child: ListTile(
          leading: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
          ),
          title: Text(
            'Pendências abertas (${pendencias.length})',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Total em aberto: ${formatarMoeda(pendente)}',
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PendenciasPage(
                  mesSelecionado: mesSelecionado,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTransacaoCard(FinanceiroModel model, Transacao t) {
    final pago = model.estaPago(t.id);
    final podeEditar =
        !t.id.startsWith('parcelado_') && !t.id.startsWith('fixo_');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: Icon(
          t.isAutomatica
              ? Icons.autorenew
              : (t.tipo == 'Ganho' ? Icons.trending_up : Icons.trending_down),
          color: t.isAutomatica
              ? Colors.blue
              : (t.tipo == 'Ganho' ? Colors.green : Colors.red),
        ),
        title: Text(
          t.nome,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            decoration: pago ? TextDecoration.lineThrough : null,
            color: pago ? Colors.grey : null,
            fontWeight: t.isAutomatica ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(_subtituloTransacao(t, pago)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatarMoeda(t.valor),
              style: TextStyle(
                color: t.tipo == 'Ganho' ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                decoration: pago ? TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(width: 8),
            if (t.tipo == 'Gasto' && !t.isAutomatica)
              Checkbox(
                value: pago,
                onChanged: (_) {
                  model.marcarComoPago(t.id);
                },
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

                  if (value == 'excluir') {
                    _confirmarExclusao(model, t);
                  }
                },
                itemBuilder: (_) => [
                  if (podeEditar)
                    const PopupMenuItem(
                      value: 'editar',
                      child: Text('Editar'),
                    ),
                  const PopupMenuItem(
                    value: 'excluir',
                    child: Text('Excluir'),
                  ),
                ],
              ),
          ],
        ),
        onTap: () {
          _mostrarDetalhes(context, t);
        },
      ),
    );
  }

  String _subtituloTransacao(Transacao t, bool pago) {
    if (t.tipo == 'Gasto') {
      return pago ? 'Gasto · pago' : 'Gasto · em aberto';
    }

    return t.isAutomatica ? 'Automático' : t.tipo;
  }
}
