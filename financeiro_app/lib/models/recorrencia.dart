class Recorrencia {
  final String id;
  final String descricao;
  final double valor;
  final String tipo;
  final String categoria; // 🔥 NOVO
  final DateTime dataInicio;

  Recorrencia({
    required this.id,
    required this.descricao,
    required this.valor,
    required this.tipo,
    required this.categoria, 
    required this.dataInicio,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descricao': descricao,
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
      valor: map['valor'],
      tipo: map['tipo'],
      categoria: map['categoria'] ?? '',
      dataInicio: DateTime.parse(map['dataInicio']),
    );
  }
}