class Transacao {
  final String id;
  final String nome;
  final String descricaoDetalhada;
  final double valor;
  final String tipo;
  final String categoria;
  final DateTime data;

  bool pago;
  DateTime? dataPagamento;

  bool isAutomatica; // 👈 NOVO

  Transacao({
    required this.id,
    required this.nome,
    required this.descricaoDetalhada,
    required this.valor,
    required this.tipo,
    required this.data,
    required this.categoria,
    this.pago = false,
    this.dataPagamento,
    this.isAutomatica = false, // 👈 PADRÃO
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
      'pago': pago,
      'dataPagamento': dataPagamento?.toIso8601String(),
      'isAutomatica': isAutomatica, // 👈 NOVO
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
      pago: map['pago'] ?? false,
      dataPagamento: map['dataPagamento'] != null
          ? DateTime.parse(map['dataPagamento'])
          : null,
      isAutomatica: map['isAutomatica'] ?? false, // 👈 NOVO
    );
  }
}