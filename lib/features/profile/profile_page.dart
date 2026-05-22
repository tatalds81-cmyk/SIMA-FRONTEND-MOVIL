import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: ColoredBox(
        color: _ProfileColors.background,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                child: _ProfileTopBar(
                  onSettingsTap: () => _showAccountOptionsModal(context),
                ),
              ),
              const _ProfileIdentityHeader(),
              const _ProfileTabBar(),
              Expanded(
                child: TabBarView(
                  children: [
                    _ProfileTabBody(
                      children: [
                        const _ProfileProgressBlock(),
                        const SizedBox(height: 18),
                        const _SectionHeader(title: 'Accesos del perfil'),
                        const SizedBox(height: 8),
                        _ProfileActionTile(
                          icon: Icons.person_outline_rounded,
                          title: 'Datos personales',
                          subtitle: 'Documento y contacto',
                          onTap: () => _showPersonalInformationModal(context),
                        ),
                        _ProfileActionTile(
                          icon: Icons.health_and_safety_outlined,
                          title: 'Emergencia',
                          subtitle: 'Contacto principal',
                          onTap: () => _showEmergencyContactModal(context),
                        ),
                        _ProfileActionTile(
                          icon: Icons.lock_outline_rounded,
                          title: 'Seguridad',
                          subtitle: 'Cambiar contraseña',
                          onTap: () => _showChangePasswordModal(context),
                        ),
                        _ProfileActionTile(
                          icon: Icons.notifications_none_rounded,
                          title: 'Notificaciones',
                          subtitle: 'Alertas y avisos',
                          onTap: () => _showNotificationsModal(context),
                        ),
                      ],
                    ),
                    _ProfileTabBody(
                      children: [
                        const _SectionHeader(title: 'Resumen académico'),
                        const SizedBox(height: 8),
                        const _AcademicInlineSummary(),
                        const SizedBox(height: 18),
                        const _SectionHeader(title: 'Documentos'),
                        const SizedBox(height: 8),
                        _DocumentInlineTile(
                          icon: Icons.badge_outlined,
                          title: 'Carnet digital',
                          subtitle: 'Disponible para identificación',
                          color: _ProfileColors.green,
                          onTap: () => _showMessage(
                            context,
                            'Carnet digital en revisión.',
                          ),
                        ),
                        _DocumentInlineTile(
                          icon: Icons.description_outlined,
                          title: 'Certificado de matrícula',
                          subtitle: 'Última actualización: mayo 2024',
                          color: _ProfileColors.blue,
                          onTap: () =>
                              _showMessage(context, 'Documento pendiente.'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showPersonalInformationModal(BuildContext context) {
  _showProfileModal(
    context,
    title: 'Información personal',
    actionText: 'Editar información',
    onAction: () {
      _showMessage(context, 'Edición de información pendiente de conectar.');
    },
    children: const [
      _InfoField(label: 'Nombres', value: 'Juan'),
      _InfoField(label: 'Apellidos', value: 'Pérez García'),
      _InfoField(label: 'Tipo de documento', value: 'Cédula de ciudadanía'),
      _InfoField(label: 'Número de documento', value: '1.123.456.789'),
      _InfoField(label: 'Fecha de nacimiento', value: '12/05/2002'),
      _InfoField(
        label: 'Correo institucional',
        value: 'juan.perez@misena.edu.co',
      ),
      _InfoField(label: 'Teléfono', value: '300 123 4567'),
    ],
  );
}

void _showEmergencyContactModal(BuildContext context) {
  _showProfileModal(
    context,
    title: 'Contacto de emergencia',
    actionText: 'Editar contacto',
    onAction: () {
      _showMessage(context, 'Edición de contacto pendiente de conectar.');
    },
    children: const [
      _InfoField(label: 'Nombre completo', value: 'María García'),
      _InfoField(label: 'Parentesco', value: 'Madre'),
      _InfoField(label: 'Teléfono', value: '310 456 7890'),
      _InfoField(label: 'Correo', value: 'maria.garcia@email.com'),
      _InfoField(label: 'Dirección', value: 'Cra. 12 #45-67, Bogotá'),
    ],
  );
}

void _showChangePasswordModal(BuildContext context) {
  _showProfileModal(
    context,
    title: 'Cambiar contraseña',
    actionText: 'Guardar contraseña',
    onAction: () {
      _showMessage(context, 'Contraseña lista para enviarse al backend.');
    },
    children: const [
      _PasswordField(label: 'Contraseña actual'),
      SizedBox(height: 16),
      _PasswordField(label: 'Nueva contraseña'),
      SizedBox(height: 16),
      _PasswordField(label: 'Confirmar contraseña'),
      SizedBox(height: 18),
      _PasswordHint(),
    ],
  );
}

void _showNotificationsModal(BuildContext context) {
  _showProfileModal(
    context,
    title: 'Notificaciones',
    actionText: 'Guardar cambios',
    onAction: () {
      _showMessage(context, 'Preferencias de notificación guardadas.');
    },
    children: const [_NotificationsModalContent()],
  );
}

void _showAccountOptionsModal(BuildContext context) {
  _showProfileModal(
    context,
    title: 'Cuenta',
    actionText: 'Cerrar',
    onAction: () {},
    children: [
      _ProfileMenuTile(
        icon: Icons.support_agent_rounded,
        title: 'Ayuda y soporte',
        onTap: () => _showMessage(context, 'Soporte pendiente de conectar.'),
      ),
      _ProfileMenuTile(
        icon: Icons.logout_rounded,
        title: 'Cerrar sesión',
        color: _ProfileColors.danger,
        showChevron: false,
        onTap: () => _showMessage(context, 'Sesión cerrada localmente.'),
      ),
    ],
  );
}

void _showObservationsModal(BuildContext context) {
  _showProfileModal(
    context,
    title: 'Observaciones',
    actionText: 'Cerrar',
    onAction: () {},
    children: const [
      _ObservationSummary(),
      SizedBox(height: 18),
      _ObservationItem(
        title: 'Seguimiento académico',
        date: '14 mayo 2024',
        author: 'Instructor Carlos Ramírez',
        description:
            'Se recomienda reforzar la entrega de evidencias y mantener participación constante en clase.',
        color: _ProfileColors.amber,
      ),
      _ObservationItem(
        title: 'Bienestar al aprendiz',
        date: '08 mayo 2024',
        author: 'Equipo de bienestar',
        description:
            'Aprendiz citado a acompañamiento preventivo. Se observa buena disposición durante la atención.',
        color: _ProfileColors.green,
      ),
      _ObservationItem(
        title: 'Asistencia',
        date: '29 abril 2024',
        author: 'Coordinación académica',
        description:
            'Registra dos ausencias recientes. Debe cargar soporte o justificación dentro de las fechas establecidas.',
        color: _ProfileColors.danger,
        showDivider: false,
      ),
    ],
  );
}

void _showProfileModal(
  BuildContext context, {
  required String title,
  required String actionText,
  required List<Widget> children,
  required VoidCallback onAction,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (modalContext) {
      return _ProfileModalSheet(
        title: title,
        actionText: actionText,
        onAction: () {
          FocusScope.of(modalContext).unfocus();
          Navigator.of(modalContext).pop();
          onAction();
        },
        children: children,
      );
    },
  );
}

class _ProfileModalSheet extends StatelessWidget {
  const _ProfileModalSheet({
    required this.title,
    required this.actionText,
    required this.children,
    required this.onAction,
  });

  final String title;
  final String actionText;
  final List<Widget> children;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.86;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6DEE8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 16, 10, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: _ProfileColors.navy,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Cerrar',
                        icon: const Icon(Icons.close_rounded),
                        color: _ProfileColors.navy,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
                    children: children,
                  ),
                ),
                SafeArea(
                  top: false,
                  minimum: const EdgeInsets.fromLTRB(22, 0, 22, 18),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _ProfileColors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      onPressed: onAction,
                      child: Text(actionText),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationsModalContent extends StatefulWidget {
  const _NotificationsModalContent();

  @override
  State<_NotificationsModalContent> createState() =>
      _NotificationsModalContentState();
}

class _NotificationsModalContentState
    extends State<_NotificationsModalContent> {
  bool allowNotifications = true;
  bool classReminders = true;
  bool attendanceRegister = true;
  bool absenceJustifications = true;
  bool evaluations = true;
  bool recommendations = true;
  bool wellbeing = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _NotificationSwitchTile(
          title: 'Permitir notificaciones',
          value: allowNotifications,
          onChanged: (value) => setState(() {
            allowNotifications = value;
          }),
        ),
        const SizedBox(height: 22),
        const _SectionTitle('Asistencias'),
        _NotificationSwitchTile(
          title: 'Recordatorios de clase',
          value: classReminders,
          onChanged: allowNotifications
              ? (value) => setState(() {
                  classReminders = value;
                })
              : null,
        ),
        _NotificationSwitchTile(
          title: 'Registro de asistencia',
          value: attendanceRegister,
          onChanged: allowNotifications
              ? (value) => setState(() {
                  attendanceRegister = value;
                })
              : null,
        ),
        _NotificationSwitchTile(
          title: 'Justificaciones',
          value: absenceJustifications,
          onChanged: allowNotifications
              ? (value) => setState(() {
                  absenceJustifications = value;
                })
              : null,
        ),
        const SizedBox(height: 22),
        const _SectionTitle('Observatorio'),
        _NotificationSwitchTile(
          title: 'Evaluaciones',
          value: evaluations,
          onChanged: allowNotifications
              ? (value) => setState(() {
                  evaluations = value;
                })
              : null,
        ),
        _NotificationSwitchTile(
          title: 'Recomendaciones',
          value: recommendations,
          onChanged: allowNotifications
              ? (value) => setState(() {
                  recommendations = value;
                })
              : null,
        ),
        _NotificationSwitchTile(
          title: 'Bienestar',
          value: wellbeing,
          onChanged: allowNotifications
              ? (value) => setState(() {
                  wellbeing = value;
                })
              : null,
        ),
      ],
    );
  }
}

class _ObservationSummary extends StatelessWidget {
  const _ObservationSummary();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '3',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: _ProfileColors.amber,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Observaciones activas para revisar con el equipo de seguimiento.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _ProfileColors.muted,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _ObservationItem extends StatelessWidget {
  const _ObservationItem({
    required this.title,
    required this.date,
    required this.author,
    required this.description,
    required this.color,
    this.showDivider = true,
  });

  final String title;
  final String date;
  final String author;
  final String description;
  final Color color;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: _ProfileColors.line))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(Icons.sticky_note_2_outlined, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _ProfileColors.navy,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      date,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _ProfileColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _ProfileColors.green,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _ProfileColors.muted,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileIdentityHeader extends StatelessWidget {
  const _ProfileIdentityHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      color: _ProfileColors.navy,
      child: Row(
        children: [
          const _ProfileAvatar(size: 58),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Juan Pérez García',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Aprendiz SENA',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _HeaderChip(text: 'Ficha 1234567'),
                    _HeaderChip(text: 'Etapa lectiva'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ProfileTabBar extends StatelessWidget {
  const _ProfileTabBar();

  @override
  Widget build(BuildContext context) {
    return const Material(
      color: Colors.white,
      child: TabBar(
        labelColor: _ProfileColors.green,
        unselectedLabelColor: _ProfileColors.muted,
        indicatorColor: _ProfileColors.green,
        indicatorWeight: 3,
        labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        unselectedLabelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        tabs: [
          Tab(text: 'Perfil'),
          Tab(text: 'Académico'),
        ],
      ),
    );
  }
}

class _ProfileTabBody extends StatelessWidget {
  const _ProfileTabBody({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
      children: children,
    );
  }
}

class _ProfileProgressBlock extends StatelessWidget {
  const _ProfileProgressBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Perfil del aprendiz',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: _ProfileColors.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '86%',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _ProfileColors.green,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: const LinearProgressIndicator(
            value: 0.86,
            minHeight: 7,
            color: _ProfileColors.green,
            backgroundColor: Color(0xFFE2EADF),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Expanded(
              child: _ProfileProgressMetric(
                label: 'Asistencias',
                value: '18',
                color: _ProfileColors.green,
              ),
            ),
            const _VerticalDivider(),
            const Expanded(
              child: _ProfileProgressMetric(
                label: 'Ausencias',
                value: '2',
                color: _ProfileColors.danger,
              ),
            ),
            const _VerticalDivider(),
            Expanded(
              child: _ProfileProgressMetric(
                label: 'Observaciones',
                value: '3',
                color: _ProfileColors.amber,
                onTap: () => _showObservationsModal(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileProgressMetric extends StatelessWidget {
  const _ProfileProgressMetric({
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded, color: color, size: 18),
            ],
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: _ProfileColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: content,
        ),
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _ProfileColors.line)),
          ),
          child: Row(
            children: [
              Icon(icon, color: _ProfileColors.green, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _ProfileColors.navy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _ProfileColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _ProfileColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AcademicInlineSummary extends StatelessWidget {
  const _AcademicInlineSummary();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _ProfileInfoTile(
          icon: Icons.school_outlined,
          label: 'Programa',
          value: 'Desarrollo de Software',
        ),
        _ProfileInfoTile(
          icon: Icons.confirmation_number_outlined,
          label: 'Ficha',
          value: '1234567',
        ),
        _ProfileInfoTile(
          icon: Icons.business_outlined,
          label: 'Centro',
          value: 'Centro de Tecnología',
        ),
        _ProfileInfoTile(
          icon: Icons.schedule_rounded,
          label: 'Horario',
          value: 'Lun. a Vie. 7:00 a. m. - 12:00 p. m.',
        ),
        _ProfileInfoTile(
          icon: Icons.location_on_outlined,
          label: 'Ambiente',
          value: 'Aula 301 - Bloque B',
          showDivider: false,
        ),
      ],
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  const _ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: _ProfileColors.line))
            : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: _ProfileColors.green, size: 21),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _ProfileColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _ProfileColors.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentInlineTile extends StatelessWidget {
  const _DocumentInlineTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _ProfileColors.line)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _ProfileColors.navy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _ProfileColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _ProfileColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _ApprenticeCredentialCard extends StatelessWidget {
  const _ApprenticeCredentialCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_ProfileColors.navy, Color(0xFF0B416A)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _ProfileColors.navy.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _ProfileAvatar(size: 74),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            'Juan Pérez García',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  height: 1.08,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const _StatusChip(text: 'Activo'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aprendiz SENA',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ficha 1234567',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFF315A78)),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(
                child: _CredentialDetail(
                  label: 'Programa',
                  value: 'Desarrollo de Software',
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: _CredentialDetail(
                  label: 'Centro',
                  value: 'Centro de Tecnología',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(
                child: _CredentialDetail(label: 'Jornada', value: 'Diurna'),
              ),
              SizedBox(width: 14),
              Expanded(
                child: _CredentialDetail(label: 'Etapa', value: 'Lectiva'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CredentialDetail extends StatelessWidget {
  const _CredentialDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.66),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _ProfileColors.green.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _ProfileColors.greenLight),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

// ignore: unused_element
class _ProfileCompletionCard extends StatelessWidget {
  const _ProfileCompletionCard();

  @override
  Widget build(BuildContext context) {
    return _ProfileSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Perfil del aprendiz',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: _ProfileColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '86%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _ProfileColors.green,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Información completa y lista para seguimiento académico.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _ProfileColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: const LinearProgressIndicator(
              value: 0.86,
              minHeight: 9,
              color: _ProfileColors.green,
              backgroundColor: Color(0xFFE9F2E5),
            ),
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(
                child: _ProfileStat(
                  label: 'Asistencias',
                  value: '18',
                  color: _ProfileColors.green,
                ),
              ),
              _VerticalDivider(),
              Expanded(
                child: _ProfileStat(
                  label: 'Ausencias',
                  value: '2',
                  color: _ProfileColors.danger,
                ),
              ),
              _VerticalDivider(),
              Expanded(
                child: _ProfileStat(
                  label: 'Bienestar',
                  value: '85%',
                  color: _ProfileColors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: _ProfileColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 38, color: _ProfileColors.line);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: _ProfileColors.navy,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

// ignore: unused_element
class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _ProfileColors.line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _ProfileColors.greenPale,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _ProfileColors.green, size: 21),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _ProfileColors.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: _ProfileColors.muted,
                  fontWeight: FontWeight.w600,
                  height: 1.22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _AcademicSummaryCard extends StatelessWidget {
  const _AcademicSummaryCard();

  @override
  Widget build(BuildContext context) {
    return const _ProfileSurface(
      child: Column(
        children: [
          _InfoMiniRow(
            icon: Icons.school_outlined,
            label: 'Programa',
            value: 'Desarrollo de Software',
          ),
          _InfoMiniRow(
            icon: Icons.confirmation_number_outlined,
            label: 'Ficha',
            value: '1234567',
          ),
          _InfoMiniRow(
            icon: Icons.business_outlined,
            label: 'Centro',
            value: 'Centro de Tecnología',
          ),
          _InfoMiniRow(
            icon: Icons.schedule_rounded,
            label: 'Horario',
            value: 'Lun. a Vie. 7:00 a. m. - 12:00 p. m.',
          ),
          _InfoMiniRow(
            icon: Icons.location_on_outlined,
            label: 'Ambiente',
            value: 'Aula 301 - Bloque B',
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _DocumentsCard extends StatelessWidget {
  const _DocumentsCard();

  @override
  Widget build(BuildContext context) {
    return _ProfileSurface(
      child: Column(
        children: [
          _DocumentRow(
            icon: Icons.badge_outlined,
            title: 'Carnet digital',
            subtitle: 'Disponible para identificación',
            color: _ProfileColors.green,
            onTap: () => _showMessage(context, 'Carnet digital en revisión.'),
          ),
          const Divider(height: 18, color: _ProfileColors.line),
          _DocumentRow(
            icon: Icons.description_outlined,
            title: 'Certificado de matrícula',
            subtitle: 'Última actualización: mayo 2024',
            color: _ProfileColors.blue,
            onTap: () => _showMessage(context, 'Documento pendiente.'),
          ),
        ],
      ),
    );
  }
}

class _InfoMiniRow extends StatelessWidget {
  const _InfoMiniRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: _ProfileColors.green, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _ProfileColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _ProfileColors.navy,
                      fontWeight: FontWeight.w800,
                      height: 1.22,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: _ProfileColors.line),
          ),
      ],
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 23),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _ProfileColors.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _ProfileColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: _ProfileColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSurface extends StatelessWidget {
  const _ProfileSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _ProfileColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar({required this.onSettingsTap});

  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'Perfil',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: _ProfileColors.navy,
              fontWeight: FontWeight.w800,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: 'Configuración',
              icon: const Icon(Icons.settings_outlined),
              color: _ProfileColors.navy,
              onPressed: onSettingsTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({this.size = 78});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFEAF3E7), Color(0xFFCDEAC2)],
            ),
            border: Border.all(color: Colors.white, width: 4),
          ),
          alignment: Alignment.center,
          child: Text(
            'JP',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: _ProfileColors.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Positioned(
          right: 3,
          bottom: 3,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: _ProfileColors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color = _ProfileColors.navy,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color color;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _ProfileColors.line)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (showChevron)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: _ProfileColors.navy,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  const _InfoField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _ProfileColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _ProfileColors.navy,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: _ProfileColors.line),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.visibility_off_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _ProfileColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _ProfileColors.green, width: 1.5),
        ),
      ),
    );
  }
}

class _PasswordHint extends StatelessWidget {
  const _PasswordHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDEED5)),
      ),
      child: Text(
        'Usa mínimo 8 caracteres e incluye letras, números y un símbolo.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: _ProfileColors.navy,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      ),
    );
  }
}

class _NotificationSwitchTile extends StatelessWidget {
  const _NotificationSwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _ProfileColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: onChanged == null
                    ? _ProfileColors.muted
                    : _ProfileColors.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Theme(
            data: Theme.of(context).copyWith(
              switchTheme: SwitchThemeData(
                thumbColor: WidgetStateProperty.all(Colors.white),
                trackColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.disabled)) {
                    return const Color(0xFFE3E8EF);
                  }
                  if (states.contains(WidgetState.selected)) {
                    return _ProfileColors.green;
                  }
                  return const Color(0xFFD8DEE7);
                }),
                trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              ),
            ),
            child: Switch(value: value, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: _ProfileColors.navy,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: _ProfileColors.navy,
    ),
  );
}

abstract final class _ProfileColors {
  static const background = Color(0xFFF5F7F8);
  static const green = Color(0xFF2FA312);
  static const greenLight = Color(0xFF8ED36B);
  static const greenPale = Color(0xFFEAF6E5);
  static const navy = Color(0xFF062E4F);
  static const blue = Color(0xFF1D75BB);
  static const amber = Color(0xFFF5A400);
  static const muted = Color(0xFF6F7C8E);
  static const line = Color(0xFFE9EDF2);
  static const danger = Color(0xFFE04444);
}
