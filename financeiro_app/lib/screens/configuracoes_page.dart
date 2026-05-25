import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_config_model.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';

class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  late final TextEditingController _nomeController;

  @override
  void initState() {
    super.initState();
    final config = context.read<AppConfigModel>();
    _nomeController = TextEditingController(text: config.nomeUsuario);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _salvarNome() async {
    final config = context.read<AppConfigModel>();
    await config.atualizarNomeUsuario(_nomeController.text);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nome salvo com sucesso.')),
    );
  }

  Future<void> _limparNome() async {
    final config = context.read<AppConfigModel>();
    await config.limparNomeUsuario();
    _nomeController.clear();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nome removido.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<AppConfigModel>();

    return Scaffold(
      drawer: const AppDrawer(selectedItem: AppDrawerItem.configuracoes),
      appBar: AppBar(title: const Text('Configurações')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _buildPerfilCard(config),
            const SizedBox(height: 14),
            _buildInfoLocalCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildPerfilCard(AppConfigModel config) {
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
          const Text(
            'Perfil do usuário',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Esse nome aparece apenas no seu app e fica salvo neste celular.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _nomeController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Seu nome',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _salvarNome,
              child: const Text('Salvar nome'),
            ),
          ),
          if (config.nomeUsuario.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _limparNome,
                child: const Text('Remover nome'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoLocalCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.phone_android_outlined, color: AppColors.accentBlue),
          SizedBox(height: 12),
          Text(
            'Armazenamento local',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Nesta versão, seus dados ficam salvos no próprio celular. '
            'O app não depende de servidor para funcionar.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
