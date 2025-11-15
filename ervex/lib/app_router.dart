import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ervex/screens/home_screen.dart';
import 'package:ervex/screens/clima_screen.dart';
import 'package:ervex/screens/boletins_screen.dart';
import 'package:ervex/screens/perfil_screen.dart';
import 'package:ervex/screens/learn_screen.dart'; // Importa a nova tela
import 'package:ervex/widgets/scaffold_with_nav_bar.dart';

// Chave global para o Navigator principal
final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  initialLocation: '/home',
  navigatorKey: _rootNavigatorKey,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      // --- ATUALIZADO PARA SEGUIR O ESBOÇO ---
      branches: [
        // Ramo 0: Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),

        // Ramo 1: News (Tela de Boletins)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/boletins',
              builder: (context, state) => const BoletinsScreen(),
            ),
          ],
        ),

        // Ramo 2: Learn (Nova Tela)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/learn',
              builder: (context, state) => const LearnScreen(),
            ),
          ],
        ),

        // Ramo 3: Config (Tela de Perfil/Região)
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

    // --- IMPORTANTE: A tela de Clima agora não está no menu ---
    // Mas ainda pode ser acessada por um link, se precisarmos.
    // Por enquanto, vou deixá-la aqui para não quebrar o import.
    GoRoute(
      path: '/clima',
      // Redireciona para a home se tentarem acessar a rota antiga
      redirect: (context, state) => '/home',
      // builder: (context, state) => const ClimaScreen(),
    ),
  ],
);