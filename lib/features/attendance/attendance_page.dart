import 'package:flutter/material.dart';
import 'package:sima_movil_froned/services/attendance_service.dart';
import 'dart:math' as math;

class AttendancePage extends StatefulWidget {
  const AttendancePage({
    super.key,
    this.initialTabIndex = 0,
  });

  final int initialTabIndex;

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedMonth = 'Mayo 2024';
  String _selectedFilter = 'Todos';
  Map<String, dynamic>? _hoveredSegmentData;
  Offset? _hoverPosition;

  bool _isLoadingDashboard = true;
  Map<String, dynamic>? _dashboardData;
  String? _dashboardError;

  bool _isLoadingCalendar = true;
  List<dynamic>? _calendarData;
  String? _calendarError;

  bool _isLoadingSessions = true;
  Map<String, dynamic>? _sessionsData;
  String? _sessionsError;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.initialTabIndex.clamp(0, 2);
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: initialIndex,
    );
    _fetchDashboard();
    _fetchCalendar();
    _fetchSessions();
  }

  Future<void> _fetchDashboard() async {
    setState(() {
      _isLoadingDashboard = true;
      _dashboardError = null;
    });

    try {
      final data = await AttendanceService.getDashboard();
      if (mounted) {
        setState(() {
          _dashboardData = data;
          _isLoadingDashboard = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dashboardError = e.toString();
          _isLoadingDashboard = false;
        });
      }
    }
  }

  Future<void> _fetchCalendar() async {
    setState(() {
      _isLoadingCalendar = true;
      _calendarError = null;
    });

    try {
      final data = await AttendanceService.getMyCalendar();
      if (mounted) {
        setState(() {
          _calendarData = data?['registros'] as List<dynamic>? ?? [];
          _isLoadingCalendar = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _calendarError = e.toString();
          _isLoadingCalendar = false;
        });
      }
    }
  }

  Future<void> _fetchSessions() async {
    setState(() {
      _isLoadingSessions = true;
      _sessionsError = null;
    });

    try {
      final data = await AttendanceService.getSessions();
      if (mounted) {
        setState(() {
          _sessionsData = data;
          _isLoadingSessions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sessionsError = e.toString();
          _isLoadingSessions = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showMonthPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Seleccionar Mes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ListTile(
                title: const Text('Mayo 2024'),
                onTap: () {
                  setState(() => _selectedMonth = 'Mayo 2024');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Abril 2024'),
                onTap: () {
                  setState(() => _selectedMonth = 'Abril 2024');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Marzo 2024'),
                onTap: () {
                  setState(() => _selectedMonth = 'Marzo 2024');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFilterPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Filtrar por Estado',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ListTile(
                title: const Text('Todos'),
                onTap: () {
                  setState(() => _selectedFilter = 'Todos');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('PENDIENTE'),
                onTap: () {
                  setState(() => _selectedFilter = 'PENDIENTE');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('PRESENTE'),
                onTap: () {
                  setState(() => _selectedFilter = 'PRESENTE');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('INASISTENTE'),
                onTap: () {
                  setState(() => _selectedFilter = 'INASISTENTE');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('TARDE'),
                onTap: () {
                  setState(() => _selectedFilter = 'TARDE');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('JUSTIFICADA'),
                onTap: () {
                  setState(() => _selectedFilter = 'JUSTIFICADA');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDIENTE':
        return Colors.grey.shade500;
      case 'PRESENTE':
        return const Color(0xFF39A900);
      case 'INASISTENTE':
        return const Color(0xFFE53935);
      case 'TARDE':
      case 'JUSTIFICADA':
        return const Color(0xFFF6A900);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // â”€â”€ Header Principal â”€â”€
            const Padding(
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
                  SizedBox(height: 6),
                  Text(
                    'Registro y consulta de asistencia',
                    style: TextStyle(
                      color: Color(0xFF607086),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // â”€â”€ Banner Control de Asistencia (visible en todas las pestaÃ±as) â”€â”€
            _buildSessionBanner(),

            // TabBar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF39A900),
                indicatorWeight: 3,
                labelColor: const Color(0xFF39A900),
                unselectedLabelColor: const Color(0xFF607086),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'Resumen'),
                  Tab(text: 'Historial'),
                  Tab(text: 'Justificar'),

                ],
              ),
            ),

            const SizedBox(height: 10),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // â”€â”€ Tab 0: Resumen â”€â”€
                  _buildResumenTab(),

                  // â”€â”€ Tab 1: Historial â”€â”€
                  _buildHistorialTab(),

                  // â”€â”€ Tab 2: Justificar (vacÃ­o) â”€â”€
                  const Center(
                    child: Text(
                      'Justificar prÃ³ximamente',
                      style: TextStyle(color: Color(0xFF607086), fontSize: 15),
                    ),
                  ),


                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€â”€ Banner "Control de Asistencia de Aprendices" â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildSessionBanner() {
    // â”€â”€ Extraer datos de la respuesta real del backend â”€â”€
    final ficha     = _sessionsData?['ficha']         as Map<String, dynamic>?;
    final sesion    = _sessionsData?['sesion_activa'] as Map<String, dynamic>?;

    // Ficha / Programa
    final String numeroFicha = ficha?['numero_ficha']?.toString() ?? 'â€”';
    final programa = ficha?['programa'] as Map<String, dynamic>?;
    final String nombrePrograma = programa?['nombre_programa']?.toString() ?? 'â€”';

    // Instructor lÃ­der (viene en ficha.instructor_lider)
    final instructorLider = ficha?['instructor_lider'] as Map<String, dynamic>?;
    final bool instructorRegistrado = instructorLider?['registrado'] == true;
    final String nombreInstructor = instructorRegistrado
        ? (instructorLider?['nombre_completo']?.toString() ?? 'â€”')
        : 'â€”';

    // Jornada del grupo
    final String jornada = ficha?['jornada']?.toString() ?? 'â€”';

    // Fecha de la sesiÃ³n activa (formateada)
    String fechaFormateada = 'â€”';
    if (sesion != null) {
      final fechaRaw = sesion['fecha_clase']?.toString() ?? '';
      if (fechaRaw.length >= 10) {
        final parts = fechaRaw.substring(0, 10).split('-');
        if (parts.length == 3) {
          const meses = {
            '01': 'enero',    '02': 'febrero', '03': 'marzo',
            '04': 'abril',    '05': 'mayo',    '06': 'junio',
            '07': 'julio',    '08': 'agosto',  '09': 'septiembre',
            '10': 'octubre',  '11': 'noviembre','12': 'diciembre',
          };
          fechaFormateada = '${parts[2]} de ${meses[parts[1]] ?? ''} de ${parts[0]}';
        }
      }
    }

    // Estado de sesiÃ³n
    final bool haySession = sesion != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Control de Asistencia de Aprendices',
            style: TextStyle(
              color: Color(0xFF092444),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // â”€â”€ Estado: cargando â”€â”€
          if (_isLoadingSessions)
            const SizedBox(
              height: 20,
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF39A900),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Cargando sesiÃ³n...',
                    style: TextStyle(color: Color(0xFF607086), fontSize: 13),
                  ),
                ],
              ),
            )

          // â”€â”€ Estado: error al cargar â”€â”€
          else if (_sessionsError != null)
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 16, color: Color(0xFFF6A900)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'No se pudo cargar la sesiÃ³n',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: _fetchSessions,
                  child: const Text(
                    'Reintentar',
                    style: TextStyle(
                      color: Color(0xFF39A900),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )

          // â”€â”€ Estado: datos reales del backend â”€â”€
          else
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Fila principal con datos
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _bannerInlineText('Ficha: ', numeroFicha),
                            _bannerDivider(),
                            _bannerInlineText('Programa: ', nombrePrograma),
                            _bannerDivider(),
                            _bannerInlineText('Instructor: ', nombreInstructor),
                            _bannerDivider(),
                            _bannerInlineText('Jornada: ', jornada),
                            _bannerDivider(),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Estado: ',
                                  style: TextStyle(
                                    color: Color(0xFF607086),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                _sessionStatusChip(haySession),
                              ],
                            ),
                          ],
                        ),
                        // Segunda fila: Fecha (solo si hay sesiÃ³n activa)
                        if (haySession) ...[
                          const SizedBox(height: 8),
                          _bannerInlineText('Fecha de sesión: ', fechaFormateada),
                        ] else ...[
                          const SizedBox(height: 8),
                          Text(
                            _sessionsData?['mensaje_sesion_activa']?.toString() ??
                                'No hay sesiÃ³n activa en este momento',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _bannerInlineText(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF607086), fontSize: 13, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(color: Color(0xFF092444), fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _bannerDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      width: 1,
      height: 16,
      color: Colors.grey.shade300,
    );
  }

  Widget _sessionStatusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF39A900) : Colors.grey.shade400,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Activa' : 'Sin sesión',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showDetailBottomSheet(String apiEstado, String status, Color color) {
    final data = (_calendarData ?? []).where((e) => e['estado_asistencia'] == apiEstado).toList();
    final int count = data.length;
    final String instructor = 'N/A';
    final String ultActualizacion = data.isNotEmpty ? (data.first['actualizado_en'] as String? ?? 'N/A') : 'N/A';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tooltip / Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Detalle de $status',
                          style: TextStyle(
                            color: color,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          color: color,
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTooltipInfo('Cantidad', '$count'),
                        _buildTooltipInfo('Instructor', instructor),
                        _buildTooltipInfo('Ãšltima act.', ultActualizacion.length > 10 ? ultActualizacion.substring(0, 10) : ultActualizacion),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: data.isEmpty
                    ? Center(
                        child: Text(
                          'No hay registros de asistencia disponibles.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          final item = data[index];
                          final sesion = item['sesion'] as Map<String, dynamic>? ?? {};
                          final fecha = sesion['fecha_clase'] as String? ?? 'Sin fecha';
                          final materia = sesion['competencia']?['nombre_competencia'] ?? 'Sin asignar';
                          final diasFaltados = apiEstado == 'INASISTENTE' ? 1 : 0;
                          final observacion = item['observacion'] ?? 'Ninguna';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      fecha,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Color(0xFF092444),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Instructor: N/A',
                                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.book_outlined, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Materia: $materia',
                                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.date_range_outlined, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      'DÃ­as faltados: $diasFaltados',
                                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'ObservaciÃ³n: $observacion',
                                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTooltipInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.6)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  // â”€â”€â”€ Tab Resumen con dona â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildResumenTab() {
    if (_isLoadingDashboard) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF39A900)));
    }
    
    if (_dashboardError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Error al cargar el resumen:\n$_dashboardError',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF607086)),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchDashboard,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF39A900)),
              child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    // Mapeo de datos reales desde el backend
    final asistenciaTrimestre = _dashboardData?['asistencia_trimestre'];
    final int total = asistenciaTrimestre?['total'] ?? 0;

    // Trimestre activo â€” leÃ­do directamente del dashboard, sin variables extra
    final trimestreActivo = _dashboardData?['trimestre_activo'] as Map<String, dynamic>?;
    final bool trimestreRegistrado = trimestreActivo?['registrado'] == true;
    final int? numeroTrimestre = trimestreRegistrado
        ? (trimestreActivo?['numero_trimestre'] as int?)
        : null;

    int pendiente = 0;
    int presente = 0;
    int ausente = 0;
    int retardado = 0;
    int justificado = 0;

    if (asistenciaTrimestre != null && asistenciaTrimestre['estados'] != null) {
      final List<dynamic> estados = asistenciaTrimestre['estados'];
      for (var estadoInfo in estados) {
        final estado = estadoInfo['estado'];
        final cantidad = estadoInfo['cantidad'] as int;

        if (estado == 'PENDIENTE') {
          pendiente = cantidad;
        } else if (estado == 'PRESENTE') {
          presente = cantidad;
        } else if (estado == 'INASISTENTE') {
          ausente = cantidad;
        } else if (estado == 'TARDE') {
          retardado = cantidad;
        } else if (estado == 'JUSTIFICADA') {
          justificado = cantidad;
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              blurRadius: 10,
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
                const Text(
                  'Resumen',
                  style: TextStyle(
                    color: Color(0xFF092444),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                // Chip de trimestre â€” solo visible cuando el backend confirma
                // trimestre_activo.registrado == true
                if (numeroTrimestre != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Trimestre $numeroTrimestre',
                          style: const TextStyle(
                            color: Color(0xFF092444),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: Color(0xFF39A900),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Total sesiones: $total',
              style: const TextStyle(
                color: Color(0xFF607086),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            // Dona centrada
            Center(
              child: SizedBox(
                width: 180,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: MouseRegion(
                        onHover: (event) {
                          final center = const Offset(90, 90);
                          final dx = event.localPosition.dx - center.dx;
                          final dy = event.localPosition.dy - center.dy;
                          final distance = math.sqrt(dx * dx + dy * dy);
                          
                          const double strokeWidth = 180 * 0.18;
                          const double outerRadius = 90;
                          const double innerRadius = outerRadius - strokeWidth;

                          if (distance >= innerRadius && distance <= outerRadius) {
                            double angle = math.atan2(dy, dx);
                            double adjustedAngle = angle - (-math.pi / 2);
                            if (adjustedAngle < 0) adjustedAngle += 2 * math.pi;

                            final segments = [
                              {'cat': 'PENDIENTE', 'label': 'PENDIENTE', 'value': pendiente, 'color': Colors.grey.shade400},
                              {'cat': 'PRESENTE', 'label': 'PRESENTE', 'value': presente, 'color': const Color(0xFF39A900)},
                              {'cat': 'TARDE', 'label': 'TARDE', 'value': retardado, 'color': const Color(0xFFF6A900)},
                              {'cat': 'INASISTENTE', 'label': 'INASISTENTE', 'value': ausente, 'color': const Color(0xFFE53935)},
                              {'cat': 'JUSTIFICADA', 'label': 'JUSTIFICADA', 'value': justificado, 'color': const Color(0xFF1565C0)},
                            ];

                            double currentAngle = 0;
                            const double gap = 0.04;
                            
                            for (final seg in segments) {
                              final val = seg['value'] as int;
                              if (val == 0) continue;
                              
                              final double sweep = (val / total) * 2 * math.pi - gap;
                              if (adjustedAngle >= currentAngle && adjustedAngle <= currentAngle + sweep) {
                                setState(() {
                                  _hoveredSegmentData = seg;
                                  _hoverPosition = event.localPosition;
                                });
                                return;
                              }
                              currentAngle += sweep + gap;
                            }
                          }
                          if (_hoveredSegmentData != null) {
                            setState(() {
                              _hoveredSegmentData = null;
                              _hoverPosition = null;
                            });
                          }
                        },
                        onExit: (_) {
                          if (_hoveredSegmentData != null) {
                            setState(() {
                              _hoveredSegmentData = null;
                              _hoverPosition = null;
                            });
                          }
                        },
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapUp: (details) {
                            final center = const Offset(90, 90);
                            final dx = details.localPosition.dx - center.dx;
                            final dy = details.localPosition.dy - center.dy;
                            final distance = math.sqrt(dx * dx + dy * dy);
                            
                            const double strokeWidth = 180 * 0.18;
                            const double outerRadius = 90;
                            const double innerRadius = outerRadius - strokeWidth;

                            if (distance >= innerRadius && distance <= outerRadius) {
                              double angle = math.atan2(dy, dx);
                              double adjustedAngle = angle - (-math.pi / 2);
                              if (adjustedAngle < 0) adjustedAngle += 2 * math.pi;

                              final segments = [
                                {'cat': 'PENDIENTE', 'label': 'PENDIENTE', 'value': pendiente, 'color': Colors.grey.shade400},
                                {'cat': 'PRESENTE', 'label': 'PRESENTE', 'value': presente, 'color': const Color(0xFF39A900)},
                                {'cat': 'TARDE', 'label': 'TARDE', 'value': retardado, 'color': const Color(0xFFF6A900)},
                                {'cat': 'INASISTENTE', 'label': 'INASISTENTE', 'value': ausente, 'color': const Color(0xFFE53935)},
                                {'cat': 'JUSTIFICADA', 'label': 'JUSTIFICADA', 'value': justificado, 'color': const Color(0xFF1565C0)},
                              ];

                              double currentAngle = 0;
                              const double gap = 0.04;
                              
                              for (final seg in segments) {
                                final val = seg['value'] as int;
                                if (val == 0) continue;
                                
                                final double sweep = (val / total) * 2 * math.pi - gap;
                                if (adjustedAngle >= currentAngle && adjustedAngle <= currentAngle + sweep) {
                                  _showDetailBottomSheet(seg['cat'] as String, seg['label'] as String, seg['color'] as Color);
                                  break;
                                }
                                currentAngle += sweep + gap;
                              }
                            }
                          },
                          child: CustomPaint(
                            painter: _DonutChartPainter(
                              pendiente: pendiente,
                              presente: presente,
                              ausente: ausente,
                              retardado: retardado,
                              justificado: justificado,
                              total: total,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${((presente / (total == 0 ? 1 : total)) * 100).round()}%',
                                    style: const TextStyle(
                                      color: Color(0xFF092444),
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const Text(
                                    'PRESENTE',
                                    style: TextStyle(
                                      color: Color(0xFF607086),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_hoveredSegmentData != null && _hoverPosition != null)
                      Positioned(
                        left: _hoverPosition!.dx,
                        top: _hoverPosition!.dy + 20,
                        child: FractionalTranslation(
                          translation: const Offset(-0.5, 0),
                          child: Container(
                            width: 260,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))
                              ],
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 12, height: 12,
                                      decoration: BoxDecoration(color: _hoveredSegmentData!['color'] as Color, shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${_hoveredSegmentData!['label']}: ${_hoveredSegmentData!['value']} registros (${(((_hoveredSegmentData!['value'] as int) / total) * 100).round()}%)',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF092444)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Haz clic en el Ã­cono del ojo para ver el detalle',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            // Leyendas
            _statRow('PENDIENTE', pendiente, total, Colors.grey.shade400, 'PENDIENTE'),
            const SizedBox(height: 16),
            _statRow('PRESENTE', presente, total, const Color(0xFF39A900), 'PRESENTE'),
            const SizedBox(height: 16),
            _statRow('TARDE', retardado, total, const Color(0xFFF6A900), 'TARDE'),
            const SizedBox(height: 16),
            _statRow('INASISTENTE', ausente, total, const Color(0xFFE53935), 'INASISTENTE'),
            const SizedBox(height: 16),
            _statRow('JUSTIFICADA', justificado, total, const Color(0xFF1565C0), 'JUSTIFICADA'),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, int count, int total, Color color, String categoryId) {
    final double pct = total == 0 ? 0 : count / total;
    final int pctInt = (pct * 100).round();
    return InkWell(
      onTap: () {
        if (count > 0) _showDetailBottomSheet(categoryId, label, color);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF092444),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '$count',
                  style: const TextStyle(
                    color: Color(0xFF092444),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  child: Text(
                    '$pctInt%',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Color(0xFF607086),
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: const Icon(
                    Icons.visibility_outlined,
                    size: 14,
                    color: Color(0xFF092444),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorialTab() {
    if (_isLoadingCalendar) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF39A900)));
    }
    
    if (_calendarError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error al cargar el historial:\n$_calendarError',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF607086)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchCalendar,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF39A900)),
              child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    final List<Map<String, dynamic>> mappedData = (_calendarData ?? []).map((registro) {
      final estadoRaw = registro['estado_asistencia'] as String? ?? '';
      String status = estadoRaw;

      final sesion = registro['sesion'] as Map<String, dynamic>? ?? {};
      final fechaClase = sesion['fecha_clase'] as String? ?? 'Sin fecha';
      
      String formattedDate = fechaClase;
      if (fechaClase.length >= 10) {
        final parts = fechaClase.substring(0, 10).split('-');
        if (parts.length == 3) {
          final month = parts[1];
          final day = parts[2];
          
          const meses = {
            '01': 'ene', '02': 'feb', '03': 'mar', '04': 'abr',
            '05': 'mayo', '06': 'jun', '07': 'jul', '08': 'ago',
            '09': 'sep', '10': 'oct', '11': 'nov', '12': 'dic'
          };
          
          formattedDate = '$day ${meses[month] ?? ''}';
        }
      }

      final horaIni = sesion['hora_inicio_programada'] as String? ?? '';
      final horaFin = sesion['hora_fin_programada'] as String? ?? '';
      final formattedTime = (horaIni.isNotEmpty && horaFin.isNotEmpty) 
          ? '${horaIni.substring(0, 5)} - ${horaFin.substring(0, 5)}'
          : 'Sin registro';

      return {
        'date': formattedDate,
        'time': formattedTime,
        'status': status,
      };
    }).toList();

    final filteredData = _selectedFilter == 'Todos'
        ? mappedData
        : mappedData.where((e) => e['status'] == _selectedFilter).toList();

    return Column(
      children: [
        // Historial header con filtros
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Historial',
                style: TextStyle(
                  color: Color(0xFF092444),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: _showMonthPicker,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _selectedMonth,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down,
                              color: Colors.grey.shade600, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _showFilterPicker,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedFilter == 'Todos'
                              ? Colors.grey.shade300
                              : const Color(0xFF39A900),
                        ),
                        color: _selectedFilter == 'Todos'
                            ? Colors.transparent
                            : const Color(0xFF39A900).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.filter_list,
                        color: _selectedFilter == 'Todos'
                            ? Colors.grey.shade600
                            : const Color(0xFF39A900),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Lista
        Expanded(
          child: filteredData.isEmpty
              ? const Center(
                  child: Text(
                    'No hay registros de asistencia disponibles',
                    style: TextStyle(color: Color(0xFF607086), fontSize: 15),
                  ),
                )
              : ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            itemCount: filteredData.length,
            itemBuilder: (context, index) {
              final item = filteredData[index];
              final statusColor = _getStatusColor(item['status']);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item['status'] == 'PRESENTE'
                            ? Icons.check_circle_outline
                            : item['status'] == 'INASISTENTE'
                                ? Icons.cancel_outlined
                                : Icons.access_time,
                        color: statusColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['date'],
                            style: const TextStyle(
                              color: Color(0xFF092444),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item['time'],
                            style: const TextStyle(
                              color: Color(0xFF607086),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item['status'],
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Donut Chart Painter
class _DonutChartPainter extends CustomPainter {
  final int pendiente;
  final int presente;
  final int ausente;
  final int retardado;
  final int justificado;
  final int total;

  _DonutChartPainter({
    required this.pendiente,
    required this.presente,
    required this.ausente,
    required this.retardado,
    required this.justificado,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = size.width * 0.18;
    final Rect rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2 - strokeWidth / 2,
    );

    final List<Map<String, dynamic>> segments = [
      {'value': pendiente, 'color': Colors.grey.shade400},
      {'value': presente, 'color': const Color(0xFF39A900)},
      {'value': retardado, 'color': const Color(0xFFF6A900)},
      {'value': ausente, 'color': const Color(0xFFE53935)},
      {'value': justificado, 'color': const Color(0xFF1565C0)},
    ];

    double startAngle = -1.5707963;
    const double gap = 0.04;

    for (final seg in segments) {
      final int val = seg['value'] as int;
      if (val == 0) continue;
      final double sweep = (val / total) * 6.2831853 - gap;
      final Paint paint = Paint()
        ..color = seg['color'] as Color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
