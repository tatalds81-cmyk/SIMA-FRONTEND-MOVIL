import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:sima_movil_froned/features/home/dashboard_qr_flow.dart';
import 'package:sima_movil_froned/features/observatory/data/observations_repository.dart';
import 'package:sima_movil_froned/features/observatory/models/observation.dart';
import 'package:sima_movil_froned/services/auth_service.dart';
import 'package:sima_movil_froned/services/attendance_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.hasActiveSession,
    required this.hasVerifiedSession,
    this.onNavigateToAttendance,
    this.onNavigateToObservatory,
  });

  final bool hasActiveSession;
  final bool hasVerifiedSession;
  final Function(int)? onNavigateToAttendance;
  final Function(int)? onNavigateToObservatory;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const int _initialPage = 10000;

  late final PageController _controller;
  bool _scheduleCarouselInitialized = false;
  final ObservatoryRepository _observatoryRepository =
      const BackendObservatoryRepository();
  late Future<_DashboardData> _dashboardFuture;
  int _currentClass = 0;
  bool _activeSessionPromptShown = false;

  // ignore: unused_field
  final List<ClassItem> _classes = const [
    ClassItem(
      day: 'Lunes',
      status: 'Próxima',
      color: Color(0xFF052D4F),
      blocks: [
        ClassBlock(
          title: 'Implantación',
          time: '7:00 a. m. - 9:30 a. m.',
          place: 'Ambiente ADSO 1',
          instructor: 'Henry Bastidas',
        ),
        ClassBlock(
          title: 'Inglés',
          time: '10:00 a. m. - 12:30 p. m.',
          place: 'Ambiente ADSO 2',
          instructor: 'Natalia Henao',
        ),
      ],
    ),
    ClassItem(
      day: 'Martes',
      status: 'En curso',
      color: Color(0xFF052D4F),
      blocks: [
        ClassBlock(
          title: 'Base de datos',
          time: '8:00 a. m. - 10:00 a. m.',
          place: 'Ambiente TIC 3',
          instructor: 'Prof. Andrés Mejía',
        ),
        ClassBlock(
          title: 'Programación móvil',
          time: '10:30 a. m. - 12:00 p. m.',
          place: 'Laboratorio 2',
          instructor: 'Dra. Laura Salinas',
        ),
      ],
    ),
    ClassItem(
      day: 'Miércoles',
      status: 'Próxima',
      color: Color(0xFF052D4F),
      blocks: [
        ClassBlock(
          title: 'Programación móvil',
          time: '1:00 p. m. - 3:00 p. m.',
          place: 'Laboratorio 2',
          instructor: 'Dra. Laura Salinas',
        ),
        ClassBlock(
          title: 'Proyecto formativo',
          time: '3:30 p. m. - 5:00 p. m.',
          place: 'Ambiente ADSO 3',
          instructor: 'Ing. David Castro',
        ),
      ],
    ),
    ClassItem(
      day: 'Jueves',
      status: 'Próxima',
      color: Color(0xFF052D4F),
      blocks: [
        ClassBlock(
          title: 'Proyecto formativo',
          time: '7:00 a. m. - 9:00 a. m.',
          place: 'Ambiente 207',
          instructor: 'Ing. David Castro',
        ),
        ClassBlock(
          title: 'Pruebas de software',
          time: '9:30 a. m. - 11:00 a. m.',
          place: 'Laboratorio QA',
          instructor: 'Prof. Adriana Suárez',
        ),
      ],
    ),
    ClassItem(
      day: 'Viernes',
      status: 'En curso',
      color: Color(0xFF052D4F),
      blocks: [
        ClassBlock(
          title: 'Pruebas de software',
          time: '9:00 a. m. - 10:30 a. m.',
          place: 'Laboratorio QA',
          instructor: 'Prof. Adriana Suárez',
        ),
        ClassBlock(
          title: 'Desarrollo de Software',
          time: '11:00 a. m. - 12:00 p. m.',
          place: 'Aula 301 - Bloque B',
          instructor: 'Ing. Camila Rojas',
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      initialPage: _initialPage,
      viewportFraction: 0.92,
    );
    _dashboardFuture = _fetchDashboardData();
    _showActiveSessionPrompt();
  }

  Future<_DashboardData> _fetchDashboardData() async {
    final results = await Future.wait<dynamic>([
      AttendanceService.getDashboard(),
      _observatoryRepository.fetchObservations(const ObservatoryFilters()),
      _observatoryRepository.fetchAlerts(const ObservatoryFilters()),
    ]);

    final dashboard = results[0] as Map<String, dynamic>? ?? {};
    final observations = results[1] as ObservatoryObservationResponse;
    final alerts = results[2] as ObservatoryAlertResponse;

    return _DashboardData.fromBackend(
      dashboard: dashboard,
      observations: observations,
      alerts: alerts,
    );
  }

  void _reloadDashboard() {
    setState(() {
      _dashboardFuture = _fetchDashboardData();
    });
  }

  Future<void> _showActiveSessionPrompt() async {
    try {
      final data = await AttendanceService.getSessions();
      if (!mounted || _activeSessionPromptShown) {
        return;
      }

      final activeSession = data?['sesion_activa'] as Map<String, dynamic>?;
      if (activeSession == null) {
        return;
      }

      _activeSessionPromptShown = true;
      final ficha = data?['ficha'] as Map<String, dynamic>? ?? {};

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _showActiveSessionBottomSheet(activeSession, ficha);
      });
    } catch (_) {
      // The dashboard should still load normally if the active-session lookup fails.
    }
  }

  Future<void> _showActiveSessionFromButton() async {
    try {
      final data = await AttendanceService.getSessions();
      if (!mounted) {
        return;
      }

      final activeSession = data?['sesion_activa'] as Map<String, dynamic>?;
      if (activeSession == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay sesión activa en este momento'),
              backgroundColor: Color(0xFFF4A900),
            ),
          );
        }
        return;
      }

      final ficha = data?['ficha'] as Map<String, dynamic>? ?? {};

      if (mounted) {
        _showActiveSessionBottomSheet(activeSession, ficha);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar la sesión: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showActiveSessionBottomSheet(
    Map<String, dynamic> session,
    Map<String, dynamic> ficha,
  ) {
    final program = ficha['programa'] as Map<String, dynamic>? ?? {};
    final instructor = session['instructor'] as Map<String, dynamic>? ?? {};
    final leader = ficha['instructor_lider'] as Map<String, dynamic>? ?? {};
    final environment = session['ambiente'] as Map<String, dynamic>? ?? {};
    final competency = session['competencia'] as Map<String, dynamic>? ?? {};
    final block = session['bloque_jornada'] as Map<String, dynamic>? ?? {};

    final instructorName = _firstString([
      instructor['nombre_completo'],
      leader['registrado'] == true ? leader['nombre_completo'] : null,
      'Instructor por asignar',
    ]);
    final date = _formatDateLabel(_firstString([session['fecha_clase']]));
    final startTime = _formatTime(
      _firstString([session['hora_inicio'], block['hora_inicio']]),
    );
    final endTime = _formatTime(
      _firstString([session['hora_fin'], block['hora_fin']]),
    );
    final place = _formatPlace(environment);
    final group = _firstString([ficha['numero_ficha'], 'Grupo por asignar']);
    final programName = _firstString([
      program['nombre_programa'],
      program['sigla'],
      'Programa por asignar',
    ]);
    final programShortName = _programShortName(programName);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8DDE6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: 68,
                    height: 68,
                    decoration: const BoxDecoration(
                      color: Color(0xFF092444),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tienes una sesión activa',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF092444),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF092444),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        _ActiveSessionInfoRow(
                          icon: Icons.description_outlined,
                          label: 'Programa',
                          value: programShortName,
                        ),
                        _ActiveSessionInfoRow(
                          icon: Icons.adjust_rounded,
                          label: 'Competencia',
                          value: _firstString([
                            competency['nombre_competencia'],
                            'Clase programada',
                          ]),
                        ),
                        _ActiveSessionInfoRow(
                          icon: Icons.person_outline,
                          label: 'Instructor',
                          value: instructorName,
                        ),
                        _ActiveSessionInfoRow(
                          icon: Icons.groups_outlined,
                          label: 'Grupo',
                          value: '$programShortName - $group',
                        ),
                        _ActiveSessionInfoRow(
                          icon: Icons.science_outlined,
                          label: 'Ambiente',
                          value: place,
                          showDivider: false,
                        ),
                        const SizedBox(height: 14),
                        _ActiveSessionTimePanel(
                          startTime: startTime.isEmpty
                              ? 'Por definir'
                              : startTime,
                          endTime: endTime.isEmpty ? 'Por definir' : endTime,
                          date: date,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await startDashboardQrFlow(context);
                      },
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                      label: const Text('Escanear QR de la sesión'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF28B000),
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  // const SizedBox(height: 16), // Espacio removido junto con los botones
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        color: Color(0xFF8B97A8),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FB),
      body: SafeArea(
        child: FutureBuilder<_DashboardData>(
          future: _dashboardFuture,
          builder: (context, constraints) {
            final isLoading =
                constraints.connectionState == ConnectionState.waiting;
            final data = constraints.data ?? _DashboardData.empty();
            final errorMessage = constraints.hasError
                ? _cleanError(constraints.error)
                : null;
            final bodyContent = Column(
              children: [
                _HomeHeader(
                  notificationCount: 0,
                  hasActiveSession: widget.hasActiveSession,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (errorMessage != null) ...[
                          _DashboardErrorBanner(
                            message: errorMessage,
                            onRetry: _reloadDashboard,
                          ),
                          const SizedBox(height: 14),
                        ],
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F7EA),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.school_rounded,
                                  color: Color(0xFF39A900),
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Bienvenido Aprendiz',
                                      style: TextStyle(
                                        color: Color(0xFF092444),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Consulta tus próximas clases y mantente al día con tus asistencias.',
                                      style: TextStyle(
                                        color: Color(0xFF607086),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _DailyDonutSummary(
                          metrics: data.metrics,
                          isLoading: isLoading,
                        ),
                        const SizedBox(height: 18),
                        _QuickAccessSection(
                          onAttendanceTap: () {
                            _showActiveSessionFromButton();
                          },
                          onJustifyTap: () {
                            widget.onNavigateToAttendance?.call(0);
                          },
                          onObservationsTap: () {
                            widget.onNavigateToAttendance?.call(2);
                          },
                          onAlertsTap: () {
                            widget.onNavigateToObservatory?.call(0);
                          },
                        ),
                        const SizedBox(height: 18),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildScheduleCarousel(
                                  widget.hasActiveSession &&
                                          data.classes.isEmpty
                                      ? _classes
                                      : data.classes,
                                  isLoading: isLoading,
                                  emptyMessage: data.scheduleMessage,
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );

            return bodyContent;
          },
        ),
      ),
    );
  }

  static String _cleanError(Object? error) {
    final raw = error.toString();
    return raw.startsWith('Exception: ')
        ? raw.replaceFirst('Exception: ', '')
        : raw;
  }

  Widget _buildScheduleCarousel(
    List<ClassItem> classes, {
    required bool isLoading,
    String? emptyMessage,
  }) {
    if (isLoading) {
      return const _SchedulePlaceholder();
    }

    if (classes.isEmpty) {
      return _EmptyScheduleCard(
        message:
            emptyMessage ??
            'No hay horario disponible para la ficha seleccionada',
        helperText: 'Cuando tengas una sesión agendada, aparecerá aquí.',
      );
    }

    if (!_scheduleCarouselInitialized) {
      final initialIndex = _findInitialScheduleIndex(classes);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _scheduleCarouselInitialized) {
          return;
        }

        if (_controller.hasClients) {
          _controller.jumpToPage(_initialPage + initialIndex);
        }

        setState(() {
          _currentClass = initialIndex;
          _scheduleCarouselInitialized = true;
        });
      });
    }

    final activeIndex = _currentClass % classes.length;

    final screenHeight = MediaQuery.of(context).size.height;
    final carouselHeight = screenHeight < 720 ? 360.0 : 400.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TODO: Header de "Próxima clase" va para el próximo sprint.
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: carouselHeight,
          child: ScrollConfiguration(
            behavior: const _CarouselScrollBehavior(),
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (index) {
                setState(() {
                  _currentClass = index % classes.length;
                });
              },
              itemBuilder: (context, index) {
                final item = classes[index % classes.length];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _ClassCard(item: item),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(classes.length, (index) {
            final isActive = index == activeIndex;
            final dotColor = isActive
                ? classes[index].color
                : const Color(0xFFD4DCE7);

            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: isActive ? 22 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: dotColor,
                borderRadius: BorderRadius.circular(12),
              ),
            );
          }),
        ),
      ],
    );
  }
}

int _findInitialScheduleIndex(List<ClassItem> classes) {
  if (classes.isEmpty) {
    return 0;
  }

  final now = DateTime.now();
  final todayIndex = (now.weekday - 1).clamp(0, classes.length - 1);

  for (var index = todayIndex; index < classes.length; index++) {
    if (classes[index].status.toLowerCase() != 'cerrada') {
      return index;
    }
  }

  for (var index = 0; index < todayIndex; index++) {
    if (classes[index].status.toLowerCase() != 'cerrada') {
      return index;
    }
  }

  return todayIndex;
}

class _CarouselScrollBehavior extends MaterialScrollBehavior {
  const _CarouselScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };
}

class _ActiveSessionInfoRow extends StatelessWidget {
  const _ActiveSessionInfoRow({
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
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFFB8C6D8), size: 20),
              const SizedBox(width: 12),
              SizedBox(
                width: 74,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF9EADC1),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  value.isEmpty ? 'Sin información' : value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Container(height: 1, color: const Color(0xFF244361)),
      ],
    );
  }
}

class _ActiveSessionTimePanel extends StatelessWidget {
  const _ActiveSessionTimePanel({
    required this.startTime,
    required this.endTime,
    required this.date,
  });

  final String startTime;
  final String endTime;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF113A69),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (date.isNotEmpty) ...[
            Text(
              date,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFB8C6D8),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: _ActiveSessionTimeValue(
                  label: 'Hora inicio',
                  value: startTime,
                ),
              ),
              Container(height: 42, width: 1, color: const Color(0xFF446083)),
              Expanded(
                child: _ActiveSessionTimeValue(
                  label: 'Hora fin',
                  value: endTime,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActiveSessionTimeValue extends StatelessWidget {
  const _ActiveSessionTimeValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.schedule_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF2DCC35),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.notificationCount,
    required this.hasActiveSession,
  });

  final int notificationCount;
  final bool hasActiveSession;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
      decoration: const BoxDecoration(color: Color(0xFF052D4F)),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFE7F3E3),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Color(0xFF052D4F),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Hola, ${_getCurrentUserGreetingName()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: hasActiveSession
                        ? const Color(0xFF39A900)
                        : const Color(0xFF9AA8B8),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topRight,
            children: [
              Tooltip(
                message: 'Notificaciones',
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const _NotificationsPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.notifications_none_rounded),
                    color: Colors.white,
                    tooltip: 'Notificaciones',
                  ),
                ),
              ),
              if (notificationCount > 0)
                Positioned(
                  top: -5,
                  right: -5,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE74935),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      notificationCount > 9 ? '9+' : '$notificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationsPage extends StatelessWidget {
  const _NotificationsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FB),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: const BoxDecoration(
                color: Color(0xFF052D4F),
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE7EDF6)),
                ),
              ),
              child: Row(
                children: [
                  Tooltip(
                    message: 'Volver',
                    child: SizedBox(
                      width: 56,
                      height: 42,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF8FB4D3)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Icon(Icons.arrow_back_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Notificaciones',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(child: SizedBox.expand()),
          ],
        ),
      ),
    );
  }
}

class _ActiveDot extends StatefulWidget {
  const _ActiveDot({required this.isActive});

  final bool isActive;

  @override
  State<_ActiveDot> createState() => _ActiveDotState();
}

class _ActiveDotState extends State<_ActiveDot> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.isActive
        ? const Color(0xFF39A900)
        : const Color(0xFF9AA8B8);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isHovered = true),
        onTapUp: (_) => Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) setState(() => _isHovered = false);
        }),
        onTapCancel: () => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: _isHovered ? 16 : 12,
          height: _isHovered ? 16 : 12,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: _isHovered ? 3 : 2),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: dotColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _NoScheduledSessionCard extends StatelessWidget {
  const _NoScheduledSessionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7EDF6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Próxima sesión',
            style: TextStyle(
              color: Color(0xFF092444),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAF3FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.event_available_outlined,
                    color: Color(0xFF1976D2),
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'No tienes una sesión\nprogramada por ahora',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF092444),
                    fontSize: 13,
                    height: 1.16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Cuando tengas una sesión activa,\npodrás validar tu asistencia.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF607086),
                    fontSize: 10,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
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

class _DailyDonutSummary extends StatelessWidget {
  const _DailyDonutSummary({required this.metrics, required this.isLoading});

  final _DashboardMetrics metrics;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen del día',
          style: TextStyle(
            color: Color(0xFF092444),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Alertas, observaciones y asistencia de hoy',
          style: TextStyle(
            color: Color(0xFF607086),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DonutMetric(
                label: 'Alertas del día',
                value: isLoading ? '...' : '${metrics.alertsTotal}',
                percent: isLoading ? 0 : metrics.alertsPercent,
                color: const Color(0xFFE74935),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DonutMetric(
                label: 'Observaciones',
                value: isLoading ? '...' : '${metrics.observationsTotal}',
                percent: isLoading ? 0 : metrics.observationsPercent,
                color: const Color(0xFFF4A900),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DonutMetric(
                label: 'Asistencia',
                value: isLoading
                    ? '...'
                    : '${metrics.attendancePercent.round()}%',
                percent: isLoading ? 0 : metrics.attendancePercent / 100,
                color: const Color(0xFF39A900),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DonutMetric extends StatelessWidget {
  const _DonutMetric({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
  });

  final String label;
  final String value;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 144,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9EEF5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 62,
            height: 62,
            child: CustomPaint(
              painter: _DonutPainter(percent: percent, color: color),
              child: Center(
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF092444),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.percent, required this.color});

  final double percent;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 8.0;
    final radius = (size.width - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);

    final backgroundPaint = Paint()
      ..color = const Color(0xFFE9EEF5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final foregroundPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);
    final startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * percent.clamp(0, 1).toDouble();
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      foregroundPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.percent != percent || oldDelegate.color != color;
  }
}

class _DashboardErrorBanner extends StatelessWidget {
  const _DashboardErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD2CB)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFE74935), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF8F2E22),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _SchedulePlaceholder extends StatelessWidget {
  const _SchedulePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9EEF5)),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF39A900)),
      ),
    );
  }
}

class _EmptyScheduleCard extends StatelessWidget {
  const _EmptyScheduleCard({required this.message, this.helperText});

  final String message;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9EEF5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.event_busy_rounded,
            color: Color(0xFF607086),
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF607086),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (helperText != null) ...[
            const SizedBox(height: 6),
            Text(
              helperText!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF607086),
                fontSize: 11,
                height: 1.25,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickAccessSection extends StatelessWidget {
  const _QuickAccessSection({
    required this.onAttendanceTap,
    required this.onJustifyTap,
    required this.onObservationsTap,
    required this.onAlertsTap,
  });

  final VoidCallback onAttendanceTap;
  final VoidCallback onJustifyTap;
  final VoidCallback onObservationsTap;
  final VoidCallback onAlertsTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Accesos rápidos',
          style: TextStyle(
            color: Color(0xFF092444),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final spacing = 10.0;
            final cardWidth = (constraints.maxWidth - spacing) / 2;
            return Wrap(
              runSpacing: spacing,
              spacing: spacing,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _QuickAccessCard(
                    icon: Icons.assignment_turned_in_rounded,
                    label: 'Registrar asistencia',
                    color: const Color(0xFF062E4F),
                    onTap: onAttendanceTap,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _QuickAccessCard(
                    icon: Icons.calendar_today_rounded,
                    label: 'Mis asistencias',
                    color: const Color(0xFF062E4F),
                    onTap: onJustifyTap,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _QuickAccessCard(
                    icon: Icons.description_rounded,
                    label: 'Justificaciones',
                    color: const Color(0xFF062E4F),
                    onTap: onObservationsTap,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _QuickAccessCard(
                    icon: Icons.notifications_active_rounded,
                    label: 'Alertas y Observaciones',
                    color: const Color(0xFF062E4F),
                    onTap: onAlertsTap,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 102),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.item});

  final ClassItem item;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 380;
    final titleFontSize = isCompact ? 18.0 : 20.0;
    final blockTitleFontSize = isCompact ? 14.0 : 15.0;
    final cardPadding = isCompact ? 16.0 : 20.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9EEF5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.day.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF607086),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Jornada programada',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF092444),
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.status,
                  style: TextStyle(
                    color: item.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: List.generate(item.blocks.length, (index) {
              return Column(
                children: [
                  _ClassBlockTile(
                    block: item.blocks[index],
                    color: item.color,
                    titleFontSize: blockTitleFontSize,
                  ),
                  if (index < item.blocks.length - 1)
                    const SizedBox(height: 10),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ClassBlockTile extends StatelessWidget {
  const _ClassBlockTile({
    required this.block,
    required this.color,
    this.titleFontSize = 15,
  });

  final ClassBlock block;
  final Color color;
  final double titleFontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9EEF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 38,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      block.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF092444),
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _BlockInfoRow(
                      icon: Icons.schedule_outlined,
                      text: block.time,
                      color: color,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _BlockInfoRow(icon: Icons.place_outlined, text: block.place),
          const SizedBox(height: 6),
          _BlockInfoRow(icon: Icons.person_outline, text: block.instructor),
        ],
      ),
    );
  }
}

class _BlockInfoRow extends StatelessWidget {
  const _BlockInfoRow({
    required this.icon,
    required this.text,
    this.color = const Color(0xFF607086),
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF607086),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class ClassItem {
  const ClassItem({
    required this.day,
    required this.status,
    required this.color,
    required this.blocks,
  });

  final String day;
  final String status;
  final Color color;
  final List<ClassBlock> blocks;
}

class ClassBlock {
  const ClassBlock({
    required this.title,
    required this.time,
    required this.place,
    required this.instructor,
  });

  final String title;
  final String time;
  final String place;
  final String instructor;
}

String _getCurrentUserFullName() {
  final user = AuthService.currentUser ?? {};
  final fullName = _firstString([
    user['nombre_completo'],
    user['nombreCompleto'],
    user['full_name'],
    user['name'],
    user['nombre_usuario'],
    user['nombreUsuario'],
  ]);

  if (fullName.isNotEmpty) {
    return fullName;
  }

  final firstName = _firstString([
    user['primer_nombre'],
    user['primerNombre'],
    user['nombre1'],
    user['first_name'],
    user['firstName'],
    user['nombres'],
    user['nombre'],
    user['name'],
  ]);
  final lastName = _firstString([
    user['primer_apellido'],
    user['primerApellido'],
    user['apellido1'],
    user['last_name'],
    user['lastName'],
    user['apellidos'],
    user['apellido'],
    user['apellido_paterno'],
    user['apellido_materno'],
    user['apellidos'],
  ]);

  final combined = [
    firstName,
    lastName,
  ].where((part) => part.trim().isNotEmpty).join(' ');
  return combined.isEmpty ? 'Aprendiz' : combined;
}

String _getCurrentUserGreetingName() {
  final user = AuthService.currentUser ?? {};
  final firstName = _firstWord(
    _firstString([
      user['primer_nombre'],
      user['primerNombre'],
      user['nombre1'],
      user['first_name'],
      user['firstName'],
      user['nombres'],
      user['nombre'],
    ]),
  );
  final firstLastName = _firstWord(
    _firstString([
      user['primer_apellido'],
      user['primerApellido'],
      user['apellido1'],
      user['last_name'],
      user['lastName'],
      user['apellidos'],
      user['apellido'],
      user['apellido_paterno'],
      user['apellido_materno'],
    ]),
  );
  final shortName = [
    firstName,
    firstLastName,
  ].where((part) => part.isNotEmpty).join(' ');

  if (shortName.isNotEmpty) {
    return shortName;
  }

  final fullName = _getCurrentUserFullName();
  if (fullName.isEmpty || fullName.toLowerCase() == 'aprendiz') {
    return 'Aprendiz';
  }

  final parts = fullName
      .split(RegExp(r'\s+'))
      .where((part) => part.trim().isNotEmpty)
      .toList();
  if (parts.length >= 4) {
    return '${parts.first} ${parts[2]}';
  }
  if (parts.length >= 2) {
    return '${parts.first} ${parts[1]}';
  }
  return parts.isEmpty ? 'Aprendiz' : parts.first;
}

String _firstWord(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  return parts.isEmpty ? '' : parts.first;
}

String _getCurrentUserRole() {
  final user = AuthService.currentUser ?? {};
  return _firstString([user['rol'], user['role'], user['perfil'], 'Aprendiz']);
}

String _getCurrentUserProgram() {
  final user = AuthService.currentUser ?? {};
  return _firstString([
    user['program'],
    user['programa'],
    user['nombre_programa'],
    user['nombrePrograma'],
    'No disponible',
  ]);
}

String _getCurrentUserFicha() {
  final user = AuthService.currentUser ?? {};
  return _firstString([
    user['ficha'],
    user['numero_ficha'],
    user['numeroFicha'],
    user['codigo'],
    'No disponible',
  ]);
}

String _getCurrentUserTrimester() {
  final user = AuthService.currentUser ?? {};
  return _firstString([
    user['trimestre'],
    user['etapa'],
    user['stage'],
    'No disponible',
  ]);
}

class _DashboardData {
  const _DashboardData({
    required this.metrics,
    required this.classes,
    required this.unreadNotifications,
    this.scheduleMessage,
  });

  factory _DashboardData.empty() {
    return const _DashboardData(
      metrics: _DashboardMetrics.empty(),
      classes: [],
      unreadNotifications: 0,
    );
  }

  factory _DashboardData.fromBackend({
    required Map<String, dynamic> dashboard,
    required ObservatoryObservationResponse observations,
    required ObservatoryAlertResponse alerts,
  }) {
    final attendance = _firstMap([dashboard['asistencia_trimestre']]);
    final schedule = _firstMap([dashboard['horario_semanal']]);
    final news = _firstMap([dashboard['novedades']]);
    final notifications = _firstList([news['notificaciones']]);
    final sessions = _firstList([schedule['sesiones']]);
    final scheduleMessage = _firstString([schedule['mensaje']]);

    return _DashboardData(
      metrics: _DashboardMetrics(
        alertsTotal: alerts.metrics.total,
        observationsTotal: observations.metrics.total,
        attendancePercent: _attendancePercent(attendance),
      ),
      classes: _classItemsFromSessions(
        sessions.whereType<Map<String, dynamic>>().toList(),
      ),
      unreadNotifications: notifications
          .whereType<Map<String, dynamic>>()
          .where((item) => item['leida'] != true)
          .length,
      scheduleMessage: scheduleMessage.isEmpty ? null : scheduleMessage,
    );
  }

  final _DashboardMetrics metrics;
  final List<ClassItem> classes;
  final int unreadNotifications;
  final String? scheduleMessage;
}

class _DashboardMetrics {
  const _DashboardMetrics({
    required this.alertsTotal,
    required this.observationsTotal,
    required this.attendancePercent,
  });

  const _DashboardMetrics.empty()
    : alertsTotal = 0,
      observationsTotal = 0,
      attendancePercent = 0;

  final int alertsTotal;
  final int observationsTotal;
  final double attendancePercent;

  double get alertsPercent => (alertsTotal / 10).clamp(0, 1).toDouble();

  double get observationsPercent =>
      (observationsTotal / 10).clamp(0, 1).toDouble();
}

List<ClassItem> _classItemsFromSessions(List<Map<String, dynamic>> sessions) {
  final now = DateTime.now();
  final monday = now.subtract(Duration(days: now.weekday - 1));
  final weekDays = List.generate(
    5,
    (index) => DateTime(monday.year, monday.month, monday.day + index),
    growable: false,
  );

  final groupedByDate = <String, List<Map<String, dynamic>>>{};
  for (final session in sessions) {
    final fecha = _firstString([session['fecha_clase']]);
    final date = DateTime.tryParse(fecha);
    if (date == null) continue;

    final dateKey = _dateKey(DateTime(date.year, date.month, date.day));
    groupedByDate.putIfAbsent(dateKey, () => []).add(session);
  }

  return weekDays
      .map((date) {
        final dateKey = _dateKey(date);
        final sessionsForDay = groupedByDate[dateKey];

        if (sessionsForDay == null || sessionsForDay.isEmpty) {
          return ClassItem(
            day: _formatDay(date.toIso8601String()),
            status: 'Cerrada',
            color: const Color(0xFF607086),
            blocks: const [
              ClassBlock(
                title: 'No hay jornada programada',
                time: 'Horario por definir',
                place: 'Jornada cerrada',
                instructor: 'Sin instructor',
              ),
            ],
          );
        }

        final status = _firstString([
          sessionsForDay.first['estado'],
          'PROGRAMADA',
        ]);
        final color = _sessionColor(status);
        final blocks =
            sessionsForDay.map(_classBlockFromSession).toList(growable: false)
              ..sort(
                (a, b) => _parseTimeForSort(
                  a.time,
                ).compareTo(_parseTimeForSort(b.time)),
              );

        return ClassItem(
          day: _formatDay(date.toIso8601String()),
          status: _statusLabel(status),
          color: color,
          blocks: blocks,
        );
      })
      .toList(growable: false);
}

String _dateKey(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

ClassBlock _classBlockFromSession(Map<String, dynamic> session) {
  final competency = _firstMap([session['competencia']]);
  final instructor = _firstMap([session['instructor']]);
  final environment = _firstMap([session['ambiente']]);
  final block = _firstMap([session['bloque_jornada']]);

  return ClassBlock(
    title: _firstString([competency['nombre_competencia'], 'Clase programada']),
    time: _formatTimeRange(
      _firstString([session['hora_inicio'], block['hora_inicio']]),
      _firstString([session['hora_fin'], block['hora_fin']]),
    ),
    place: _formatPlace(environment),
    instructor: _firstString([
      instructor['nombre_completo'],
      'Instructor por asignar',
    ]),
  );
}

int _parseTimeForSort(String timeRange) {
  final parts = timeRange.split(' - ').first.split(' ');
  if (parts.isEmpty) return 0;
  final hm = parts.first.split(':');
  if (hm.length < 2) return 0;
  final hour = int.tryParse(hm[0]) ?? 0;
  final minute = int.tryParse(hm[1]) ?? 0;
  return hour * 100 + minute;
}

double _attendancePercent(Map<String, dynamic> attendance) {
  final total = _toInt(attendance['total']);
  final states = _firstList([attendance['estados']]);
  if (total <= 0 || states.isEmpty) return 0;

  var absencePercent = 0.0;
  var presentPercent = 0.0;
  for (final state in states.whereType<Map<String, dynamic>>()) {
    final name = _firstString([state['estado']]).toUpperCase();
    final percent = _toDouble(state['porcentaje']);
    if (name == 'INASISTENCIA') absencePercent = percent;
    if (name == 'PRESENTE') presentPercent = percent;
  }

  if (absencePercent > 0) {
    return (100 - absencePercent).clamp(0, 100).toDouble();
  }
  return presentPercent.clamp(0, 100).toDouble();
}

String _formatDay(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) return 'Programada';
  const days = [
    'Lunes',
    'Martes',
    'Miercoles',
    'Jueves',
    'Viernes',
    'Sabado',
    'Domingo',
  ];
  return days[date.weekday - 1];
}

String _formatDateLabel(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) return 'Fecha por definir';
  const months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _formatTimeRange(String start, String end) {
  final startText = _formatTime(start);
  final endText = _formatTime(end);
  if (startText.isEmpty && endText.isEmpty) return 'Horario por definir';
  if (endText.isEmpty) return startText;
  return '$startText - $endText';
}

String _formatTime(String value) {
  if (value.isEmpty) return '';
  final parts = value.split(':');
  final hour = int.tryParse(parts.first) ?? 0;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  final suffix = hour >= 12 ? 'p. m.' : 'a. m.';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  return '$displayHour:${minute.toString().padLeft(2, '0')} $suffix';
}

String _formatPlace(Map<String, dynamic> environment) {
  final name = _firstString([environment['nombre_ambiente']]);
  final location = _firstString([environment['ubicacion']]);
  if (name.isEmpty && location.isEmpty) return 'Ambiente por asignar';
  if (location.isEmpty) return name;
  if (name.isEmpty) return location;
  return '$name - $location';
}

String _programShortName(String value) {
  final text = value.trim();
  if (text.isEmpty) return 'Programa';

  final upperWords = RegExp(
    r'\b[A-Z]{2,}\b',
  ).allMatches(text).map((match) => match.group(0)!).toList(growable: false);
  if (upperWords.isNotEmpty) {
    return upperWords.first;
  }

  final initials = text
      .split(RegExp(r'\s+'))
      .where((word) => word.length > 2)
      .map((word) => word[0].toUpperCase())
      .take(5)
      .join();
  return initials.isEmpty ? text : initials;
}

String _statusLabel(String value) {
  switch (value.toUpperCase()) {
    case 'ABIERTA':
      return 'En curso';
    case 'FINALIZADA':
      return 'Finalizada';
    case 'CANCELADA':
      return 'Cancelada';
    default:
      return 'Proxima';
  }
}

Color _sessionColor(String value) {
  switch (value.toUpperCase()) {
    case 'ABIERTA':
      return const Color(0xFF39A900);
    case 'FINALIZADA':
      return const Color(0xFF607086);
    case 'CANCELADA':
      return const Color(0xFFE74935);
    default:
      return const Color(0xFF052D4F);
  }
}

Map<String, dynamic> _firstMap(List<dynamic> values) {
  for (final value in values) {
    if (value is Map<String, dynamic>) return value;
  }
  return {};
}

List<dynamic> _firstList(List<dynamic> values) {
  for (final value in values) {
    if (value is List) return value;
  }
  return const [];
}

String _firstString(List<dynamic> values) {
  for (final value in values) {
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return '';
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
