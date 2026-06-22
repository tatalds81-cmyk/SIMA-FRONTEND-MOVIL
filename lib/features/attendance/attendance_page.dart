import 'package:file_picker/file_picker.dart';
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
  final TextEditingController _justificationDescriptionController = TextEditingController();
  String _selectedMonth = 'Mayo 2024';
  String _selectedFilter = 'Todos';
  Map<String, dynamic>? _hoveredSegmentData;
  Offset? _hoverPosition;

  // ── Calendario visual ────────────────────────────────────────────────
  int _selectedDay = 0;
  int _monthIndex = 0;
  int _year = 0;
  Map<int, String> _attendanceStatus = {};
  Map<int, Map<String, String>> _dayDetails = {};
  Map<int, String> _competencia = {};
  Map<int, String> _justEstado = {};
  Map<int, String> _observacion = {};

  static const List<String> _monthNames = [
    "Enero","Febrero","Marzo","Abril","Mayo","Junio",
    "Julio","Agosto","Septiembre","Octubre","Noviembre","Diciembre",
  ];

  bool _isLoadingDashboard = true;
  Map<String, dynamic>? _dashboardData;
  String? _dashboardError;

  bool _isLoadingCalendar = true;
  List<dynamic>? _calendarData;
  String? _calendarError;

  bool _isLoadingSessions = true;
  Map<String, dynamic>? _sessionsData;
  String? _sessionsError;

  final Map<String, PlatformFile?> _selectedJustificationFiles = {};
  final Map<String, bool> _isSubmittingJustification = {};
  static const int _maxJustificationBytes = 5 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.initialTabIndex.clamp(0, 2);
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: initialIndex,
    );
    _selectedDay = DateTime.now().day;
    _monthIndex = DateTime.now().month - 1;
    _year = DateTime.now().year;
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
      final String fechaRef = '$_year-${(_monthIndex + 1).toString().padLeft(2, '0')}-01';
      final data = await AttendanceService.getMyCalendar(periodo: 'mes', fechaReferencia: fechaRef);
      
      if (mounted) {
        final List<dynamic> registros = (data?['registros'] as List<dynamic>?) ?? [];
        final Map<int, String> statusMap = {};
        final Map<int, Map<String, String>> detailMap = {};
        final Map<int, String> competMap = {};
        final Map<int, String> justMap = {};
        final Map<int, String> obsMap = {};

        for (final reg in registros) {
          final String? fechaClase = reg['sesion']?['fecha_clase'];
          if (fechaClase == null) continue;

          final DateTime fecha = DateTime.parse(fechaClase);
          if (fecha.month != _monthIndex + 1 || fecha.year != _year) continue;

          final int day = fecha.day;
          final String ep05 = (reg['estado_asistencia'] ?? '').toString().toUpperCase();

          switch (ep05) {
            case 'PRESENTE':
            case 'TARDE':
              statusMap[day] = 'presente';
              break;
            case 'INASISTENTE':
              statusMap[day] = 'ausente';
              break;
            case 'JUSTIFICADA':
              statusMap[day] = 'justificada';
              break;
          }

          final String? hi = reg['sesion']?['hora_inicio_programada'];
          final String? hf = reg['sesion']?['hora_fin_programada'];
          if (hi != null && hf != null) {
            detailMap[day] = {
              'entrada': hi.length >= 5 ? hi.substring(0, 5) : hi,
              'salida': hf.length >= 5 ? hf.substring(0, 5) : hf,
            };
          }

          final String? nombreComp = reg['sesion']?['competencia']?['nombre_competencia'];
          if (nombreComp != null && nombreComp.isNotEmpty) {
            competMap[day] = nombreComp;
          }

          final String? obs = reg['observacion'];
          if (obs != null && obs.isNotEmpty) {
            obsMap[day] = obs;
          }

          final List<dynamic> justs = (reg['justificaciones'] as List<dynamic>?) ?? [];
          if (justs.isNotEmpty) {
            justs.sort((a, b) {
              final da = DateTime.tryParse(a['fecha_envio'] ?? '') ?? DateTime(2000);
              final db = DateTime.tryParse(b['fecha_envio'] ?? '') ?? DateTime(2000);
              return db.compareTo(da);
            });
            final String justEstado = (justs.first['estado'] ?? '').toString().toUpperCase();
            justMap[day] = justEstado;
          }
        }

        setState(() {
          _calendarData = registros;
          _attendanceStatus = statusMap;
          _dayDetails = detailMap;
          _competencia = competMap;
          _justEstado = justMap;
          _observacion = obsMap;
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
    _justificationDescriptionController.dispose();
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

  Future<void> _pickJustificationFile(String sessionId) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;
      if (file.size > _maxJustificationBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El archivo supera el máximo permitido de 5 MB.'),
              backgroundColor: Color(0xFFF4A900),
            ),
          );
        }
        return;
      }

      setState(() {
        _selectedJustificationFiles[sessionId] = file;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar archivo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitJustification(String sessionId) async {
    final file = _selectedJustificationFiles[sessionId];
    final description = _justificationDescriptionController.text.trim();

    if (file == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecciona un archivo de justificación.'),
            backgroundColor: Color(0xFFF4A900),
          ),
        );
      }
      return;
    }

    if (description.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Describe brevemente el motivo de la justificación.'),
            backgroundColor: Color(0xFFF4A900),
          ),
        );
      }
      return;
    }

    setState(() {
      _isSubmittingJustification[sessionId] = true;
    });

    try {
      await AttendanceService.submitJustification(
        sessionId: sessionId,
        description: description,
        file: file,
      );
      if (mounted) {
        _justificationDescriptionController.clear();
        _selectedJustificationFiles.remove(sessionId);
        _fetchCalendar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Justificación enviada correctamente.'),
            backgroundColor: Color(0xFF39A900),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar justificación: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingJustification[sessionId] = false;
        });
      }
    }
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
        return const Color(0xFFF6A900);
      case 'JUSTIFICADA':
        return const Color(0xFF1565C0);
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
                  Tab(text: 'Calendario'),
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

                  // â”€â”€ Tab 2: Justificar â”€â”€
                  _buildJustificarTab(),

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

  Widget _buildJustificarTab() {
    if (_isLoadingSessions) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF39A900)));
    }

    if (_sessionsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Error al cargar la sesión activa:\n$_sessionsError',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF607086)),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchSessions,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF39A900)),
              child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    final session = _sessionsData?['sesion_activa'] as Map<String, dynamic>?;
    if (session == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_empty, color: Color(0xFF607086), size: 50),
            const SizedBox(height: 14),
            const Text(
              'No hay sesión activa en este momento.',
              style: TextStyle(color: Color(0xFF607086), fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _fetchSessions,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF39A900)),
              child: const Text('Actualizar sesión', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    final String sessionId = session['id']?.toString() ?? '';
    final selectedFile = _selectedJustificationFiles[sessionId];
    final isSubmitting = _isSubmittingJustification[sessionId] == true;

    final String competencia = (session['competencia'] as Map<String, dynamic>?)?['nombre_competencia']?.toString() ?? 'Competencia no disponible';
    final String ambiente = (session['ambiente'] as Map<String, dynamic>?)?['nombre_ambiente']?.toString() ?? 'Ambiente no disponible';
    final String fechaRaw = session['fecha_clase']?.toString() ?? '';
    String fechaLegible = 'Fecha no disponible';
    if (fechaRaw.length >= 10) {
      final parts = fechaRaw.substring(0, 10).split('-');
      if (parts.length == 3) {
        final meses = {
          '01': 'enero', '02': 'febrero', '03': 'marzo', '04': 'abril',
          '05': 'mayo', '06': 'junio', '07': 'julio', '08': 'agosto',
          '09': 'septiembre', '10': 'octubre', '11': 'noviembre', '12': 'diciembre'
        };
        fechaLegible = '${parts[2]} de ${meses[parts[1]] ?? ''} de ${parts[0]}';
      }
    }

    final String horaInicio = session['hora_inicio']?.toString() ?? '';
    final String horaFin = session['hora_fin']?.toString() ?? '';
    final String horaTexto = (horaInicio.isNotEmpty && horaFin.isNotEmpty)
        ? '${horaInicio.substring(0, 5)} - ${horaFin.substring(0, 5)}'
        : 'Horario no disponible';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sesión activa disponible para justificar',
                  style: TextStyle(
                    color: Color(0xFF092444),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                _buildDetailRow(Icons.calendar_today, 'Fecha', fechaLegible),
                const SizedBox(height: 10),
                _buildDetailRow(Icons.access_time, 'Horario', horaTexto),
                const SizedBox(height: 10),
                _buildDetailRow(Icons.school, 'Competencia', competencia),
                const SizedBox(height: 10),
                _buildDetailRow(Icons.location_on, 'Ambiente', ambiente),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Adjunta tu justificante',
            style: TextStyle(
              color: Color(0xFF092444),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () => _pickJustificationFile(sessionId),
            icon: const Icon(Icons.attach_file_outlined),
            label: const Text(
              'Seleccionar archivo',
              textAlign: TextAlign.center,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF39A900),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              alignment: Alignment.center,
            ),
          ),
          if (selectedFile != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F8F4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF39A900).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Color(0xFF39A900)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selectedFile.name,
                      style: const TextStyle(color: Color(0xFF092444), fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            'Descripción',
            style: TextStyle(
              color: Color(0xFF092444),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _justificationDescriptionController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Describe el motivo de la falta o la justificación',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : () => _submitJustification(sessionId),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39A900),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                alignment: Alignment.center,
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      'Enviar',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Formato aceptado: PDF, JPG, JPEG, PNG. Tamaño máximo 5 MB.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF39A900)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF607086),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF092444),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Helpers de calendario ──────────────────────────────────────────────────
  int get _firstWeekday => DateTime(_year, _monthIndex + 1, 1).weekday - 1;
  int get _daysInMonth => DateTime(_year, _monthIndex + 2, 0).day;

  void _prevMonth() {
    setState(() {
      _selectedDay = 1;
      _monthIndex == 0 ? (_monthIndex = 11, _year--) : _monthIndex--;
    });
    _fetchCalendar();
  }

  void _nextMonth() {
    setState(() {
      _selectedDay = 1;
      _monthIndex == 11 ? (_monthIndex = 0, _year++) : _monthIndex++;
    });
    _fetchCalendar();
  }

  String _dayName(int day) {
    const n = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"];
    return n[DateTime(_year, _monthIndex + 1, day).weekday - 1];
  }

  // ── Helpers de color/texto ────────────────────────────────────────────────
  Color _statusColor(String? s) {
    switch (s) {
      case 'presente': return const Color(0xFF44C21E);
      case 'ausente': return const Color(0xFFE53935);
      case 'justificada': return const Color(0xFFF6A900);
      default: return const Color(0xFFBDBDBD);
    }
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'presente': return 'Presente';
      case 'ausente': return 'Ausente';
      case 'justificada': return 'Justificada';
      default: return 'Sin clase';
    }
  }

  Color _justColor(String estado) {
    switch (estado) {
      case 'APROBADA': return const Color(0xFF44C21E);
      case 'RECHAZADA': return const Color(0xFFE53935);
      case 'PENDIENTE': return const Color(0xFFF6A900);
      default: return Colors.grey;
    }
  }

  String _justLabel(String estado) {
    switch (estado) {
      case 'APROBADA': return 'Justificación aprobada';
      case 'RECHAZADA': return 'Justificación rechazada';
      case 'PENDIENTE': return 'Justificación pendiente de revisión';
      default: return '';
    }
  }

  IconData _justIcon(String estado) {
    switch (estado) {
      case 'APROBADA': return Icons.check_circle_outline;
      case 'RECHAZADA': return Icons.cancel_outlined;
      case 'PENDIENTE': return Icons.hourglass_empty_rounded;
      default: return Icons.info_outline;
    }
  }

  // ── Widgets auxiliares ─────────────────────────────────────────────────────
  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
      ],
    ),
    child: child,
  );

  Widget _navBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: const Color(0xFF6E7B8D)),
    ),
  );

  Widget _dot6(Color color) => Container(
    width: 6,
    height: 6,
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

  Widget _buildHistorialTab() {
    if (_isLoadingCalendar) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF39A900)));
    }

    if (_calendarError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 52, color: Color(0xFF607086)),
              const SizedBox(height: 14),
              Text(_calendarError!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF607086), fontSize: 14)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchCalendar,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Reintentar', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF44C21E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final int firstWeekday = _firstWeekday;
    final int daysInMonth = _daysInMonth;
    final int gridCells = (((firstWeekday + daysInMonth) / 7).ceil()) * 7;

    final String? selStatus = _attendanceStatus[_selectedDay];
    final Map<String, String>? selDetail = _dayDetails[_selectedDay];
    final String? selComp = _competencia[_selectedDay];
    final String? selJust = _justEstado[_selectedDay];
    final String? selObs = _observacion[_selectedDay];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
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
                  children: ["L", "M", "M", "J", "V", "S", "D"]
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 0,
                    childAspectRatio: 0.82,
                  ),
                  itemBuilder: (context, index) {
                    if (index < firstWeekday || index >= firstWeekday + daysInMonth) {
                      return const SizedBox.shrink();
                    }

                    final int day = index - firstWeekday + 1;
                    final bool isSelected = _selectedDay == day;
                    final String? status = _attendanceStatus[day];
                    final String? justDay = _justEstado[day];

                    return GestureDetector(
                      onTap: () => setState(() => _selectedDay = day),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF44C21E) : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$day',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : const Color(0xFF334155),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          if (justDay == 'PENDIENTE')
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _dot6(status != null ? _statusColor(status) : Colors.transparent),
                                const SizedBox(width: 2),
                                _dot6(const Color(0xFFF6A900)),
                              ],
                            )
                          else
                            _dot6(status != null ? _statusColor(status) : Colors.transparent),
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
                            "${_dayName(_selectedDay)}, $_selectedDay de ${_monthNames[_monthIndex].toLowerCase()}",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 4),
                              Text(
                                selDetail != null
                                    ? "${selDetail['entrada']} - ${selDetail['salida']}"
                                    : "Sin registro de horario",
                                style: const TextStyle(fontSize: 13, color: Color(0xFF607086)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

                if (selComp != null) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFEEF0F3)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.book_outlined, size: 16, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 8),
                      const Text('Competencia: ', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                      Expanded(
                        child: Text(
                          selComp,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                if (selJust != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: _justColor(selJust).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _justColor(selJust).withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        Icon(_justIcon(selJust), size: 16, color: _justColor(selJust)),
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

                if (selObs != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selObs,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF607086)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (selStatus == null) ...[
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      'Sin sesión registrada este día',
                      style: TextStyle(fontSize: 13, color: Color(0xFFBDBDBD)),
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
                Row(
                  children: [
                    _dot6(const Color(0xFFE53935)),
                    const SizedBox(width: 2),
                    _dot6(const Color(0xFFF6A900)),
                    const SizedBox(width: 8),
                    const Text(
                      'Ausente con justificación pendiente',
                      style: TextStyle(fontSize: 12, color: Color(0xFF607086)),
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
