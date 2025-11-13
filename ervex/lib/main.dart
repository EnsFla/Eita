import 'package:flutter/material.dart';
import 'package:ervex/app_router.dart';
import 'package:ervex/theme.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  // Garante a inicialização do Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa a formatação de datas para o local pt_BR
  await initializeDateFormatting('pt_BR', null);
  
  runApp(const ErvexApp());
}

class ErvexApp extends StatelessWidget {
  const ErvexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Ervex Demo',
      // Remove o banner de debug
      debugShowCheckedModeBanner: false,
      
      // Configuração do Tema
      theme: ErvexTheme.lightTheme,
      
      // Configuração do GoRouter
      routerConfig: appRouter,
    );
  }
}