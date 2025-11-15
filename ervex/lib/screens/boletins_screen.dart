import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:ervex/models/boletim.dart';

class BoletinsScreen extends StatefulWidget {
  const BoletinsScreen({super.key});

  @override
  State<BoletinsScreen> createState() => _BoletinsScreenState();
}

class _BoletinsScreenState extends State<BoletinsScreen> {
  late Future<List<Boletim>> _boletinsFuture;
  final DateFormat _dateFormat = DateFormat('dd \'de\' MMMM, yyyy', 'pt_BR');

  @override
  void initState() {
    super.initState();
    _boletinsFuture = _loadBoletinsData();
  }

  Future<List<Boletim>> _loadBoletinsData() async {
    try {
      final String response = await rootBundle.loadString('assets/data/boletins.json');
      final List<dynamic> data = json.decode(response);
      return data.map((json) => Boletim.fromJson(json)).toList();
    } catch (e) {
      // print("Erro ao carregar boletins: $e");
      throw Exception('Falha ao carregar boletins');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boletins e Alertas'),
      ),
      body: FutureBuilder<List<Boletim>>(
        future: _boletinsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum boletim encontrado.'));
          }

          final boletins = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: boletins.length,
            itemBuilder: (context, index) {
              final boletim = boletins[index];
              return _buildBoletimCard(context, boletim);
            },
          );
        },
      ),
    );
  }

  Widget _buildBoletimCard(BuildContext context, Boletim boletim) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () {
          // Ação de clique: No futuro, navegaria para
          // context.go('/boletim/${boletim.id}')
          // Por enquanto, mostra um SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Boletim selecionado: ${boletim.titulo}'),
              backgroundColor: colorScheme.primary,
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Categoria e Data
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Text(boletim.categoria),
                    backgroundColor: colorScheme.primary.withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                  ),
                  Text(
                    _dateFormat.format(boletim.data),
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Título
              Text(
                boletim.titulo,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              
              // Resumo
              Text(
                boletim.resumo,
                style: textTheme.bodyMedium?.copyWith(
                  color: textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              
              // Ação
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Ler mais',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 14, color: colorScheme.primary),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}