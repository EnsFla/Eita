class Clima {
  final DateTime data;
  final int tempMin;
  final int tempMax;
  final double chuvaMm;
  final String descricao;

  Clima({
    required this.data,
    required this.tempMin,
    required this.tempMax,
    required this.chuvaMm,
    required this.descricao,
  });

  // Factory para converter JSON em um objeto Clima
  factory Clima.fromJson(Map<String, dynamic> json) {
    return Clima(
      data: DateTime.parse(json['data']),
      tempMin: json['temp_min'],
      tempMax: json['temp_max'],
      chuvaMm: (json['chuva_mm'] as num).toDouble(),
      descricao: json['descricao'] ?? 'Sem descrição',
    );
  }
}