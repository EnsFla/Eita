import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ErvexTheme {
  // Cor primária definida na identidade visual
  static const Color _primaryColor = Color(0xFF4C8A2B);

  // Paleta de cores base
  static final _colorScheme = ColorScheme.fromSeed(
    seedColor: _primaryColor,
    primary: _primaryColor,
    brightness: Brightness.light,
    // Tons terrosos e neutros
    surface: const Color(0xFFFBFBFA),
    onSurface: const Color(0xFF1C1C16),
    surfaceContainer: const Color(0xFFF3F2EE),
  );

  // Tema claro (Light Mode)
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: _colorScheme,
    
    // Configuração da fonte Poppins
    textTheme: GoogleFonts.poppinsTextTheme(
      ThemeData.light().textTheme,
    ).apply(
      bodyColor: _colorScheme.onSurface,
      displayColor: _colorScheme.onSurface,
    ),
    
    // Estilo dos Scaffolds
    scaffoldBackgroundColor: _colorScheme.surface,
    
    // Estilo dos AppBars
    appBarTheme: AppBarTheme(
      backgroundColor: _colorScheme.surface,
      surfaceTintColor: Colors.transparent, // Remove tint de elevação
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: _colorScheme.primary,
      ),
    ),
    
    // Estilo dos Cards
    cardTheme: CardThemeData(
      elevation: 0,
      color: _colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    
    // Estilo da Barra de Navegação
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _colorScheme.surfaceContainer,
      indicatorColor: _colorScheme.primary.withOpacity(0.2),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: _colorScheme.primary);
        }
        return IconThemeData(color: _colorScheme.onSurface.withOpacity(0.6));
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final style = GoogleFonts.poppins(fontSize: 12);
        if (states.contains(WidgetState.selected)) {
          return style.copyWith(
              color: _colorScheme.primary, fontWeight: FontWeight.w600);
        }
        return style.copyWith(
            color: _colorScheme.onSurface.withOpacity(0.6));
      }),
    ),
  );
}