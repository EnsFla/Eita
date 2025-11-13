import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
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
  // Futuro combinado para carregar clima e boletins
  late Future<Map<String, dynamic>> _dataFuture;
  // Variável de estado para a região
  String _regiaoAtual = 'Carregando...';

  @override
  void initState() {
    super.initState();
    // Carrega a região salva e os dados JSON
    // initState é chamado toda vez graças ao ShellRoute (sem "Stateful")
    _dataFuture = _loadInitialData();
  }

  // Carrega a região e os dados JSON na primeira vez
  Future<Map<String, dynamic>> _loadInitialData() async {
    await _carregarRegiao(); // Carrega a região primeiro
    return _loadJsonData(); // Depois carrega os JSONs
  }

  // Carrega todos os dados JSON
  Future<Map<String, dynamic>> _loadJsonData() async {
    try {
      // Carrega os dois arquivos em paralelo
      final climaString = rootBundle.loadString('assets/data/clima.json');
      final boletinsString =
          rootBundle.loadString('assets/data/boletins.json');

      // Aguarda ambos terminarem
      final results = await Future.wait([climaString, boletinsString]);

      // Processa Clima
      final List<dynamic> climaData = json.decode(results[0]);
      final List<Clima> climaList =
          climaData.map((json) => Clima.fromJson(json)).toList();

      // Processa Boletins
      final List<dynamic> boletinsData = json.decode(results[1]);
      final List<Boletim> boletimList =
          boletinsData.map((json) => Boletim.fromJson(json)).toList();

      // Retorna um mapa com as duas listas
      return {
        'clima': climaList,
        'boletins': boletimList,
      };
    } catch (e) {
      // print("Erro ao carregar dados JSON: $e");
      throw Exception('Falha ao carregar dados');
    }
  }

  // Carrega a região salva
  Future<void> _carregarRegiao() async {
    final prefs = await SharedPreferences.getInstance();
    // Adiciona setState para atualizar a UI
    // Não é estritamente necessário se _dataFuture o usar, mas boa prática.
    if (mounted) {
      setState(() {
        _regiaoAtual =
            prefs.getString('regiaoSelecionada') ?? 'São Mateus do Sul, PR';
      });
    }
  }

  // Ação de "Puxar para Atualizar"
  Future<void> _refreshData() async {
    // Recarrega a região e os dados
    await _carregarRegiao();
    setState(() {
      _dataFuture = _loadJsonData();
    });
    // Aguarda o futuro completar para o indicador de refresh sumir
    await _dataFuture;
  }

  // Gera a mensagem de alerta baseada no clima e boletim
  String _getAlerta(Clima clima, Boletim boletim) {
    if (clima.tempMin <= 5) {
      return "Risco de geada forte. Proteja os ervais jovens!";
    }
    if (clima.chuvaMm > 10) {
      return "Chuva intensa. Evite colheita e manejo de solo.";
    }
    // Retorna o título do último boletim como alerta padrão
    return boletim.titulo;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ervex'),
        // Remove o "leading" (botão de voltar)
        automaticallyImplyLeading: false,
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

          // Listas de dados
          final climaList = snapshot.data!['clima'] as List<Clima>;
          final boletimList = snapshot.data!['boletins'] as List<Boletim>;

          // --- CORREÇÃO: Encontrar "Hoje" ---
          final now = DateTime.now();
          final hoje = climaList.firstWhere(
            (clima) => DateUtils.isSameDay(clima.data, now),
            // Fallback: se "hoje" (13/11) não estiver no JSON, pega o primeiro item
            orElse: () => climaList.first,
          );

          // --- CORREÇÃO: Pegar próximos dias (que não são hoje) ---
          final proximosDias = climaList
              .where((clima) =>
                  !DateUtils.isSameDay(clima.data, now) &&
                  clima.data.isAfter(now))
              .take(7)
              .toList();

          final alerta = _getAlerta(hoje, boletimList.first);

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                      _regiaoAtual, // Exibe a região do estado
                      style: textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- Card de Alerta Principal ---
                _AlertCard(
                  alerta: alerta,
                  onTap: () => context.go('/boletins'),
                ),
                const SizedBox(height: 24),

                // --- Card de Resumo de Hoje ---
                _ResumoHojeCard(clima: hoje),
                const SizedBox(height: 24),

                // --- Título "Próximos Dias" ---
                Text(
                  'Próximos Dias',
                  style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // --- Carrossel Próximos Dias ---
                // Altura aumentada para 155 para corrigir o overflow
                SizedBox(
                  height: 155,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: proximosDias.length,
                    itemBuilder: (context, index) {
                      return _ProximoDiaCard(clima: proximosDias[index]);
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // --- Cards de Navegação ---
                Text(
                  'Atalhos',
                  style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _NavigationCard(
                        icon: Icons.wb_sunny,
                        label: 'Previsão Detalhada',
                        onTap: () => context.go('/clima'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _NavigationCard(
                        icon: Icons.article,
                        label: 'Ver Boletins',
                        onTap: () => context.go('/boletins'),
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

// --- WIDGETS AUXILIARES DA TELA ---

// Card de Alerta (Topo)
class _AlertCard extends StatelessWidget {
  final String alerta;
  final VoidCallback onTap;

  const _AlertCard({required this.alerta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.primary,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.warning, color: colorScheme.onPrimary, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  alerta,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: colorScheme.onPrimary),
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: colorScheme.onPrimary),
            ],
          ),
        ),
      ),
    );
  }
}

// Card de Resumo do Dia (Hoje)
class _ResumoHojeCard extends StatelessWidget {
  final Clima clima;
  const _ResumoHojeCard({required this.clima});

  // Determina o ícone com base na chuva
  IconData _getWeatherIcon(double chuvaMm) {
    if (chuvaMm == 0) return Icons.wb_sunny;
    if (chuvaMm < 5) return Icons.cloud_queue;
    return Icons.water_drop;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // --- CORREÇÃO: Checar se é 'hoje' ---
    final bool isHoje = DateUtils.isSameDay(clima.data, DateTime.now());
    final String dataFormatada =
        DateFormat('d \'de\' MMMM', 'pt_BR').format(clima.data);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Ícone do Clima
            Icon(
              _getWeatherIcon(clima.chuvaMm),
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            // Informações
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // --- CORREÇÃO: Usar a string correta ---
                    isHoje ? 'Hoje, $dataFormatada' : dataFormatada,
                    style: textTheme.titleSmall
                        ?.copyWith(color: textTheme.bodySmall?.color),
                  ),
                  Text(
                    '${clima.tempMin.round()}° - ${clima.tempMax.round()}°',
                    style: textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            // Precipitação
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Chuva',
                  style: textTheme.titleSmall
                      ?.copyWith(color: textTheme.bodySmall?.color),
                ),
                Text(
                  '${clima.chuvaMm.toStringAsFixed(1)} mm',
                  style: textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Card do Carrossel (Próximos Dias)
class _ProximoDiaCard extends StatelessWidget {
  final Clima clima;
  const _ProximoDiaCard({required this.clima});

  IconData _getWeatherIcon(double chuvaMm) {
    if (chuvaMm == 0) return Icons.wb_sunny;
    if (chuvaMm < 5) return Icons.cloud_queue;
    return Icons.water_drop;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final diaSemana = DateFormat('EEE', 'pt_BR').format(clima.data);

    return Card(
      child: Container(
        width: 110,
        padding: const EdgeInsets.all(12.0),
        child: Column(
          // CORREÇÃO: Alinhamento central para corrigir o visual "torto".
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              // Deixa o dia da semana maiúsculo e com cor
              diaSemana.toUpperCase().replaceAll('.', ''),
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary, // Deixa mais bonito
              ),
            ),
            const SizedBox(height: 8),
            // Ícone (não precisa mais de 'Center')
            Icon(
              _getWeatherIcon(clima.chuvaMm),
              size: 32,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 8),
            // Temperatura (não precisa mais de 'Center')
            Text(
              '${clima.tempMin.round()}° - ${clima.tempMax.round()}°',
              style: textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            // Chuva (não precisa mais de 'Center')
            Text(
              '${clima.chuvaMm.toStringAsFixed(1)} mm',
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// Card de Navegação (Atalhos)
class _NavigationCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavigationCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}