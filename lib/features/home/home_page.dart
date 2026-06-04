import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FB),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bodyContent = Column(
              children: [
                const _HomeHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 144),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _DailyDonutSummary(),
                                const SizedBox(height: 18),
                                _buildScheduleCarousel(),
                                const SizedBox(height: 14),
                                const _HistoryButton(),
                                const SizedBox(height: 14),
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
              ],
            );

            return bodyContent;
          },
        ),
      ),
    );
  }

  Widget _buildScheduleCarousel() {
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
          height: 320,
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

                return _ClassCard(item: item);
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_classes.length, (index) {
            final isActive = index == _currentClass;
            final dotColor = isActive
                ? _classes[index].color
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
          initialChildSize: 0.5,
          minChildSize: 0.4,
          maxChildSize: 0.8,
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
                            color: const Color(0xFFE6EAF3),
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
                                color: const Color(0xFFE7F3E3),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: Color(0xFF052D4F),
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
                                          Icons.edit,
                                          size: 18,
                                          color: Color(0xFF052D4F),
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
                                          Icons.photo_camera,
                                          size: 18,
                                          color: Color(0xFF052D4F),
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
                                          Icons.photo_size_select_large,
                                          size: 18,
                                          color: Color(0xFF052D4F),
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
                                          Icons.delete_outline,
                                          size: 18,
                                          color: Colors.red,
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
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: Color(0xFF052D4F),
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
                          color: Color(0xFF092444),
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
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
      decoration: const BoxDecoration(color: Color(0xFF052D4F)),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showPhotoOptions(context),
            child: Container(
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
                    fontWeight: FontWeight.w700,
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
              Tooltip(
                message: 'Notificaciones',
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_none_rounded),
                    color: Colors.white,
                    tooltip: 'Notificaciones',
                  ),
                ),
              ),
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
                  child: const Text(
                    '3',
                    style: TextStyle(
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
          width: _isHovered ? 16 : 12,
          height: _isHovered ? 16 : 12,
          decoration: BoxDecoration(
            color: const Color(0xFF39A900),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: _isHovered ? 3 : 2),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: const Color(0xFF39A900).withValues(alpha: 0.4),
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
            color: Color(0xFF607086),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE9EEF5)),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF092444),
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
          children: const [
            Expanded(
              child: _DonutMetric(
                label: 'Alertas del día',
                value: '3',
                percent: 0.7,
                color: Color(0xFFE74935),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _DonutMetric(
                label: 'Observaciones',
                value: '5',
                percent: 0.5,
                color: Color(0xFFF4A900),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _DonutMetric(
                label: 'Asistencia',
                value: '92%',
                percent: 0.92,
                color: Color(0xFF39A900),
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

class _QrScanButton extends StatelessWidget {
  const _QrScanButton();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: Color(0xFF39A900),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x29000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.qr_code_2, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Escanear QR',
          style: TextStyle(
            color: Color(0xFF39A900),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _HistoryButton extends StatelessWidget {
  const _HistoryButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {},
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE9EEF5)),
          ),
          child: const Row(
            children: [
              Icon(Icons.history_rounded, color: Color(0xFF092444), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ver historial de asistencias',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF092444),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Color(0xFF092444)),
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
      padding: const EdgeInsets.all(20),
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
                      style: const TextStyle(
                        color: Color(0xFF092444),
                        fontSize: 20,
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
          const SizedBox(height: 18),
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: item.blocks.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
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
                      style: const TextStyle(
                        color: Color(0xFF092444),
                        fontSize: 15,
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
