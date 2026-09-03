import 'package:flutter/material.dart';
import 'package:horas_trabajo/features/home/home_tab.dart';
import 'package:horas_trabajo/features/history/history_tab.dart';
import 'package:horas_trabajo/features/report/report_tab.dart';
import 'package:horas_trabajo/features/settings/settings_tab.dart';

/// Muestra la navegación inferior (Material 3) entre las 4 secciones.
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;

  static const _pantallas = [
    HomeTab(),
    HistoryTab(),
    ReportTab(),
    SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _CrossfadeIndexedStack(index: _index, children: _pantallas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.play_circle_outline),
            selectedIcon: Icon(Icons.play_circle_fill),
            label: 'Marcar',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Historial',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Reporte',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}

/// Como [IndexedStack], mantiene todas las pantallas montadas (sin perder su
/// estado al cambiar de pestaña — temporizadores, controladores de texto,
/// reconocimiento de voz, etc.), pero cruza con un fade + leve deslizamiento
/// hacia la pantalla activa en vez de cortar en seco.
class _CrossfadeIndexedStack extends StatelessWidget {
  const _CrossfadeIndexedStack({required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (var i = 0; i < children.length; i++)
          IgnorePointer(
            ignoring: i != index,
            child: AnimatedOpacity(
              opacity: i == index ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: AnimatedSlide(
                offset: i == index ? Offset.zero : const Offset(0, 0.02),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: children[i],
              ),
            ),
          ),
      ],
    );
  }
}
