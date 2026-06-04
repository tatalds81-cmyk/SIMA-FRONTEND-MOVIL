import 'package:flutter/material.dart';
import 'package:sima_movil_froned/features/login/login_page.dart';
import 'package:sima_movil_froned/features/profile/data/profile_repository.dart';
import 'package:sima_movil_froned/features/profile/models/apprentice_profile.dart';
import 'package:sima_movil_froned/theme/app_colors.dart';

const _wideBreakpoint = 760.0;

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    this.repository = const BackendProfileRepository(),
  });

  final ProfileRepository repository;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<ApprenticeProfile> _profileFuture;
  ApprenticeProfile? _profile;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<ApprenticeProfile> _loadProfile() async {
    final profile = await widget.repository.fetchCurrentApprenticeProfile();
    _profile = profile;
    return profile;
  }

  void _reload() {
    setState(() {
      _profileFuture = _loadProfile();
    });
  }

  void _setProfile(ApprenticeProfile profile) {
    setState(() {
      _profile = profile;
      _profileFuture = Future.value(profile);
    });
  }

  Future<void> _savePersonalInformation(ApprenticeProfile profile) async {
    final saved = await widget.repository.updatePersonalInformation(profile);

    if (!mounted) {
      return;
    }

    _setProfile(saved);
    _showMessage('Datos personales actualizados.');
  }

  Future<void> _saveEmergencyContact(EmergencyContact contact) async {
    final profile = _profile;
    if (profile == null) {
      return;
    }

    final savedContact = await widget.repository.updateEmergencyContact(
      contact,
    );

    if (!mounted) {
      return;
    }

    _setProfile(profile.copyWith(emergencyContact: savedContact));
    _showMessage('Contacto de emergencia actualizado.');
  }

  Future<void> _changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await widget.repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );

    if (!mounted) {
      return;
    }

    _showMessage('Clave actualizada correctamente.');
  }

  void _showPersonalInformationSheet(ApprenticeProfile profile) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return _PersonalInformationForm(
          profile: profile,
          onSave: _savePersonalInformation,
        );
      },
    );
  }

  void _showAcademicInformationSheet(ApprenticeProfile profile) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return _ReadOnlySheet(
          title: 'Academico',
          actionText: 'Cerrar',
          onAction: () => Navigator.of(sheetContext).pop(),
          children: [
            _SheetInfoField(label: 'Programa', value: profile.program),
            _SheetInfoField(label: 'Ficha', value: profile.ficha),
            _SheetInfoField(label: 'Etapa', value: profile.stage),
            _SheetInfoField(label: 'Horario', value: profile.schedule),
          ],
        );
      },
    );
  }

  void _showEmergencyContactSheet(ApprenticeProfile profile) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return _EmergencyContactForm(
          contact: profile.emergencyContact,
          onSave: _saveEmergencyContact,
        );
      },
    );
  }

  void _showChangePasswordSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return _PasswordForm(onSave: _changePassword);
      },
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cerrar sesion'),
          content: const Text(
            'Quieres salir de tu cuenta en este dispositivo?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: _ProfileColors.danger,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cerrar sesion'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _ProfileColors.navy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _ProfileColors.background,
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= _wideBreakpoint;
            final horizontalPadding = isWide ? 32.0 : 22.0;

            return FutureBuilder<ApprenticeProfile>(
              future: _profileFuture,
              builder: (context, snapshot) {
                final profile = snapshot.data ?? _profile;

                if (profile != null) {
                  final content = _ProfileContent(
                    profile: profile,
                    isWide: isWide,
                    onPersonalTap: () => _showPersonalInformationSheet(profile),
                    onAcademicTap: () => _showAcademicInformationSheet(profile),
                    onEmergencyTap: () => _showEmergencyContactSheet(profile),
                    onLogoutTap: _confirmLogout,
                    onSecurityTap: _showChangePasswordSheet,
                  );

                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 112),
                    child: content,
                  );
                }

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    22,
                    horizontalPadding,
                    112,
                  ),
                  child: snapshot.hasError
                      ? _ProfileStatePanel(
                          icon: Icons.cloud_off_outlined,
                          title: 'No se pudo cargar tu perfil',
                          message: _cleanErrorMessage(snapshot.error),
                          actionLabel: 'Reintentar',
                          onAction: _reload,
                        )
                      : const _ProfileLoading(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.profile,
    required this.isWide,
    required this.onPersonalTap,
    required this.onAcademicTap,
    required this.onEmergencyTap,
    required this.onLogoutTap,
    required this.onSecurityTap,
  });

  final ApprenticeProfile profile;
  final bool isWide;
  final VoidCallback onPersonalTap;
  final VoidCallback onAcademicTap;
  final VoidCallback onEmergencyTap;
  final VoidCallback onLogoutTap;
  final VoidCallback onSecurityTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileHero(
          profile: profile,
          onBackTap: () => Navigator.of(context).maybePop(),
          onLogoutTap: onLogoutTap,
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            isWide ? 32 : 22,
            0,
            isWide ? 32 : 22,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileQuickInfoCard(profile: profile),
              const SizedBox(height: 16),
              _ProfileAccessCard(
                onPersonalTap: onPersonalTap,
                onAcademicTap: onAcademicTap,
                onEmergencyTap: onEmergencyTap,
                onSecurityTap: onSecurityTap,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.profile,
    required this.onBackTap,
    required this.onLogoutTap,
  });

  final ApprenticeProfile profile;
  final VoidCallback onBackTap;
  final VoidCallback onLogoutTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 252,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipPath(
            clipper: const _ProfileHeaderWaveClipper(),
            child: Container(
              height: 160,
              decoration: const BoxDecoration(color: _ProfileColors.headerBlue),
              child: Stack(
                children: const [
                  _HeaderGlow(
                    width: 210,
                    height: 92,
                    left: -68,
                    bottom: 0,
                    opacity: 0.14,
                  ),
                  _HeaderGlow(
                    width: 210,
                    height: 120,
                    right: -58,
                    bottom: 6,
                    opacity: 0.24,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: Row(
              children: [
                _HeaderIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  tooltip: 'Volver',
                  onTap: onBackTap,
                ),
                const Expanded(
                  child: Text(
                    'Mi perfil',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _HeaderIconButton(
                  icon: Icons.logout_rounded,
                  tooltip: 'Cerrar sesion',
                  onTap: onLogoutTap,
                ),
              ],
            ),
          ),
          Positioned(
            top: 72,
            left: 0,
            right: 0,
            child: Center(
              child: _ProfileAvatar(
                size: 86,
                initials: profile.initials,
                showPhoto: true,
              ),
            ),
          ),
          Positioned(
            top: 166,
            left: 24,
            right: 24,
            child: Column(
              children: [
                Text(
                  profile.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _ProfileColors.navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Aprendiz ADSO',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _ProfileColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _HeaderBadge(label: profile.statusLabel),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderGlow extends StatelessWidget {
  const _HeaderGlow({
    required this.width,
    required this.height,
    required this.opacity,
    this.left,
    this.right,
    this.bottom,
  });

  final double width;
  final double height;
  final double opacity;
  final double? left;
  final double? right;
  final double? bottom;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      right: right,
      bottom: bottom,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(999),
        ),
        child: SizedBox(width: width, height: height),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 20),
    );
  }
}

class _ProfileHeaderWaveClipper extends CustomClipper<Path> {
  const _ProfileHeaderWaveClipper();

  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height - 34)
      ..cubicTo(
        size.width * 0.24,
        size.height - 6,
        size.width * 0.58,
        size.height - 68,
        size.width,
        size.height - 26,
      )
      ..lineTo(size.width, 0)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _ProfileQuickInfoCard extends StatelessWidget {
  const _ProfileQuickInfoCard({required this.profile});

  final ApprenticeProfile profile;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: _QuickInfoItem(
              icon: Icons.school_outlined,
              label: 'Ficha',
              value: profile.ficha,
            ),
          ),
          const _VerticalDivider(),
          Expanded(
            child: _QuickInfoItem(
              icon: Icons.calendar_today_outlined,
              label: 'Etapa',
              value: profile.stage,
            ),
          ),
          const _VerticalDivider(),
          Expanded(
            child: _QuickInfoItem(
              icon: Icons.schedule_outlined,
              label: 'Horario',
              value: profile.schedule,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickInfoItem extends StatelessWidget {
  const _QuickInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _ProfileColors.green, size: 20),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ProfileColors.navy,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ProfileColors.navy,
                fontSize: 9,
                height: 1.15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 44, color: _ProfileColors.line);
  }
}

class _ProfileAccessCard extends StatelessWidget {
  const _ProfileAccessCard({
    required this.onPersonalTap,
    required this.onAcademicTap,
    required this.onEmergencyTap,
    required this.onSecurityTap,
  });

  final VoidCallback onPersonalTap;
  final VoidCallback onAcademicTap;
  final VoidCallback onEmergencyTap;
  final VoidCallback onSecurityTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Accesos del perfil',
          style: TextStyle(
            color: _ProfileColors.navy,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        _ProfileAccessTile(
          icon: Icons.person_outline_rounded,
          title: 'Datos personales',
          subtitle: 'Documento, contacto y cierre de sesion',
          trailingIcon: Icons.edit_outlined,
          trailingTooltip: 'Editar datos personales',
          onTap: onPersonalTap,
        ),
        _ProfileAccessTile(
          icon: Icons.school_outlined,
          title: 'Academico',
          subtitle: 'Ficha, programa, etapa y horario',
          onTap: onAcademicTap,
        ),
        _ProfileAccessTile(
          icon: Icons.health_and_safety_outlined,
          title: 'Contacto de emergencia',
          subtitle: 'Persona de contacto principal',
          trailingIcon: Icons.edit_outlined,
          trailingTooltip: 'Editar contacto de emergencia',
          onTap: onEmergencyTap,
        ),
        _ProfileAccessTile(
          icon: Icons.lock_outline_rounded,
          title: 'Seguridad',
          subtitle: 'Clave y estado de la sesion',
          onTap: onSecurityTap,
        ),
      ],
    );
  }
}

class _ProfileAccessTile extends StatelessWidget {
  const _ProfileAccessTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingIcon = Icons.chevron_right_rounded,
    this.trailingTooltip,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData trailingIcon;
  final String? trailingTooltip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: _SurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _ProfileColors.green.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: _ProfileColors.green, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ProfileColors.navy,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ProfileColors.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: trailingTooltip ?? title,
                  onPressed: onTap,
                  constraints: const BoxConstraints.tightFor(
                    width: 40,
                    height: 40,
                  ),
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    trailingIcon,
                    color: _ProfileColors.muted,
                    size: 21,
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

class _PersonalInformationForm extends StatefulWidget {
  const _PersonalInformationForm({required this.profile, required this.onSave});

  final ApprenticeProfile profile;
  final Future<void> Function(ApprenticeProfile profile) onSave;

  @override
  State<_PersonalInformationForm> createState() =>
      _PersonalInformationFormState();
}

class _PersonalInformationFormState extends State<_PersonalInformationForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _documentTypeController;
  late final TextEditingController _documentNumberController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _firstNameController = TextEditingController(text: profile.firstName);
    _lastNameController = TextEditingController(text: profile.lastName);
    _documentTypeController = TextEditingController(text: profile.documentType);
    _documentNumberController = TextEditingController(
      text: profile.documentNumber,
    );
    _emailController = TextEditingController(text: profile.email);
    _phoneController = TextEditingController(text: profile.phone);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _documentTypeController.dispose();
    _documentNumberController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final updated = widget.profile.copyWith(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    try {
      await widget.onSave(updated);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });
      _showFormError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ProfileSheetScaffold(
      title: 'Datos personales',
      actionText: 'Guardar cambios',
      isSaving: _isSaving,
      onAction: _save,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _ProfileTextField(
              controller: _firstNameController,
              label: 'Nombres',
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            _ProfileTextField(
              controller: _lastNameController,
              label: 'Apellidos',
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            _ProfileTextField(
              controller: _documentTypeController,
              label: 'Tipo de documento',
              validator: _requiredValidator,
              readOnly: true,
            ),
            const SizedBox(height: 12),
            _ProfileTextField(
              controller: _documentNumberController,
              label: 'Numero de documento',
              validator: _requiredValidator,
              keyboardType: TextInputType.number,
              readOnly: true,
            ),
            const SizedBox(height: 12),
            _ProfileTextField(
              controller: _emailController,
              label: 'Correo',
              validator: _emailValidator,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            _ProfileTextField(
              controller: _phoneController,
              label: 'Telefono',
              validator: _requiredValidator,
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyContactForm extends StatefulWidget {
  const _EmergencyContactForm({required this.contact, required this.onSave});

  final EmergencyContact contact;
  final Future<void> Function(EmergencyContact contact) onSave;

  @override
  State<_EmergencyContactForm> createState() => _EmergencyContactFormState();
}

class _EmergencyContactFormState extends State<_EmergencyContactForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _relationshipController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final contact = widget.contact;
    _nameController = TextEditingController(text: contact.name);
    _relationshipController = TextEditingController(text: contact.relationship);
    _phoneController = TextEditingController(text: contact.phone);
    _emailController = TextEditingController(text: contact.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final updated = EmergencyContact(
      name: _nameController.text.trim(),
      relationship: _relationshipController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
    );

    try {
      await widget.onSave(updated);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });
      _showFormError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ProfileSheetScaffold(
      title: 'Contacto de emergencia',
      actionText: 'Guardar contacto',
      isSaving: _isSaving,
      onAction: _save,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _ProfileTextField(
              controller: _nameController,
              label: 'Nombre',
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            _ProfileTextField(
              controller: _relationshipController,
              label: 'Parentesco',
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            _ProfileTextField(
              controller: _phoneController,
              label: 'Telefono',
              validator: _requiredValidator,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _ProfileTextField(
              controller: _emailController,
              label: 'Correo',
              validator: _emailValidator,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordForm extends StatefulWidget {
  const _PasswordForm({required this.onSave});

  final Future<void> Function({
    required String currentPassword,
    required String newPassword,
  })
  onSave;

  @override
  State<_PasswordForm> createState() => _PasswordFormState();
}

class _PasswordFormState extends State<_PasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onSave(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });
      _showFormError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ProfileSheetScaffold(
      title: 'Cambiar clave',
      actionText: 'Guardar clave',
      isSaving: _isSaving,
      onAction: _save,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _ProfileTextField(
              controller: _currentPasswordController,
              label: 'Clave actual',
              obscureText: true,
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            _ProfileTextField(
              controller: _newPasswordController,
              label: 'Nueva clave',
              obscureText: true,
              validator: _passwordValidator,
            ),
            const SizedBox(height: 12),
            _ProfileTextField(
              controller: _confirmPasswordController,
              label: 'Confirmar clave',
              obscureText: true,
              validator: (value) {
                final error = _passwordValidator(value);
                if (error != null) {
                  return error;
                }
                if (value != _newPasswordController.text) {
                  return 'Las claves no coinciden';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            const _StatusNotice(
              icon: Icons.info_outline_rounded,
              text: 'Usa minimo 8 caracteres con letras y numeros.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlySheet extends StatelessWidget {
  const _ReadOnlySheet({
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
    return _ProfileSheetScaffold(
      title: title,
      actionText: actionText,
      onAction: onAction,
      child: Column(children: children),
    );
  }
}

class _ProfileSheetScaffold extends StatelessWidget {
  const _ProfileSheetScaffold({
    required this.title,
    required this.actionText,
    required this.child,
    required this.onAction,
    this.isSaving = false,
  });

  final String title;
  final String actionText;
  final Widget child;
  final VoidCallback onAction;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          0,
          22,
          MediaQuery.viewInsetsOf(context).bottom + 22,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.82,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _ProfileColors.navy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Flexible(child: SingleChildScrollView(child: child)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isSaving ? null : onAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: _ProfileColors.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _ProfileColors.line,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(actionText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        filled: readOnly,
        fillColor: readOnly ? _ProfileColors.background : null,
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

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ProfileColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.textMain.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.size,
    required this.initials,
    this.showPhoto = false,
  });

  final double size;
  final String initials;
  final bool showPhoto;

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
            color: _ProfileColors.green.withValues(alpha: 0.12),
            border: Border.all(color: _ProfileColors.greenLight, width: 2),
          ),
          alignment: Alignment.center,
          child: showPhoto
              ? ClipOval(
                  child: Image.asset(
                    'assets/images/aprendices_sena.png',
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Text(
                          initials,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: _ProfileColors.navy,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      );
                    },
                  ),
                )
              : Text(
                  initials,
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

class _StatusNotice extends StatelessWidget {
  const _StatusNotice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _ProfileColors.green.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: _ProfileColors.green, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _ProfileColors.navy,
                fontSize: 12,
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _ProfileColors.green.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        child: Text(
          label,
          style: const TextStyle(
            color: _ProfileColors.green,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _SheetInfoField extends StatelessWidget {
  const _SheetInfoField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _ProfileColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: _ProfileColors.navy,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: _ProfileColors.line),
        ],
      ),
    );
  }
}

class _ProfileLoading extends StatelessWidget {
  const _ProfileLoading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SkeletonBox(width: 180, height: 30),
        SizedBox(height: 10),
        _SkeletonBox(width: 320, height: 14),
        SizedBox(height: 20),
        _SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBox(width: 210, height: 18),
              SizedBox(height: 16),
              _SkeletonBox(width: double.infinity, height: 62),
              SizedBox(height: 10),
              _SkeletonBox(width: double.infinity, height: 62),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileStatePanel extends StatelessWidget {
  const _ProfileStatePanel({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _ProfileColors.green, size: 32),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: _ProfileColors.navy,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              color: _ProfileColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _ProfileColors.line,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

String? _requiredValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Campo requerido';
  }

  return null;
}

String? _emailValidator(String? value) {
  final requiredError = _requiredValidator(value);
  if (requiredError != null) {
    return requiredError;
  }

  if (!value!.contains('@')) {
    return 'Correo invalido';
  }

  return null;
}

String? _passwordValidator(String? value) {
  final requiredError = _requiredValidator(value);
  if (requiredError != null) {
    return requiredError;
  }

  if (value!.length < 8) {
    return 'Minimo 8 caracteres';
  }

  return null;
}

void _showFormError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(_cleanErrorMessage(error)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: _ProfileColors.danger,
    ),
  );
}

String _cleanErrorMessage(Object? error) {
  if (error == null) {
    return 'Revisa la conexion o intenta nuevamente.';
  }

  final rawMessage = error.toString();
  final message = rawMessage.startsWith('Exception: ')
      ? rawMessage.replaceFirst('Exception: ', '')
      : rawMessage;

  return message.trim().isEmpty
      ? 'Revisa la conexion o intenta nuevamente.'
      : message;
}

abstract final class _ProfileColors {
  static const background = AppColors.scaffoldBg;
  static const navy = AppColors.textMain;
  static const headerBlue = AppColors.primaryBlue;
  static const green = AppColors.accentGreen;
  static const greenLight = AppColors.bgSuccess;
  static const muted = AppColors.secondaryGrey;
  static const line = AppColors.borderGrey;
  static const danger = AppColors.alertCritical;
}
