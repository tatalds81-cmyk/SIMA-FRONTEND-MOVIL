import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:sima_movil_froned/features/attendance/qr_attendance_flow.dart';
import 'package:sima_movil_froned/theme/app_colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const int _initialPage = 1000;

  final PageController _controller = PageController(initialPage: _initialPage);
  int _currentClass = 0;

  final List<ClassItem> _classes = const [
    ClassItem(
      day: 'Lunes',
      status: 'Próxima',
      color: AppColors.primaryBlue,
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
      color: AppColors.primaryBlue,
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
      color: AppColors.primaryBlue,
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
      color: AppColors.primaryBlue,
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
      color: AppColors.primaryBlue,
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                const _HomeHeader(),
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 15 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 144),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.borderGrey),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.textMain.withValues(alpha: 0.03),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.bgSuccess,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.school_rounded,
                                    color: AppColors.accentGreen,
                                    size: 26,
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
                                          color: AppColors.textMain,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Consulta tus próximas clases y mantente al día con tus asistencias.',
                                        style: TextStyle(
                                          color: AppColors.secondaryGrey,
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
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _DailyDonutSummary(),
                                  const SizedBox(height: 20),
                                  _buildScheduleCarousel(),
                                  const SizedBox(height: 16),
                                  const _HistoryButton(),
                                  const SizedBox(height: 16),
                                  const Align(
                                    alignment: Alignment.centerRight,
                                    child: _QrScanButton(),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildScheduleCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Horario de Clases',
          style: TextStyle(
            color: AppColors.textMain,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 310,
          child: ScrollConfiguration(
            behavior: const _CarouselScrollBehavior(),
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (index) {
                setState(() {
                  _currentClass = index % _classes.length;
                });
              },
              itemBuilder: (context, index) {
                final item = _classes[index % _classes.length];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: _ClassCard(item: item),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_classes.length, (index) {
            final isActive = index == _currentClass;
            final dotColor = isActive
                ? AppColors.accentGreen
                : AppColors.borderGrey;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? 20 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  void _showPhotoOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.borderGrey,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: AppColors.bgSuccess,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: AppColors.primaryBlue,
                                size: 48,
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: PopupMenuButton(
                                onSelected: (value) {},
                                itemBuilder: (BuildContext context) => [
                                  const PopupMenuItem(
                                    value: 1,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.edit_rounded,
                                          size: 18,
                                          color: AppColors.primaryBlue,
                                        ),
                                        SizedBox(width: 10),
                                        Text('Editar foto'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 2,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.photo_camera_rounded,
                                          size: 18,
                                          color: AppColors.primaryBlue,
                                        ),
                                        SizedBox(width: 10),
                                        Text('Cambiar foto'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 3,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.photo_size_select_large_rounded,
                                          size: 18,
                                          color: AppColors.primaryBlue,
                                        ),
                                        SizedBox(width: 10),
                                        Text('Ajustar foto'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 4,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete_outline_rounded,
                                          size: 18,
                                          color: AppColors.alertCritical,
                                        ),
                                        SizedBox(width: 10),
                                        Text('Eliminar foto'),
                                      ],
                                    ),
                                  ),
                                ],
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.edit_rounded,
                                    size: 16,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Información básica',
                        style: TextStyle(
                          color: AppColors.textMain,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _ReadOnlyFormField(
                        label: 'Nombres y apellidos',
                        value: 'Esteban Felipe Benavides Paz',
                      ),
                      const SizedBox(height: 12),
                      const _ReadOnlyFormField(label: 'Rol', value: 'Aprendiz'),
                      const SizedBox(height: 12),
                      const _ReadOnlyFormField(
                        label: 'Programa',
                        value: 'Análisis y desarrollo de software',
                      ),
                      const SizedBox(height: 12),
                      const _ReadOnlyFormField(
                        label: 'Ficha',
                        value: '3064975',
                      ),
                      const SizedBox(height: 12),
                      const _ReadOnlyFormField(label: 'Trimestre', value: '4'),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(color: AppColors.primaryBlue),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showPhotoOptions(context),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.bgSuccess,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.primaryBlue,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                Text(
                  'Hola Esteban',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(width: 8),
                _ActiveDot(),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topRight,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_rounded),
                color: Colors.white,
                tooltip: 'Notificaciones',
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: AppColors.alertCritical,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
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

class _ActiveDot extends StatefulWidget {
  const _ActiveDot();

  @override
  State<_ActiveDot> createState() => _ActiveDotState();
}

class _ActiveDotState extends State<_ActiveDot> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
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
          width: _isHovered ? 14 : 11,
          height: _isHovered ? 14 : 11,
          decoration: BoxDecoration(
            color: AppColors.accentGreen,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppColors.accentGreen.withValues(alpha: 0.4),
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

class _ReadOnlyFormField extends StatelessWidget {
  const _ReadOnlyFormField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.secondaryGrey,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.scaffoldBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textMain,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _DailyDonutSummary extends StatelessWidget {
  const _DailyDonutSummary();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen del día',
          style: TextStyle(
            color: AppColors.textMain,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Alertas, observaciones y asistencia de hoy',
          style: TextStyle(
            color: AppColors.secondaryGrey,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: const [
            Expanded(
              child: _DonutMetric(
                label: 'Alertas del día',
                value: '3',
                percent: 0.7,
                color: AppColors.alertCritical,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _DonutMetric(
                label: 'Observaciones',
                value: '5',
                percent: 0.5,
                color: AppColors.alertWarning,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _DonutMetric(
                label: 'Asistencia',
                value: '92%',
                percent: 0.92,
                color: AppColors.accentGreen,
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [
          BoxShadow(
            color: AppColors.textMain.withValues(alpha: 0.02),
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
              color: AppColors.textMain,
              fontSize: 11.5,
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
    final strokeWidth = 7.0;
    final radius = (size.width - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);

    final backgroundPaint = Paint()
      ..color = AppColors.borderGrey
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final foregroundPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);
    final startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * percent;
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

class _QrScanButton extends StatefulWidget {
  const _QrScanButton();

  @override
  State<_QrScanButton> createState() => _QrScanButtonState();
}

class _QrScanButtonState extends State<_QrScanButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: () => startQrAttendanceFlow(context),
          child: AnimatedScale(
            scale: _isPressed ? 0.94 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.accentGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentGreen.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 32),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Escanear QR',
          style: TextStyle(
            color: AppColors.accentGreen,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _HistoryButton extends StatefulWidget {
  const _HistoryButton();

  @override
  State<_HistoryButton> createState() => _HistoryButtonState();
}

class _HistoryButtonState extends State<_HistoryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {},
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderGrey),
            boxShadow: [
              BoxShadow(
                color: AppColors.textMain.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.history_rounded, color: AppColors.textMain, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ver historial de asistencias',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textMain,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textMain),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [
          BoxShadow(
            color: AppColors.textMain.withValues(alpha: 0.02),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
                        color: AppColors.secondaryGrey,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Jornada programada',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textMain,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  item.status,
                  style: TextStyle(
                    color: item.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: item.blocks.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final block = item.blocks[index];

                return _ClassBlockTile(block: block, color: item.color);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassBlockTile extends StatelessWidget {
  const _ClassBlockTile({required this.block, required this.color});

  final ClassBlock block;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 34,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      block.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMain,
                        fontSize: 14,
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
          const SizedBox(height: 6),
          _BlockInfoRow(icon: Icons.place_outlined, text: block.place),
          const SizedBox(height: 4),
          _BlockInfoRow(icon: Icons.person_outline_rounded, text: block.instructor),
        ],
      ),
    );
  }
}

class _BlockInfoRow extends StatelessWidget {
  const _BlockInfoRow({
    required this.icon,
    required this.text,
    this.color = AppColors.secondaryGrey,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.secondaryGrey,
              fontSize: 11.5,
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
