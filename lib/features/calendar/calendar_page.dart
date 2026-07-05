import 'package:flutter/material.dart';
import 'package:sima_movil_froned/features/attendance/attendance_page.dart';
import 'package:sima_movil_froned/services/attendance_service.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  int _selectedDay = DateTime.now().day;
  int _monthIndex  = DateTime.now().month - 1;
  int _year        = DateTime.now().year;

  // Estado completo por día
  Map<int, String>              _attendanceStatus = {};
  Map<int, Map<String, String>> _dayDetails       = {};
  // Campos extra del backend
  Map<int, String>  _competencia    = {};   // nombre_competencia
  Map<int, String>  _justEstado     = {};   // estado de la justificación si existe
  Map<int, String>  _observacion    = {};   // observacion de la asistencia

  bool    _loading = false;
  String? _error;

  static const List<String> _monthNames = [
    "Enero","Febrero","Marzo","Abril","Mayo","Junio",
    "Julio","Agosto","Septiembre","Octubre","Noviembre","Diciembre",
  ];

  @override
  void initState() {
    super.initState();
    _fetchCalendar();
  }

  // ── Helpers de calendario ─────────────────────────────────────────────────
  int get _firstWeekday =>
      DateTime(_year, _monthIndex + 1, 1).weekday - 1;

  int get _daysInMonth =>
      DateTime(_year, _monthIndex + 2, 0).day;

  void _prevMonth() {
    setState(() {
      _selectedDay = 1;
      _monthIndex == 0
          ? (_monthIndex = 11, _year--)
          : _monthIndex--;
    });
    _fetchCalendar();
  }

  void _nextMonth() {
    setState(() {
      _selectedDay = 1;
      _monthIndex == 11
          ? (_monthIndex = 0, _year++)
          : _monthIndex++;
    });
    _fetchCalendar();
  }

  String _dayName(int day) {
    const n = [
      "Lunes","Martes","Miércoles",
      "Jueves","Viernes","Sábado","Domingo",
    ];
    return n[DateTime(_year, _monthIndex + 1, day).weekday - 1];
  }

  // ── Llamada a la API ──────────────────────────────────────────────────────
  Future<void> _fetchCalendar() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });

    try {
      final String fechaRef =
          '$_year-${(_monthIndex + 1).toString().padLeft(2, '0')}-01';

      final data = await AttendanceService.getMyCalendar(
        periodo: 'mes',
        fechaReferencia: fechaRef,
      );

      if (!mounted) return;

      final List<dynamic> registros =
          (data?['registros'] as List<dynamic>?) ?? [];

      final Map<int, String>              statusMap     = {};
      final Map<int, Map<String, String>> detailMap     = {};
      final Map<int, String>              competMap     = {};
      final Map<int, String>              justMap       = {};
      final Map<int, String>              obsMap        = {};

      for (final reg in registros) {
        final String? fechaClase = reg['sesion']?['fecha_clase'];
        if (fechaClase == null) continue;

        final DateTime fecha = DateTime.parse(fechaClase);
        if (fecha.month != _monthIndex + 1 || fecha.year != _year) continue;

        final int    day  = fecha.day;
        final String ep05 =
            (reg['estado_ep05'] ?? '').toString().toUpperCase();

        // ── Estado de asistencia ──────────────────────────────────────────
        switch (ep05) {
          case 'PRESENTE':
          case 'TARDE':
            statusMap[day] = 'presente';
            break;
          case 'INASISTENCIA':
            statusMap[day] = 'ausente';
            break;
          case 'JUSTIFICADO':
            statusMap[day] = 'justificada';
            break;
        }

        // ── Horas ─────────────────────────────────────────────────────────
        final String? hi = reg['sesion']?['hora_inicio_programada'];
        final String? hf = reg['sesion']?['hora_fin_programada'];
        if (hi != null && hf != null) {
          detailMap[day] = {
            'entrada': hi.length >= 5 ? hi.substring(0, 5) : hi,
            'salida':  hf.length >= 5 ? hf.substring(0, 5) : hf,
          };
        }

        // ── Competencia ───────────────────────────────────────────────────
        final String? nombreComp =
            reg['sesion']?['competencia']?['nombre_competencia'];
        if (nombreComp != null && nombreComp.isNotEmpty) {
          competMap[day] = nombreComp;
        }

        // ── Observación de la asistencia ──────────────────────────────────
        final String? obs = reg['observacion'];
        if (obs != null && obs.isNotEmpty) {
          obsMap[day] = obs;
        }

        // ── Justificaciones — toma la más reciente ─────────────────────── 
        final List<dynamic> justs =
            (reg['justificaciones'] as List<dynamic>?) ?? [];
        if (justs.isNotEmpty) {
          // Ordena por fecha_envio descendente y toma el estado del primero
          justs.sort((a, b) {
            final da = DateTime.tryParse(a['fecha_envio'] ?? '') ??
                DateTime(2000);
            final db = DateTime.tryParse(b['fecha_envio'] ?? '') ??
                DateTime(2000);
            return db.compareTo(da);
          });
          final String justEstado =
              (justs.first['estado'] ?? '').toString().toUpperCase();
          justMap[day] = justEstado; // 'PENDIENTE' | 'APROBADA' | 'RECHAZADA'
        }
      }

      setState(() {
        _attendanceStatus = statusMap;
        _dayDetails       = detailMap;
        _competencia      = competMap;
        _justEstado       = justMap;
        _observacion      = obsMap;
        _loading          = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error   = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  // ── Helpers de color/texto ────────────────────────────────────────────────
  Color _statusColor(String? s) {
    switch (s) {
      case 'presente':    return const Color(0xFF44C21E);
      case 'ausente':     return const Color(0xFFE53935);
      case 'justificada': return const Color(0xFFF6A900);
      default:            return const Color(0xFFBDBDBD);
    }
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'presente':    return 'Presente';
      case 'ausente':     return 'Ausente';
      case 'justificada': return 'Justificada';
      default:            return 'Sin clase';
    }
  }

  // Color e ícono del estado de la justificación
  Color _justColor(String estado) {
    switch (estado) {
      case 'APROBADA':   return const Color(0xFF44C21E);
      case 'RECHAZADA':  return const Color(0xFFE53935);
      case 'PENDIENTE':  return const Color(0xFFF6A900);
      default:           return Colors.grey;
    }
  }

  String _justLabel(String estado) {
    switch (estado) {
      case 'APROBADA':  return 'Justificación aprobada';
      case 'RECHAZADA': return 'Justificación rechazada';
      case 'PENDIENTE': return 'Justificación pendiente de revisión';
      default:          return '';
    }
  }

  IconData _justIcon(String estado) {
    switch (estado) {
      case 'APROBADA':  return Icons.check_circle_outline;
      case 'RECHAZADA': return Icons.cancel_outlined;
      case 'PENDIENTE': return Icons.hourglass_empty_rounded;
      default:          return Icons.info_outline;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calendario',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Historial de asistencia mensual',
                    style: TextStyle(fontSize: 14, color: Color(0xFF607086)),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF44C21E)),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 52, color: Color(0xFF607086)),
              const SizedBox(height: 14),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF607086), fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchCalendar,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Reintentar',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF44C21E),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final int firstWeekday = _firstWeekday;
    final int daysInMonth  = _daysInMonth;
    final int gridCells =
        (((firstWeekday + daysInMonth) / 7).ceil()) * 7;

    final String?              selStatus = _attendanceStatus[_selectedDay];
    final Map<String, String>? selDetail = _dayDetails[_selectedDay];
    final String?              selComp   = _competencia[_selectedDay];
    final String?              selJust   = _justEstado[_selectedDay];
    final String?              selObs    = _observacion[_selectedDay];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          // ── Card calendario ──────────────────────────────────────────────
          _card(
            child: Column(
              children: [
                // Navegación mes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _navBtn(Icons.chevron_left, _prevMonth),
                    Text(
                      "${_monthNames[_monthIndex]} $_year",
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    _navBtn(Icons.chevron_right, _nextMonth),
                  ],
                ),
                const SizedBox(height: 16),

                // Cabecera L M M J V S D
                Row(
                  children: ["L","M","M","J","V","S","D"]
                      .map((d) => Expanded(
                            child: Center(
                              child: Text(
                                d,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 10),

                // Grid de días
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: gridCells,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 0,
                    childAspectRatio: 0.82,
                  ),
                  itemBuilder: (context, index) {
                    if (index < firstWeekday ||
                        index >= firstWeekday + daysInMonth) {
                      return const SizedBox.shrink();
                    }

                    final int     day        = index - firstWeekday + 1;
                    final bool    isSelected = _selectedDay == day;
                    final String? status     = _attendanceStatus[day];
                    // Punto extra para justificación pendiente
                    final String? justDay    = _justEstado[day];

                    return GestureDetector(
                      onTap: () => setState(() => _selectedDay = day),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 34, height: 34,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF44C21E)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$day',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF334155),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          // Si tiene justificación pendiente muestra doble punto
                          if (justDay == 'PENDIENTE')
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _dot6(status != null
                                    ? _statusColor(status)
                                    : Colors.transparent),
                                const SizedBox(width: 2),
                                _dot6(const Color(0xFFF6A900)),
                              ],
                            )
                          else
                            _dot6(status != null
                                ? _statusColor(status)
                                : Colors.transparent),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Card detalle del día ─────────────────────────────────────────
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila principal: fecha + badge estado
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${_dayName(_selectedDay)}, $_selectedDay de "
                            "${_monthNames[_monthIndex].toLowerCase()}",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Horas
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded,
                                  size: 14, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 4),
                              Text(
                                selDetail != null
                                    ? "${selDetail['entrada']} - ${selDetail['salida']}"
                                    : "Sin registro de horario",
                                style: const TextStyle(
                                    fontSize: 13, color: Color(0xFF607086)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Badge estado
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _statusColor(selStatus).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabel(selStatus),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _statusColor(selStatus),
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Competencia ──────────────────────────────────────────
                if (selComp != null) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFEEF0F3)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.book_outlined,
                          size: 16, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 8),
                      Text(
                        'Competencia: ',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          selComp,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1E293B),
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                // ── Justificación ─────────────────────────────────────────
                if (selJust != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: _justColor(selJust).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _justColor(selJust).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(_justIcon(selJust),
                            size: 16, color: _justColor(selJust)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _justLabel(selJust),
                            style: TextStyle(
                              fontSize: 13,
                              color: _justColor(selJust),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Observación ───────────────────────────────────────────
                if (selObs != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline,
                            size: 16, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selObs,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF607086),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (selStatus == 'ausente') ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AttendancePage(
                              initialTabIndex: 2,
                              initialSelectedJustificationDate: DateTime(
                                _year,
                                _monthIndex + 1,
                                _selectedDay,
                              ),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF39A900),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 16,
                        ),
                      ),
                      child: const Text(
                        'Justificar asistencia',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],

                // ── Si el día no tiene ningún registro ───────────────────
                if (selStatus == null) ...[
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      'Sin sesión registrada este día',
                      style: TextStyle(
                          fontSize: 13, color: Color(0xFFBDBDBD)),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Leyenda ──────────────────────────────────────────────────────
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Referencias',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _legendDot(const Color(0xFF44C21E), "Presente"),
                    _legendDot(const Color(0xFFE53935), "Ausente"),
                    _legendDot(const Color(0xFFF6A900), "Justificada"),
                    _legendDot(const Color(0xFFBDBDBD), "Sin clase"),
                  ],
                ),
                const SizedBox(height: 10),
                // Explicación del doble punto
                Row(
                  children: [
                    _dot6(const Color(0xFFE53935)),
                    const SizedBox(width: 2),
                    _dot6(const Color(0xFFF6A900)),
                    const SizedBox(width: 8),
                    const Text(
                      'Ausente con justificación pendiente',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF607086)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Widgets auxiliares ────────────────────────────────────────────────────
  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      );

  Widget _navBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF6E7B8D)),
        ),
      );

  Widget _dot6(Color color) => Container(
        width: 6, height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  Widget _legendDot(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dot6(color),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF607086),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
}
