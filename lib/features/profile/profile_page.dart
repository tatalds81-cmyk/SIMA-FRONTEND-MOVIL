import 'package:flutter/material.dart';
import 'package:sima_movil_froned/widgets/feature_placeholder.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Perfil',
      subtitle: 'Datos del usuario',
    );
  }
}
