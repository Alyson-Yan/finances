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
  String descricaoDetalhada;
  double valorTotal;
  int totalParcelas;
  TipoTransacao tipo;
  String categoria;
  DateTime dataInicio;

  Parcelado({
    required this.id,
    required this.descricao,
    required this.valorTotal,
    required this.totalParcelas,
    required this.tipo,
    required this.dataInicio,
    this.descricaoDetalhada = '',
    this.categoria = 'Sem categoria',
  });

  List<Parcela> gerarParcelas() {
    final parcelas = <Parcela>[];
    final valorBase = double.parse((valorTotal / totalParcelas).toStringAsFixed(2));
    double soma = 0;

    for (var i = 1; i <= totalParcelas; i++) {
      final dataParcela = DateTime(
        dataInicio.year,
        dataInicio.month + (i - 1),
        dataInicio.day,
      );

      var valor = valorBase;

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
      'descricaoDetalhada': descricaoDetalhada,
      'valorTotal': valorTotal,
      'totalParcelas': totalParcelas,
      'tipo': tipo.name,
      'categoria': categoria,
      'dataInicio': dataInicio.toIso8601String(),
    };
  }

  factory Parcelado.fromMap(Map<String, dynamic> map) {
    return Parcelado(
      id: map['id'],
      descricao: map['descricao'],
      descricaoDetalhada: map['descricaoDetalhada'] ?? '',
      valorTotal: (map['valorTotal'] as num).toDouble(),
      totalParcelas: map['totalParcelas'],
      tipo: TipoTransacao.values.firstWhere(
        (e) => e.name == map['tipo'],
      ),
      categoria: map['categoria'] ?? 'Sem categoria',
      dataInicio: DateTime.parse(map['dataInicio']),
    );
  }
}
