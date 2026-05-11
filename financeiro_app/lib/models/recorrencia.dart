class Recorrencia {
  final String id;
  final String descricao;
  final String descricaoDetalhada;
  final double valor;
  final String tipo;
  final String categoria;
  final DateTime dataInicio;

  Recorrencia({
    required this.id,
    required this.descricao,
    required this.valor,
    required this.tipo,
    required this.categoria,
    required this.dataInicio,
    this.descricaoDetalhada = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descricao': descricao,
      'descricaoDetalhada': descricaoDetalhada,
      'valor': valor,
      'tipo': tipo,
      'categoria': categoria,
      'dataInicio': dataInicio.toIso8601String(),
    };
  }

  factory Recorrencia.fromMap(Map<String, dynamic> map) {
    return Recorrencia(
      id: map['id'],
      descricao: map['descricao'],
      descricaoDetalhada: map['descricaoDetalhada'] ?? '',
      valor: (map['valor'] as num).toDouble(),
      tipo: map['tipo'],
      categoria: map['categoria'] ?? 'Sem categoria',
      dataInicio: DateTime.parse(map['dataInicio']),
    );
  }
}
