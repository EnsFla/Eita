import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:ervex/models/clima.dart';

class ClimaScreen extends StatefulWidget {
  const ClimaScreen({super.key});

  @override
  State<ClimaScreen> createState() => _ClimaScreenState();
}

class _ClimaScreenState extends State<ClimaScreen> {
  late Future<List<Clima>> _climaFuture;
  final DateFormat _dateFormat = DateFormat('dd/MM (EEE)', 'pt_BR');

  @override
  void initState() {
    super.initState();
    _climaFuture = _loadClimaData();
  }

  Future<List<Clima>> _loadClimaData() async {
    try {
      final String response = await rootBundle.loadString('assets/data/clima.json');
      final List<dynamic> data = json.decode(response);
      return data.map((json) => Clima.fromJson(json)).toList();
    } catch (e) {
      // print("Erro ao carregar clima: $e");
      throw Exception('Falha ao carregar dados do clima');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Previsão do Tempo'),
      ),
      body: FutureBuilder<List<Clima>>(
        future: _climaFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum dado de clima encontrado.'));
          }

          final climaList = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: climaList.length,
            itemBuilder: (context, index) {
              final clima = climaList[index];
              return _buildClimaCard(context, clima);
            },
          );
        },
      ),
    );
  }

  Widget _buildClimaCard(BuildContext context, Clima clima) {
    final textTheme = Theme.of(context).textTheme;
    final bool hoje = DateUtils.isSameDay(clima.data, DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hoje ? 'Hoje' : _dateFormat.format(clima.data),
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: hoje ? Theme.of(context).colorScheme.primary : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              clima.descricao,
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _InfoItem(
                  icon: Icons.thermostat,
                  label: '${clima.tempMin}° - ${clima.tempMax}°',
                  color: Colors.orange,
                ),
                _InfoItem(
                  icon: Icons.water_drop_outlined,
                  label: '${clima.chuvaMm} mm',
                  color: Colors.blue,
                ),
                // Exemplo de como poderia ser a umidade
                _InfoItem(
                  icon: Icons.air,
                  label: 'Umidade (N/D)', // Dado não fornecido
                  color: Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Widget auxiliar para item de informação
class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}