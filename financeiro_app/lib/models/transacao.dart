class Transacao {
  final String id;
  final String nome; // antigo "descricao"
  final String descricaoDetalhada; // novo campo
  final double valor;
  final String tipo; // Ganho ou Gasto
  final String categoria;
  final DateTime data;

  Transacao({
    required this.id,
    required this.nome,
    required this.descricaoDetalhada,
    required this.valor,
    required this.tipo,
    required this.data,
    required this.categoria,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'descricaoDetalhada': descricaoDetalhada,
      'valor': valor,
      'tipo': tipo,
      'categoria': categoria,
      'data': data.toIso8601String(),
    };
  }

  factory Transacao.fromMap(Map<String, dynamic> map) {
    return Transacao(
      id: map['id'],
      nome: map['nome'],
      descricaoDetalhada: map['descricaoDetalhada'] ?? '',
      valor: (map['valor'] as num).toDouble(),
      tipo: map['tipo'],
      categoria: map['categoria'],
      data: DateTime.parse(map['data']),
    );
  }
}
