import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ervex/screens/home_screen.dart';
import 'package:ervex/screens/clima_screen.dart';
import 'package:ervex/screens/boletins_screen.dart';
import 'package:ervex/screens/perfil_screen.dart';
import 'package:ervex/widgets/scaffold_with_nav_bar.dart';

// Chave global para o Navigator principal
final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  initialLocation: '/home',
  navigatorKey: _rootNavigatorKey,
  routes: [
    // --- CORREÇÃO: Usando a API correta do GoRouter v14 ---
    // Isto usa o "Stateful" ShellRoute, que preserva o estado das abas
    // (mas corrigimos o problema de atualização automática em outro lugar).
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        // O 'Shell' do app (Scaffold com BottomNavBar)
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        // Ramo 1: Home
        // --- CORREÇÃO: Usando a classe correta "StatefulShellBranch" ---
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),

        // Ramo 2: Clima
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/clima',
              builder: (context, state) => const ClimaScreen(),
            ),
          ],
        ),

        // Ramo 3: Boletins
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/boletins',
              builder: (context, state) => const BoletinsScreen(),
            ),
          ],
        ),

        // Ramo 4: Perfil
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/perfil',
              builder: (context, state) => const PerfilScreen(),
            ),
          ],
        ),
      ],
    ),

    // Rotas fora do Shell (ex: tela de detalhes de um boletim)
    // Ex:
    // GoRoute(
    //   path: '/boletim/:id',
    //   builder: (context, state) {
    //     final id = state.pathParameters['id']!;
    //     return BoletimDetailScreen(id: id);
    //   },
    // ),
  ],
);