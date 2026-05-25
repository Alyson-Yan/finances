import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/financeiro_model.dart';
import '../models/parcelado.dart';
import '../theme/app_theme.dart';

class AdicionarTransacaoPage extends StatefulWidget {
  final dynamic transacao;

  const AdicionarTransacaoPage({
    super.key,
    this.transacao,
  });

  @override
  State<AdicionarTransacaoPage> createState() => _AdicionarTransacaoPageState();
}

class _AdicionarTransacaoPageState extends State<AdicionarTransacaoPage> {
  final _descricaoController = TextEditingController();
  final _descricaoDetalhadaController = TextEditingController();
  final _valorController = TextEditingController();
  final _parcelasController = TextEditingController(text: '1');

  String? _categoriaSelecionada;
  String _tipoSelecionado = 'Gasto';

  DateTime _dataSelecionada = DateTime.now();
  DateTime _dataInicioFixo = DateTime.now();

  bool _usarValorDaParcela = false;
  bool _isFixo = false;

  bool get _editando => widget.transacao != null;
  bool get _editandoParcelado =>
      _editando && widget.transacao.id.toString().startsWith('parcelado_');
  bool get _editandoFixo =>
      _editando && widget.transacao.id.toString().startsWith('fixo_');

  @override
  void initState() {
    super.initState();

    if (widget.transacao != null) {
      final t = widget.transacao!;
      final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
      final infoParcelamento = _extrairParcelamento(t.nome);

      _descricaoController.text = _limparNomeGerado(t.nome);
      _descricaoDetalhadaController.text = t.descricaoDetalhada;
      _valorController.text = formatter.format(t.valor);
      _tipoSelecionado = t.tipo;
      _categoriaSelecionada = t.categoria;
      _dataSelecionada = t.data;

      if (_editandoParcelado) {
        _usarValorDaParcela = true;
        _parcelasController.text = infoParcelamento?.total.toString() ?? '1';

        final parcelaAtual = infoParcelamento?.atual ?? 1;
        _dataSelecionada = DateTime(
          t.data.year,
          t.data.month - (parcelaAtual - 1),
          t.data.day,
        );
      }

      if (_editandoFixo) {
        _isFixo = true;
        _dataInicioFixo = t.data;
      }
    }
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _descricaoDetalhadaController.dispose();
    _valorController.dispose();
    _parcelasController.dispose();
    super.dispose();
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
    final descricaoDetalhada = _descricaoDetalhadaController.text.trim();
    final parcelas = int.tryParse(_parcelasController.text) ?? 1;
    final valorInformado = _converterParaDouble(_valorController.text);
    final categoria = (_categoriaSelecionada == null || _categoriaSelecionada!.isEmpty)
        ? 'Sem categoria'
        : _categoriaSelecionada!;

    if (nome.isEmpty || valorInformado <= 0) {
      _erro('Preencha nome e valor corretamente.');
      return;
    }

    final valorTotal = (_usarValorDaParcela && parcelas > 1)
        ? valorInformado * parcelas
        : valorInformado;

    final model = context.read<FinanceiroModel>();
    final tipoEnum =
        _tipoSelecionado == 'Ganho' ? TipoTransacao.ganho : TipoTransacao.gasto;

    if (widget.transacao == null) {
      if (_isFixo) {
        model.adicionarFixo(
          nome: nome,
          descricaoDetalhada: descricaoDetalhada,
          valor: valorTotal,
          tipo: _tipoSelecionado,
          categoria: categoria,
          dataInicio: _dataInicioFixo,
        );
      } else if (parcelas > 1) {
        model.adicionarParcelado(
          nome: nome,
          descricaoDetalhada: descricaoDetalhada,
          valorTotal: valorTotal,
          tipo: tipoEnum,
          categoria: categoria,
          parcelas: parcelas,
          dataInicial: _dataSelecionada,
        );
      } else {
        model.adicionarTransacao(
          nome,
          descricaoDetalhada,
          valorInformado,
          _tipoSelecionado,
          categoria,
          data: _dataSelecionada,
        );
      }
    } else if (_editandoParcelado) {
      model.editarParcelado(
        id: _idOrigemVirtual(widget.transacao.id),
        nome: nome,
        descricaoDetalhada: descricaoDetalhada,
        valorTotal: valorTotal,
        tipo: tipoEnum,
        categoria: categoria,
        parcelas: parcelas,
        dataInicial: _dataSelecionada,
      );
    } else if (_editandoFixo) {
      model.editarRecorrencia(
        id: _idOrigemVirtual(widget.transacao.id),
        nome: nome,
        descricaoDetalhada: descricaoDetalhada,
        valor: valorInformado,
        tipo: _tipoSelecionado,
        categoria: categoria,
        dataInicio: _dataInicioFixo,
      );
    } else {
      model.editarTransacao(
        id: widget.transacao.id,
        nome: nome,
        descricaoDetalhada: descricaoDetalhada,
        valor: valorInformado,
        tipo: _tipoSelecionado,
        categoria: categoria,
        data: _dataSelecionada,
      );
    }

    Navigator.pop(context);
  }

  void _erro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
    final listaCategorias = {'Sem categoria', ...model.categorias.map((c) => c.nome)}.toList();
    final categoriaAtual = listaCategorias.contains(_categoriaSelecionada)
        ? _categoriaSelecionada
        : 'Sem categoria';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.transacao == null ? 'Nova transação' : 'Editar transação'),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(context).viewInsets.bottom + 28,
            ),
            children: [
              if (_editandoParcelado || _editandoFixo) ...[
                _buildAvisoEdicaoEspecial(),
                const SizedBox(height: 14),
              ],
              _buildSecao(
                title: 'Informações principais',
                children: [
                  TextField(
                    controller: _descricaoController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      prefixIcon: Icon(Icons.edit_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descricaoDetalhadaController,
                    maxLines: 3,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildSecao(
                title: 'Valores e tipo',
                children: [
                  if (!_editandoParcelado)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Fixo mensal'),
                      subtitle: const Text('Repete todo mês a partir da data escolhida.'),
                      value: _isFixo,
                      onChanged: _editandoFixo
                          ? null
                          : (v) => setState(() => _isFixo = v ?? false),
                    ),
                  if (parcelas > 1)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _usarValorDaParcela,
                      onChanged: _editandoParcelado
                          ? null
                          : (v) => setState(() => _usarValorDaParcela = v ?? false),
                      title: const Text('Valor informado é da parcela'),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _valorController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _CurrencyInputFormatter(),
                    ],
                    decoration: InputDecoration(
                      labelText: (_usarValorDaParcela && parcelas > 1)
                          ? 'Valor da parcela'
                          : 'Valor total',
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _parcelasController,
                    enabled: !_editandoFixo,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Parcelas',
                      prefixIcon: Icon(Icons.format_list_numbered),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _tipoSelecionado,
                    items: const [
                      DropdownMenuItem(value: 'Ganho', child: Text('Ganho')),
                      DropdownMenuItem(value: 'Gasto', child: Text('Gasto')),
                    ],
                    onChanged: (v) => setState(() => _tipoSelecionado = v!),
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      prefixIcon: Icon(Icons.swap_vert),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: categoriaAtual,
                    items: listaCategorias.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c));
                    }).toList(),
                    onChanged: (v) => setState(() => _categoriaSelecionada = v),
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildSecao(
                title: 'Datas',
                children: [
                  if (!_editandoFixo)
                    _buildLinhaData(
                      label: _editandoParcelado ? 'Início do parcelamento' : 'Data',
                      data: _dataSelecionada,
                      onPressed: () => _selecionarData(false),
                    ),
                  if (_isFixo)
                    _buildLinhaData(
                      label: 'Início do fixo',
                      data: _dataInicioFixo,
                      onPressed: () => _selecionarData(true),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _salvar,
                  child: const Text('Salvar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvisoEdicaoEspecial() {
    final texto = _editandoParcelado
        ? 'Você está editando o parcelamento inteiro. As parcelas geradas serão recalculadas.'
        : 'Você está editando o lançamento fixo mensal inteiro.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecao({
    required String title,
    required List<Widget> children,
  }) {
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
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLinhaData({
    required String label,
    required DateTime data,
    required VoidCallback onPressed,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$label: ${data.day}/${data.month}/${data.year}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(
          onPressed: onPressed,
          child: const Text('Alterar'),
        ),
      ],
    );
  }

  String _limparNomeGerado(String nome) {
    return nome.replaceFirst(RegExp(r'\s*\([^)]*\)\s*$'), '').trim();
  }

  _ParcelamentoInfo? _extrairParcelamento(String nome) {
    final match = RegExp(r'\((\d+)\/(\d+)\)').firstMatch(nome);
    if (match == null) return null;

    return _ParcelamentoInfo(
      atual: int.tryParse(match.group(1) ?? '') ?? 1,
      total: int.tryParse(match.group(2) ?? '') ?? 1,
    );
  }

  String _idOrigemVirtual(String id) {
    final partes = id.split('_');
    if (partes.length < 2) return id;
    return partes[1];
  }
}

class _ParcelamentoInfo {
  final int atual;
  final int total;

  _ParcelamentoInfo({
    required this.atual,
    required this.total,
  });
}

class _CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    final number = double.parse(digits) / 100;
    final newText = _formatter.format(number);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
