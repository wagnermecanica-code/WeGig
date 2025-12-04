// COMO INTEGRAR O NOVO DESIGN SYSTEM NO APP

// 1. No pubspec.yaml, adicione as fontes:
/*
dependencies:
  flutter:
    sdk: flutter

flutter:
  fonts:
    - family: Montserrat
      fonts:
        - asset: assets/fonts/Montserrat-Bold.ttf
          weight: 700
    - family: Roboto
      fonts:
        - asset: assets/fonts/Roboto-Regular.ttf
          weight: 400
        - asset: assets/fonts/Roboto-Medium.ttf
          weight: 500
        - asset: assets/fonts/Roboto-Bold.ttf
          weight: 700
*/

// 2. No main.dart, importe o theme:
/*
import 'package:flutter/material.dart';
import 'package:to_sem_banda/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WeGig',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: HomePage(),
    );
  }
}
*/

// 3. RESUMO DAS MELHORIAS IMPLEMENTADAS:

/*
✅ DESIGN SYSTEM COMPLETO:
   - Paleta de cores consistente (Azul #007AFF para músicos, Roxo #9C27B0 para bandas)
   - Amarelo #FFD600 para destaques (níveis)
   - Cores neutras configuradas para Light e Dark mode
   
✅ TIPOGRAFIA:
   - Montserrat Bold para títulos
   - Roboto Regular/Medium para textos e botões
   - Estilos pré-definidos (h1, h2, h3, subtitle, body, caption, button)
   
✅ COMPONENTES ATUALIZADOS:
   - AppBar: Com botão de alternância de tema, título estilizado
   - Cards: Bordas arredondadas (20px), sombras suaves, espaçamento interno melhorado
   - Chips: Cores consistentes com paleta, tamanho proporcional
   - Botões: Arredondados (12px), cores primárias/secundárias
   - Inputs: Bordas arredondadas, estados de foco destacados
   
✅ MAPA:
   - Pins circulares com ícone de nota musical
   - Músicos: 1 nota musical
   - Bandas: 2 notas musicais
   - Animação de pulso ao selecionar
   - Sombra suave para profundidade
   
✅ DARK MODE:
   - Fundo #121212, superfícies #1E1E1E
   - Textos #FFFFFF e #B3B3B3
   - Bordas #333333
   - Alternância via botão no AppBar
   
✅ CONSISTÊNCIA VISUAL:
   - Todos os componentes seguem o mesmo design language
   - Espaçamentos consistentes
   - Hierarquia visual clara
   - Contraste adequado para acessibilidade
*/

// 4. PRÓXIMOS PASSOS OPCIONAIS:
/*
- Adicionar animações de transição entre telas
- Implementar skeleton loading para imagens
- Adicionar haptic feedback nos botões
- Implementar splash screen com branding
- Adicionar onboarding para novos usuários
*/

// 5. COMO USAR O THEME EM OUTRAS PÁGINAS:
/*
// Exemplo em qualquer página:
import 'package:to_sem_banda/theme/app_theme.dart';

class MinhaPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Título',
          style: isDark ? AppTypography.h3Dark : AppTypography.h3Light,
        ),
      ),
      body: Container(
        child: Column(
          children: [
            // Use as cores do theme
            Container(
              color: AppColors.primary,
              child: Text(
                'Texto',
                style: isDark ? AppTypography.bodyDark : AppTypography.bodyLight,
              ),
            ),
            
            // Botões já estão estilizados automaticamente
            ElevatedButton(
              onPressed: () {},
              child: Text('Botão Primário'),
            ),
            
            OutlinedButton(
              onPressed: () {},
              child: Text('Botão Secundário'),
            ),
            
            // Chips também seguem o theme
            Chip(
              label: Text('Tag'),
              backgroundColor: AppColors.musicianLight,
            ),
          ],
        ),
      ),
    );
  }
}
*/
