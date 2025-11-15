class Boletim {
  final String id;
  final String titulo;
  final String resumo;
  final DateTime data;
  final String categoria;

  Boletim({
    required this.id,
    required this.titulo,
    required this.resumo,
    required this.data,
    required this.categoria,
  });

  // Factory para converter JSON em um objeto Boletim
  factory Boletim.fromJson(Map<String, dynamic> json) {
    return Boletim(
      id: json['id'],
      titulo: json['titulo'],
      resumo: json['resumo'],
      data: DateTime.parse(json['data']),
      categoria: json['categoria'],
    );
  }
}