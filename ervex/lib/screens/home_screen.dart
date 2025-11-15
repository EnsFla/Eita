import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:math'; // Para usar 'min' e 'max'
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:ervex/models/clima.dart';
import 'package:ervex/models/boletim.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, dynamic>> _dataFuture;
  String _regiaoAtual = 'Carregando...';

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadInitialData();
  }

  Future<Map<String, dynamic>> _loadInitialData() async {
    final regiaoPrefs = _carregarRegiao();
    final jsonData = _loadJsonData();
    final results = await Future.wait([regiaoPrefs, jsonData]);
    _regiaoAtual = results[0] as String;
    return results[1] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _loadJsonData() async {
    try {
      final climaString = rootBundle.loadString('assets/data/clima.json');
      final boletinsString =
          rootBundle.loadString('assets/data/boletins.json');
      final results = await Future.wait([climaString, boletinsString]);

      final List<dynamic> climaData = json.decode(results[0]);
      final List<Clima> climaList =
          climaData.map((json) => Clima.fromJson(json)).toList();

      final List<dynamic> boletinsData = json.decode(results[1]);
      final List<Boletim> boletimList =
          boletinsData.map((json) => Boletim.fromJson(json)).toList();

      return {
        'clima': climaList,
        'boletins': boletimList,
      };
    } catch (e) {
      throw Exception('Falha ao carregar dados');
    }
  }

  Future<String> _carregarRegiao() async {
    final prefs = await SharedPreferences.getInstance();
    final regiaoSalva =
        prefs.getString('regiaoSelecionada') ?? 'São Mateus do Sul, PR';
    if (mounted) {
      setState(() {
        _regiaoAtual = regiaoSalva;
      });
    }
    return regiaoSalva;
  }

  Future<void> _refreshData() async {
    final data = _loadInitialData();
    setState(() {
      _dataFuture = data;
    });
    await data;
  }

  (String, IconData) _getAlerta(Clima clima, Boletim boletim) {
    if (clima.tempMin <= 5) {
      return ("Risco de geada forte. Proteja os ervais jovens!", Icons.ac_unit);
    }
    if (clima.chuvaMm > 10) {
      return ("Chuva intensa. Evite colheita e manejo de solo.", Icons.water_drop);
    }
    return (boletim.titulo, Icons.article_outlined);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ervex'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            iconSize: 32,
            onPressed: () {
              context.go('/perfil');
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child:
                    Text('Erro ao carregar dados: ${snapshot.error.toString()}'));
          }
          if (!snapshot.hasData ||
              snapshot.data!['clima'] == null ||
              snapshot.data!['boletins'] == null) {
            return const Center(child: Text('Nenhum dado encontrado.'));
          }

          final climaList = snapshot.data!['clima'] as List<Clima>;
          final boletimList = snapshot.data!['boletins'] as List<Boletim>;

          final now = DateTime.now();
          final hoje = climaList.firstWhere(
            (clima) => DateUtils.isSameDay(clima.data, now),
            orElse: () => climaList.first,
          );
          
          final (alerta, alertaIcone) = _getAlerta(hoje, boletimList.first);

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // --- Cabeçalho de Saudação e Região ---
                Text(
                  'Bem-vindo ao Ervex',
                  style: textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.location_on,
                        color: colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _regiaoAtual,
                      style: textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // 1. Card de Alerta Superior (Estilo Melhorado)
                _AlertCard(
                  alerta: alerta,
                  icon: alertaIcone,
                  onTap: () => context.go('/boletins'),
                ),
                const SizedBox(height: 24),

                // 2. Layout de Dashboard em Duas Colunas
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- COLUNA DA ESQUERDA (NOTÍCIAS) ---
                    Expanded(
                      flex: 6, // 60% da largura
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(title: "Notícias Recentes"),
                          const SizedBox(height: 16),
                          _FeaturedContentList(boletimList: boletimList),
                        ],
                      ),
                    ),
                    // --- CORREÇÃO: Diminuir o espaço entre colunas ---
                    const SizedBox(width: 12), // Era 16

                    // --- COLUNA DA DIREITA (GUIA DE CULTIVO) ---
                    Expanded(
                      flex: 4, // 40% da largura
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(title: "Guia de Cultivo"),
                          const SizedBox(height: 16),
                          // 1. Resumo da Semana (Destaque do Guia)
                          _WeatherSummaryCard(climaList: climaList),
                          const SizedBox(height: 16),
                          // 2. Guia Rápido (Tipo Embrapa)
                          _GuiaRapidoCard(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// --- WIDGETS ---

// Cabeçalho de Seção
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) { // <-- CORREÇÃO: BuildContextContext -> BuildContext
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

// Lista de Notícias (Boletins)
class _FeaturedContentList extends StatelessWidget {
  final List<Boletim> boletimList;
  const _FeaturedContentList({required this.boletimList});

  @override
  Widget build(BuildContext context) {
    // Como estamos dentro de um ListView > Row > Column,
    // não podemos usar outro ListView.builder.
    // Usar Column para uma lista pequena (4-5 itens) é aceitável.
    
    // --- CORREÇÃO: Limitar a 2 notícias e adicionar botão "Ler Mais" ---
    final int maxItems = 2;
    final itemsToShow = boletimList.take(maxItems).toList();

    return Column(
      children: [
        ...itemsToShow // Spread operator para a lista limitada
            .map((boletim) => Padding(
                  // --- CORREÇÃO: Diminuir espaço vertical entre notícias ---
                  padding: const EdgeInsets.only(bottom: 12.0), // Era 16
                  child: _FeaturedContentCard(boletim: boletim),
                ))
            .toList(),
        
        // Adiciona o botão se houver mais boletins do que o máximo
        if (boletimList.length > maxItems)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: TextButton(
              onPressed: () => context.go('/boletins'), // Navega para a tela News
              child: const Text('Ler mais notícias...'),
            ),
          )
      ],
    );
  }
}

// Card de Notícia (Boletim)
class _FeaturedContentCard extends StatelessWidget {
  final Boletim boletim;
  const _FeaturedContentCard({required this.boletim});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      child: InkWell(
        onTap: () => context.go('/boletins'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          // --- CORREÇÃO: Diminuir padding interno do card ---
          padding: const EdgeInsets.all(12.0), // Era 16
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Chip(
                label: Text(boletim.categoria),
                backgroundColor: colorScheme.primary.withOpacity(0.1),
                labelStyle: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              // --- CORREÇÃO: Diminuir espaço interno ---
              const SizedBox(height: 4), // Era 8
              Text(
                boletim.titulo,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              // --- CORREÇÃO: Diminuir espaço interno ---
              const SizedBox(height: 2), // Era 4
              Text(
                boletim.resumo,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
                // --- CORREÇÃO: Diminuir tamanho vertical (menos linhas) ---
                maxLines: 2, // Era 3
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Card de Resumo da Semana (na coluna da direita)
class _WeatherSummaryCard extends StatelessWidget {
  final List<Clima> climaList;
  const _WeatherSummaryCard({required this.climaList});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final int minTemp = climaList.map((c) => c.tempMin).reduce(min);
    final int maxTemp = climaList.map((c) => c.tempMax).reduce(max);
    final bool isChuvosa = climaList.any((c) => c.chuvaMm > 5);
    final String tituloSemana = isChuvosa ? "Semana Chuvosa" : "Tempo Misto";

    return Card(
      color: colorScheme.primary.withOpacity(0.1),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tituloSemana,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$maxTemp° / $minTemp°',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// NOVO WIDGET: Card "Guia Rápido" (Tipo Embrapa)
class _GuiaRapidoCard extends StatelessWidget {
  const _GuiaRapidoCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tópicos estáticos que simulam um guia
            _GuiaItem(
              icon: Icons.grass,
              title: "Preparo do Solo",
              onTap: () => context.go('/learn'),
            ),
            Divider(height: 24, color: colorScheme.surface),
            _GuiaItem(
              icon: Icons.bug_report_outlined,
              title: "Manejo de Pragas",
              onTap: () => context.go('/learn'),
            ),
            Divider(height: 24, color: colorScheme.surface),
            _GuiaItem(
              icon: Icons.cut,
              title: "Colheita e Poda",
              onTap: () => context.go('/learn'),
            ),
            Divider(height: 24, color: colorScheme.surface),
            _GuiaItem(
              icon: Icons.local_fire_department_outlined,
              title: "Secagem (Sapeco)",
              onTap: () => context.go('/learn'),
            ),
          ],
        ),
      ),
    );
  }
}

// Item individual do Guia Rápido
class _GuiaItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _GuiaItem(
      {required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Melhor alinhamento
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          // --- CORREÇÃO: Envolver o Text em Expanded para corrigir o OVERFLOW ---
          Expanded(
            child: Text(
              title,
              // Estilo que eu tinha apagado por engano
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600
              ),
            ), // <-- Parêntese do Text FECHADO
          ), // <-- Parêntese do Expanded FECHADO
        ],
      ),
    );
  }
}


// Card de Alerta (Estilo Melhorado)
class _AlertCard extends StatelessWidget {
  final String alerta;
  final IconData icon;
  final VoidCallback onTap;

  const _AlertCard({
    required this.alerta,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      // Fundo verde claro
      color: colorScheme.primaryContainer,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Ícone verde escuro
              Icon(icon, color: colorScheme.primary, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  alerta,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        // Texto verde escuro (ou onPrimaryContainer)
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600
                      ),
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  color: colorScheme.primary, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}