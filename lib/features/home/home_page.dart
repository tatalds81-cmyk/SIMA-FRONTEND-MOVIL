import 'package:flutter/material.dart';
import 'package:sima_movil_froned/widgets/feature_placeholder.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Inicio',
      subtitle: 'Pantalla principal de SIMA',
    );
  }
}
