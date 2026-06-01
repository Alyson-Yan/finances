import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_config_model.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';

enum AppDrawerItem {
  inicio,
  lancamentos,
  planilha,
  relatorioAnual,
  categorias,
  configuracoes,
}

class AppDrawer extends StatelessWidget {
  final AppDrawerItem selectedItem;

  const AppDrawer({
    super.key,
    required this.selectedItem,
  });

  void _abrirRota(BuildContext context, String route) {
    Navigator.pop(context);

    final rotaAtual = ModalRoute.of(context)?.settings.name;
    if (rotaAtual == route) return;

    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<AppConfigModel>();

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(config),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildItem(
                    context: context,
                    item: AppDrawerItem.inicio,
                    icon: Icons.dashboard_outlined,
                    selectedIcon: Icons.dashboard,
                    title: 'Início',
                    route: AppRoutes.inicio,
                  ),
                  _buildItem(
                    context: context,
                    item: AppDrawerItem.lancamentos,
                    icon: Icons.receipt_long_outlined,
                    selectedIcon: Icons.receipt_long,
                    title: 'Lançamentos',
                    route: AppRoutes.lancamentos,
                  ),
                  _buildItem(
                    context: context,
                    item: AppDrawerItem.planilha,
                    icon: Icons.table_chart_outlined,
                    selectedIcon: Icons.table_chart,
                    title: 'Modo planilha',
                    route: AppRoutes.planilha,
                  ),
                  _buildItem(
                    context: context,
                    item: AppDrawerItem.relatorioAnual,
                    icon: Icons.insights_outlined,
                    selectedIcon: Icons.insights,
                    title: 'Relatório anual',
                    route: AppRoutes.relatorioAnual,
                  ),
                  _buildItem(
                    context: context,
                    item: AppDrawerItem.categorias,
                    icon: Icons.category_outlined,
                    selectedIcon: Icons.category,
                    title: 'Categorias',
                    route: AppRoutes.categorias,
                  ),
                  _buildItem(
                    context: context,
                    item: AppDrawerItem.configuracoes,
                    icon: Icons.settings_outlined,
                    selectedIcon: Icons.settings,
                    title: 'Configurações',
                    route: AppRoutes.configuracoes,
                  ),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppConfigModel config) {
    final nome = config.nomeUsuario.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.55),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.accentBlue,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Controle Financeiro',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              nome.isEmpty ? 'Dados salvos neste celular' : 'Olá, $nome',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem({
    required BuildContext context,
    required AppDrawerItem item,
    required IconData icon,
    required IconData selectedIcon,
    required String title,
    required String route,
  }) {
    final selected = selectedItem == item;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        selected: selected,
        selectedTileColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: Icon(
          selected ? selectedIcon : icon,
          color: selected ? AppColors.accentBlue : AppColors.textSecondary,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        trailing: selected
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.accentBlue,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: selected ? () => Navigator.pop(context) : () => _abrirRota(context, route),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: const Text(
          'Versão local-first · sem servidor',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
