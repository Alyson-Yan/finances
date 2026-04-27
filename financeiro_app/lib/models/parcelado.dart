enum TipoTransacao { ganho, gasto }

class Parcela {
  final int numero;
  final double valor;
  final DateTime data;

  Parcela({
    required this.numero,
    required this.valor,
    required this.data,
  });
}

class Parcelado {
  String id;
  String descricao;
  double valorTotal;
  int totalParcelas;
  TipoTransacao tipo;
  DateTime dataInicio;

  Parcelado({
    required this.id,
    required this.descricao,
    required this.valorTotal,
    required this.totalParcelas,
    required this.tipo,
    required this.dataInicio,
  });

  /// Gera parcelas dinamicamente com ajuste de centavos
  List<Parcela> gerarParcelas() {
    List<Parcela> parcelas = [];

    // valor base truncado em 2 casas
    double valorBase =
        (valorTotal / totalParcelas).floorToDouble() / 100 * 100;

    // alternativa mais precisa:
    valorBase =
        double.parse((valorTotal / totalParcelas).toStringAsFixed(2));

    double soma = 0;

    for (int i = 1; i <= totalParcelas; i++) {
      DateTime dataParcela = DateTime(
        dataInicio.year,
        dataInicio.month + (i - 1),
        dataInicio.day,
      );

      double valor = valorBase;

      // última parcela ajusta diferença
      if (i == totalParcelas) {
        valor = double.parse((valorTotal - soma).toStringAsFixed(2));
      }

      soma += valor;

      parcelas.add(
        Parcela(
          numero: i,
          valor: valor,
          data: dataParcela,
        ),
      );
    }

    return parcelas;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descricao': descricao,
      'valorTotal': valorTotal,
      'totalParcelas': totalParcelas,
      'tipo': tipo.name, // salva como string
      'dataInicio': dataInicio.toIso8601String(),
    };
  }

  factory Parcelado.fromMap(Map<String, dynamic> map) {
    return Parcelado(
      id: map['id'],
      descricao: map['descricao'],
      valorTotal: (map['valorTotal'] as num).toDouble(),
      totalParcelas: map['totalParcelas'],
      tipo: TipoTransacao.values.firstWhere(
        (e) => e.name == map['tipo'],
      ),
      dataInicio: DateTime.parse(map['dataInicio']),
    );
  }
}