import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/financeiro_model.dart';
import '../models/parcelado.dart';

class AdicionarTransacaoPage extends StatefulWidget {
  final dynamic transacao;

  const AdicionarTransacaoPage({
    super.key,
    this.transacao,
  });

  @override
  State<AdicionarTransacaoPage> createState() =>
      _AdicionarTransacaoPageState();
}

class _AdicionarTransacaoPageState
    extends State<AdicionarTransacaoPage> {

  final _descricaoController = TextEditingController();
  final _descricaoDetalhadaController = TextEditingController();
  final _valorController = TextEditingController();
  final _parcelasController = TextEditingController(text: "1");

  String? _categoriaSelecionada;
  String _tipoSelecionado = 'Gasto';

  DateTime _dataSelecionada = DateTime.now();
  DateTime _dataInicioFixo = DateTime.now();

  bool _usarValorDaParcela = false;
  bool _isFixo = false;

  @override
  void initState() {
    super.initState();

    if (widget.transacao != null) {
      final t = widget.transacao!;

      _descricaoController.text = t.nome;
      _descricaoDetalhadaController.text = t.descricaoDetalhada;
      _valorController.text = t.valor.toString();
      _tipoSelecionado = t.tipo;
      _categoriaSelecionada = t.categoria;
      _dataSelecionada = t.data;
    }
  }

  double _converterParaDouble(String valorFormatado) {
    return double.tryParse(
          valorFormatado
              .replaceAll('R\$', '')
              .replaceAll('.', '')
              .replaceAll(',', '.')
              .trim(),
        ) ??
        0.0;
  }

  void _salvar() {
    final nome = _descricaoController.text.trim();
    final descricaoDetalhada =
        _descricaoDetalhadaController.text.trim();
    final parcelas = int.tryParse(_parcelasController.text) ?? 1;
    final valorInformado =
        _converterParaDouble(_valorController.text);

    if (_categoriaSelecionada == null ||
        _categoriaSelecionada!.isEmpty) {
      _erro("Selecione uma categoria");
      return;
    }

    if (nome.isEmpty || valorInformado <= 0) {
      _erro("Preencha corretamente");
      return;
    }

    final valorTotal =
        (_usarValorDaParcela && parcelas > 1)
            ? valorInformado * parcelas
            : valorInformado;

    final model = context.read<FinanceiroModel>();

    final tipoEnum =
        _tipoSelecionado == 'Ganho'
            ? TipoTransacao.ganho
            : TipoTransacao.gasto;

    if (widget.transacao == null) {

      if (_isFixo) {
        model.adicionarFixo(
          nome: nome,
          descricaoDetalhada: descricaoDetalhada,
          valor: valorTotal,
          tipo: _tipoSelecionado,
          categoria: _categoriaSelecionada!,
          dataInicio: _dataInicioFixo,
        );

      } else if (parcelas > 1) {
        model.adicionarParcelado(
          nome: nome,
          descricaoDetalhada: descricaoDetalhada,
          valorTotal: valorTotal,
          tipo: tipoEnum,
          categoria: _categoriaSelecionada!,
          parcelas: parcelas,
          dataInicial: _dataSelecionada,
        );

      } else {
        model.adicionarTransacao(
          nome,
          descricaoDetalhada,
          valorInformado,
          _tipoSelecionado,
          _categoriaSelecionada!,
        );
      }

    } else {
      model.editarTransacao(
        id: widget.transacao.id,
        nome: nome,
        descricaoDetalhada: descricaoDetalhada,
        valor: valorInformado,
        tipo: _tipoSelecionado,
        categoria: _categoriaSelecionada!,
        data: _dataSelecionada,
      );
    }

    Navigator.pop(context);
  }

  void _erro(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _selecionarData(bool isFixo) async {
    final data = await showDatePicker(
      context: context,
      initialDate: isFixo ? _dataInicioFixo : _dataSelecionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (data != null) {
      setState(() {
        if (isFixo) {
          _dataInicioFixo = data;
        } else {
          _dataSelecionada = data;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<FinanceiroModel>();
    final parcelas = int.tryParse(_parcelasController.text) ?? 1;
    final listaCategorias = {
      "Sem categoria",
      ...model.categorias.map((c) => c.nome)
    }.toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Nova Transação")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            TextField(
              controller: _descricaoController,
              decoration: const InputDecoration(labelText: "Nome"),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _descricaoDetalhadaController,
              maxLines: 3,
              decoration:
                  const InputDecoration(labelText: "Descrição"),
            ),

            CheckboxListTile(
              title: const Text("Fixo mensal"),
              value: _isFixo,
              onChanged: (v) => setState(() => _isFixo = v ?? false),
            ),

            if (parcelas > 1)
              CheckboxListTile(
                value: _usarValorDaParcela,
                onChanged: (v) =>
                    setState(() => _usarValorDaParcela = v ?? false),
                title: const Text("Valor da parcela"),
              ),

            TextField(
              controller: _valorController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _CurrencyInputFormatter(),
              ],
              decoration: InputDecoration(
                labelText:
                    (_usarValorDaParcela && parcelas > 1)
                        ? "Valor da parcela"
                        : "Valor total",
              ),
            ),

            TextField(
              controller: _parcelasController,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: "Parcelas"),
              onChanged: (_) => setState(() {}),
            ),

            DropdownButtonFormField<String>(
              initialValue: _tipoSelecionado,
              items: const [
                DropdownMenuItem(value: "Ganho", child: Text("Ganho")),
                DropdownMenuItem(value: "Gasto", child: Text("Gasto")),
              ],
              onChanged: (v) =>
                  setState(() => _tipoSelecionado = v!),
              decoration: const InputDecoration(labelText: "Tipo"),
            ),

            DropdownButtonFormField<String>(
              initialValue: listaCategorias.contains(_categoriaSelecionada)
                  ? _categoriaSelecionada
                  : "Sem categoria",

              items: listaCategorias.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Text(c),
                );
              }).toList(),

              onChanged: (v) =>
                  setState(() => _categoriaSelecionada = v),

              decoration: const InputDecoration(labelText: "Categoria"),
            ),

            const SizedBox(height: 10),

            // 📅 DATA NORMAL
            Row(
              children: [
                Text(
                    "Data: ${_dataSelecionada.day}/${_dataSelecionada.month}/${_dataSelecionada.year}"),
                const Spacer(),
                TextButton(
                  onPressed: () => _selecionarData(false),
                  child: const Text("Alterar"),
                )
              ],
            ),

            // 📅 DATA FIXO
            if (_isFixo)
              Row(
                children: [
                  Text(
                      "Início: ${_dataInicioFixo.day}/${_dataInicioFixo.month}/${_dataInicioFixo.year}"),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _selecionarData(true),
                    child: const Text("Alterar"),
                  )
                ],
              ),

            const Spacer(),

            ElevatedButton(
              onPressed: _salvar,
              child: const Text("Salvar"),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue) {

    if (newValue.text.isEmpty) return newValue;

    final digits =
        newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    final number = double.parse(digits) / 100;

    final newText = _formatter.format(number);

    return TextEditingValue(
      text: newText,
      selection:
          TextSelection.collapsed(offset: newText.length),
    );
  }
}