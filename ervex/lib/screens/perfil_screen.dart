import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart'; // Importar GoRouter

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  late Future<List<String>> _regioesFuture;
  String _regiaoSelecionada = ''; // Padrão

  @override
  void initState() {
    super.initState();
    _regioesFuture = _loadRegioesData();
    _carregarRegiaoSalva(); // Carrega a seleção anterior
  }

  // Carrega a lista de regiões do JSON
  Future<List<String>> _loadRegioesData() async {
    try {
      final String response =
          await rootBundle.loadString('assets/data/regioes.json');
      final List<dynamic> data = json.decode(response);
      return data.cast<String>();
    } catch (e) {
      // print("Erro ao carregar regiões: $e");
      throw Exception('Falha ao carregar dados das regiões');
    }
  }

  // Carrega a preferência salva
  Future<void> _carregarRegiaoSalva() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _regiaoSelecionada =
            prefs.getString('regiaoSelecionada') ?? 'São Mateus do Sul, PR';
      });
    }
  }

  // Salva a nova região
  Future<void> _salvarRegiao(String regiao) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('regiaoSelecionada', regiao);

    if (mounted) {
      setState(() {
        _regiaoSelecionada = regiao;
      });

      // Mostra a confirmação
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Região alterada para $regiao'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      // --- CORREÇÃO: Navegar de volta para Home ---
      // Após salvar, leva o usuário de volta ao painel
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Região'),
      ),
      body: FutureBuilder<List<String>>(
        future: _regioesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma região encontrada.'));
          }

          final regioes = snapshot.data!;

          return ListView.builder(
            itemCount: regioes.length,
            itemBuilder: (context, index) {
              final regiao = regioes[index];
              final bool isSelected = (regiao == _regiaoSelecionada);

              return ListTile(
                title: Text(regiao),
                trailing: isSelected
                    ? Icon(Icons.radio_button_checked,
                        color: Theme.of(context).colorScheme.primary)
                    : const Icon(Icons.radio_button_unchecked),
                onTap: () {
                  // Salva a região ao tocar
                  _salvarRegiao(regiao);
                },
              );
            },
          );
        },
      ),
    );
  }
}