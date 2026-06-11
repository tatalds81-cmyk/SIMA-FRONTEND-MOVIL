import 'package:flutter/material.dart';
import 'package:sima_movil_froned/services/attendance_service.dart';
 
// ─────────────────────────────────────────────────────────────────────────────
// CalendarPage — vista de calendario de asistencia
// Consume: GET /api/attendances/my-calendar
// Se integra como ítem independiente en la barra de navegación
// ─────────────────────────────────────────────────────────────────────────────
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});
 
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}
 
class _CalendarPageState extends State<CalendarPage> {
  // ── Estado ──────────────────────────────────────────────────────────────────
  bool _isLoading = true;
  String? _error;
  List<dynamic> _registros = [];
 
  // Mes y año actualmente visible
  late DateTime _focusedMonth;
 
  // Día seleccionado (para mostrar detalle abajo)
  DateTime? _selectedDay;
 
  // ── Constantes de color ──────────────────────────────────────────────────────
  static const _colorPresente    = Color(0xFF39A900);
  static const _colorAusente     = Color(0xFFE53935);
  static const _colorJustificada = Color(0xFFF6A900);
  static const _colorSinClase    = Color(0xFFB0BEC5);
 
  // ── Nombres de mes ───────────────────────────────────────────────────────────
  static const _meses = [
    '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];
 
  static const _diasSemana = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
 
  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _fetchCalendar();
  }
 
  // ── Carga de datos ───────────────────────────────────────────────────────────
  Future<void> _fetchCalendar() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Pide el mes completo actual usando el parámetro periodo=mes
      final data = await AttendanceService.getMyCalendar(
        queryParams: {
          'periodo': 'mes',
          'fecha_referencia': _focusedMonth.toIso8601String().substring(0, 10),
        },
      );
      if (mounted) {
        setState(() {
          _registros = data?['registros'] as List<dynamic>? ?? [];
          _isLoading = false;
          // Selecciona hoy si está en el mes enfocado
          final hoy = DateTime.now();
          if (hoy.year == _focusedMonth.year && hoy.month == _focusedMonth.month) {
            _selectedDay = DateTime(hoy.year, hoy.month, hoy.day);
          } else {
            _selectedDay = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }
 
  // ── Helpers de datos ─────────────────────────────────────────────────────────
 
  /// Devuelve el registro de asistencia para una fecha dada (yyyy-MM-dd)
  Map<String, dynamic>? _registroParaDia(DateTime day) {
    final fechaStr =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    for (final r in _registros) {
      final sesion = r['sesion'] as Map<String, dynamic>?;
      final fecha = sesion?['fecha_clase'] as String? ?? '';
      if (fecha.startsWith(fechaStr)) return r as Map<String, dynamic>;
    }
    return null;
  }
 
  /// Color del dot según estado_ep05 del backend
  Color? _colorParaEstado(String? estado) {
    switch (estado?.toUpperCase()) {
      case 'PRESENTE':
        return _colorPresente;
      case 'INASISTENCIA':
        return _colorAusente;
      case 'JUSTIFICADO':
        return _colorJustificada;
      case 'TARDE':
        return _colorJustificada;
      default:
        return null;
    }
  }
 
  /// Etiqueta legible para el estado
  String _etiquetaEstado(String? estado) {
    switch (estado?.toUpperCase()) {
      case 'PRESENTE':   return 'Presente';
      case 'INASISTENCIA': return 'Ausente';
      case 'JUSTIFICADO': return 'Justificada';
      case 'TARDE':       return 'Tardanza';
      default:            return 'Sin clase';
    }
  }
 
  /// Registros del día seleccionado
  List<Map<String, dynamic>> get _registrosDelDiaSeleccionado {
    if (_selectedDay == null) return [];
    final fechaStr =
        '${_selectedDay!.year}-${_selectedDay!.month.toString().padLeft(2, '0')}-${_selectedDay!.day.toString().padLeft(2, '0')}';
    return _registros
        .where((r) {
          final sesion = r['sesion'] as Map<String, dynamic>?;
          final fecha = sesion?['fecha_clase'] as String? ?? '';
          return fecha.startsWith(fechaStr);
        })
        .map((r) => r as Map<String, dynamic>)
        .toList();
  }
 
  // ── Cambio de mes ────────────────────────────────────────────────────────────
  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
      _selectedDay = null;
    });
    _fetchCalendar();
  }
 
  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
      _selectedDay = null;
    });
    _fetchCalendar();
  }
 
  // ── Formato de hora ──────────────────────────────────────────────────────────
  String _formatHora(String? hora) {
    if (hora == null || hora.length < 5) return '';
    final parts = hora.substring(0, 5).split(':');
    if (parts.length < 2) return hora;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts[1];
    final periodo = h >= 12 ? 'p.m.' : 'a.m.';
    final h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$h12:$m $periodo';
  }
 
  /// Nombre del día de la semana en español
  String _nombreDiaSemana(DateTime d) {
    const nombres = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return nombres[d.weekday - 1];
  }
 
  // ── Build principal ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF39A900)),
                    )
                  : _error != null
                      ? _buildError()
                      : _buildBody(),
            ),
          ],
        ),
      ),
    );
  }
 
  // ── Header ───────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Asistencia',
            style: TextStyle(
              color: Color(0xFF092444),
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Registro y consulta de asistencia',
            style: TextStyle(color: Color(0xFF607086), fontSize: 14),
          ),
        ],
      ),
    );
  }
 
  // ── Error ────────────────────────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Color(0xFFE53935), size: 48),
            const SizedBox(height: 16),
            const Text(
              'No se pudo cargar el calendario',
              style: TextStyle(
                color: Color(0xFF092444),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF607086), fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchCalendar,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39A900),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
 
  // ── Cuerpo principal ─────────────────────────────────────────────────────────
  Widget _buildBody() {
    return RefreshIndicator(
      color: const Color(0xFF39A900),
      onRefresh: _fetchCalendar,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(
          children: [
            _buildCalendarCard(),
            const SizedBox(height: 16),
            _buildDayDetail(),
            const SizedBox(height: 16),
            _buildLegend(),
          ],
        ),
      ),
    );
  }
 
  // ── Tarjeta del calendario ───────────────────────────────────────────────────
  Widget _buildCalendarCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMonthNav(),
          const SizedBox(height: 12),
          _buildDayHeaders(),
          const SizedBox(height: 8),
          _buildDayGrid(),
        ],
      ),
    );
  }
 
  // ── Navegación de mes ────────────────────────────────────────────────────────
  Widget _buildMonthNav() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: _prevMonth,
          icon: const Icon(Icons.chevron_left_rounded),
          color: const Color(0xFF092444),
          iconSize: 24,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        Text(
          '${_meses[_focusedMonth.month]} ${_focusedMonth.year}',
          style: const TextStyle(
            color: Color(0xFF092444),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        IconButton(
          onPressed: _nextMonth,
          icon: const Icon(Icons.chevron_right_rounded),
          color: const Color(0xFF092444),
          iconSize: 24,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ],
    );
  }
 
  // ── Cabecera días de semana ──────────────────────────────────────────────────
  Widget _buildDayHeaders() {
    return Row(
      children: _diasSemana
          .map(
            (d) => Expanded(
              child: Center(
                child: Text(
                  d,
                  style: const TextStyle(
                    color: Color(0xFF607086),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
 
  // ── Grid de días ─────────────────────────────────────────────────────────────
  Widget _buildDayGrid() {
    // Primer día del mes (weekday: 1=Lun … 7=Dom)
    final primerDia = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final offsetInicio = primerDia.weekday - 1; // cuántas celdas vacías al inicio
 
    final diasEnMes = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    final totalCeldas = offsetInicio + diasEnMes;
    final filas = (totalCeldas / 7).ceil();
 
    final hoy = DateTime.now();
 
    return Column(
      children: List.generate(filas, (fila) {
        return Row(
          children: List.generate(7, (col) {
            final celda = fila * 7 + col;
            final diaNum = celda - offsetInicio + 1;
 
            if (diaNum < 1 || diaNum > diasEnMes) {
              return const Expanded(child: SizedBox(height: 44));
            }
 
            final fecha = DateTime(_focusedMonth.year, _focusedMonth.month, diaNum);
            final registro = _registroParaDia(fecha);
            final estado = registro?['estado_ep05'] as String?;
            final dotColor = _colorParaEstado(estado);
 
            final esHoy = fecha.year == hoy.year &&
                fecha.month == hoy.month &&
                fecha.day == hoy.day;
 
            final esSeleccionado = _selectedDay != null &&
                fecha.year == _selectedDay!.year &&
                fecha.month == _selectedDay!.month &&
                fecha.day == _selectedDay!.day;
 
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedDay = fecha),
                child: Container(
                  height: 44,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: esSeleccionado
                        ? const Color(0xFF39A900)
                        : esHoy
                            ? const Color(0xFF39A900).withOpacity(0.1)
                            : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$diaNum',
                        style: TextStyle(
                          color: esSeleccionado
                              ? Colors.white
                              : esHoy
                                  ? const Color(0xFF39A900)
                                  : const Color(0xFF092444),
                          fontSize: 14,
                          fontWeight: esHoy || esSeleccionado
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                      // Dot de estado
                      if (dotColor != null)
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: esSeleccionado
                                ? Colors.white.withOpacity(0.9)
                                : dotColor,
                            shape: BoxShape.circle,
                          ),
                        )
                      else
                        const SizedBox(height: 5),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }
 
  // ── Detalle del día seleccionado ─────────────────────────────────────────────
  Widget _buildDayDetail() {
    if (_selectedDay == null) return const SizedBox.shrink();
 
    final registros = _registrosDelDiaSeleccionado;
    final diaNombre = _nombreDiaSemana(_selectedDay!);
    final diaStr =
        '$diaNombre, ${_selectedDay!.day} de ${_meses[_selectedDay!.month]}';
 
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                diaStr,
                style: const TextStyle(
                  color: Color(0xFF092444),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (registros.isNotEmpty)
                _estadoChip(registros.first['estado_ep05'] as String?),
            ],
          ),
          if (registros.isEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Sin clase registrada',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ] else
            ...registros.map((r) => _buildRegistroItem(r)).toList(),
        ],
      ),
    );
  }
 
  Widget _buildRegistroItem(Map<String, dynamic> registro) {
    final sesion = registro['sesion'] as Map<String, dynamic>? ?? {};
    final bloque = sesion['bloque_jornada'] as Map<String, dynamic>?;
    final competencia = sesion['competencia'] as Map<String, dynamic>?;
 
    final horaInicio = _formatHora(
      bloque?['hora_inicio'] as String? ?? sesion['hora_inicio_programada'] as String?,
    );
    final horaFin = _formatHora(
      bloque?['hora_fin'] as String? ?? sesion['hora_fin_programada'] as String?,
    );
    final nombreCompetencia =
        competencia?['nombre_competencia'] as String? ?? 'Sin asignar';
    final estado = registro['estado_ep05'] as String?;
    final color = _colorParaEstado(estado) ?? _colorSinClase;
 
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          // Barra de color
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombreCompetencia,
                  style: const TextStyle(
                    color: Color(0xFF092444),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  horaInicio.isNotEmpty && horaFin.isNotEmpty
                      ? '$horaInicio - $horaFin'
                      : 'Hora no disponible',
                  style: const TextStyle(
                    color: Color(0xFF607086),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _estadoChip(String? estado) {
    final color = _colorParaEstado(estado) ?? _colorSinClase;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _etiquetaEstado(estado),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
 
  // ── Leyenda ──────────────────────────────────────────────────────────────────
  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _legendItem(_colorPresente, 'Presente'),
          _legendItem(_colorAusente, 'Ausente'),
          _legendItem(_colorJustificada, 'Justificada'),
          _legendItem(_colorSinClase, 'Sin clase'),
        ],
      ),
    );
  }
 
  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF607086), fontSize: 11),
        ),
      ],
    );
  }
}