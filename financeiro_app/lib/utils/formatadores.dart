import 'package:intl/intl.dart';

final NumberFormat _formatoMoeda = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
);

String formatarMoeda(double valor) {
  return _formatoMoeda.format(valor);
}

String nomeMesAno(DateTime data) {
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

  return '${meses[data.month - 1]} ${data.year}';
}

String mesAnoCurto(DateTime data) {
  return '${data.month.toString().padLeft(2, '0')}/${data.year}';
}
