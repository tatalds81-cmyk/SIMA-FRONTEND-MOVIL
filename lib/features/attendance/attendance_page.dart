import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:sima_movil_froned/services/attendance_service.dart';
import 'dart:math' as math;

class AttendancePage extends StatefulWidget {
  const AttendancePage({
    super.key,
    this.initialTabIndex = 0,
    this.initialSelectedJustificationDate,
  });

  final int initialTabIndex;
  final DateTime? initialSelectedJustificationDate;

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _justificationDescriptionController =
      TextEditingController();
  Map<String, dynamic>? _hoveredSegmentData;
  Offset? _hoverPosition;
  DateTime? _selectedJustificationDate;

  // â”€â”€ Calendario visual â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  int _selectedDay = 0;
  int _monthIndex = 0;
  int _year = 0;
  Map<int, String> _attendanceStatus = {};
  Map<int, Map<String, String>> _dayDetails = {};
  Map<int, String> _competencia = {};
  Map<int, String> _justEstado = {};
  Map<int, String> _observacion = {};
  final Set<String> _expandedAgendaRecords = {};

  static const List<String> _monthNames = [
    "Enero",
    "Febrero",
    "Marzo",
    "Abril",
    "Mayo",
    "Junio",
    "Julio",
    "Agosto",
    "Septiembre",
    "Octubre",
    "Noviembre",
    "Diciembre",
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

  bool _isLoadingJustifications = true;
  Map<String, dynamic>? _eligibleJustificationsData;
  String? _justificationsError;

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
    _selectedJustificationDate = widget.initialSelectedJustificationDate;
    _fetchDashboard();
    _fetchCalendar();
    _fetchSessions();
    _fetchEligibleJustifications();
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
      final String fechaRef =
          '$_year-${(_monthIndex + 1).toString().padLeft(2, '0')}-01';
      final data = await AttendanceService.getMyCalendar(
        periodo: 'mes',
        fechaReferencia: fechaRef,
      );

      if (mounted) {
        final List<dynamic> registros =
            (data?['registros'] as List<dynamic>?) ?? [];
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
          final String ep05 = _normalizeAttendanceState(
            reg['estado_ep05'] ?? reg['estado_asistencia'] ?? reg['estado'],
          );

          switch (ep05) {
            case 'PRESENTE':
              statusMap[day] = 'presente';
              break;
            case 'TARDE':
              statusMap[day] = 'tarde';
              break;
            case 'INASISTENTE':
            case 'INASISTENCIA':
              statusMap[day] = 'ausente';
              break;
            case 'JUSTIFICADA':
            case 'JUSTIFICADO':
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

          final String? nombreComp =
              reg['sesion']?['competencia']?['nombre_competencia'];
          if (nombreComp != null && nombreComp.isNotEmpty) {
            competMap[day] = nombreComp;
          }

          final String? obs = reg['observacion'];
          if (obs != null && obs.isNotEmpty) {
            obsMap[day] = obs;
          }

          final List<dynamic> justs =
              (reg['justificaciones'] as List<dynamic>?) ?? [];
          if (justs.isNotEmpty) {
            justs.sort((a, b) {
              final da =
                  DateTime.tryParse(a['fecha_envio'] ?? '') ?? DateTime(2000);
              final db =
                  DateTime.tryParse(b['fecha_envio'] ?? '') ?? DateTime(2000);
              return db.compareTo(da);
            });
            final String justEstado = (justs.first['estado'] ?? '')
                .toString()
                .toUpperCase();
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

  Future<void> _fetchEligibleJustifications() async {
    setState(() {
      _isLoadingJustifications = true;
      _justificationsError = null;
    });

    try {
      final data = await AttendanceService.getEligibleJustifications();
      if (mounted) {
        setState(() {
          _eligibleJustificationsData = data;
          _isLoadingJustifications = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _justificationsError = e.toString();
          _isLoadingJustifications = false;
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

  Future<void> _pickJustificationFile(String sessionId) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png'],
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

  Future<void> _submitJustification(String attendanceId) async {
    final file = _selectedJustificationFiles[attendanceId];
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
            content: Text(
              'Describe brevemente el motivo de la justificación.',
            ),
            backgroundColor: Color(0xFFF4A900),
          ),
        );
      }
      return;
    }

    setState(() {
      _isSubmittingJustification[attendanceId] = true;
    });

    try {
      await AttendanceService.submitJustification(
        attendanceId: attendanceId,
        description: description,
        file: file,
      );
      if (mounted) {
        _justificationDescriptionController.clear();
        _selectedJustificationFiles.remove(attendanceId);
        _fetchCalendar();
        _fetchEligibleJustifications();
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
          _isSubmittingJustification[attendanceId] = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF062E4F),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Principal
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Asistencia',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Registro y consulta de asistencia',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF2F5FB),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE1E7EF)),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: const Color(0xFF39A900),
                        indicatorWeight: 3,
                        labelColor: const Color(0xFF39A900),
                        unselectedLabelColor: const Color(0xFF607086),
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        tabs: const [
                          Tab(text: 'Resumen'),
                          Tab(text: 'Calendario'),
                          Tab(text: 'Justificar'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTabWithSessionBanner(_buildResumenTab()),
                          _buildAgendaTab(),
                          _buildJustificarTabBackend(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Banner "Control de Asistencia de Aprendices" Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  Widget _buildTabWithSessionBanner(Widget content) {
    return Column(
      children: [
        _buildSessionBanner(),
        Expanded(child: content),
      ],
    );
  }

  Widget _buildSessionBanner() {
    final sheet = _sessionsData?['ficha'] as Map<String, dynamic>?;
    final session = _sessionsData?['sesion_activa'] as Map<String, dynamic>?;
    final program = sheet?['programa'] as Map<String, dynamic>?;
    final leader = sheet?['instructor_lider'] as Map<String, dynamic>?;
    final sheetNumber = sheet?['numero_ficha']?.toString() ?? 'No disponible';
    final programName =
        program?['nombre_programa']?.toString() ?? 'Programa no disponible';
    final instructor =
        leader?['nombre_completo']?.toString() ?? 'Instructor no disponible';
    final journey = sheet?['jornada']?.toString() ?? 'Sin jornada';
    final hasSession = session != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E7EF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF092444).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
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
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoadingSessions)
            const LinearProgressIndicator(
              minHeight: 3,
              color: Color(0xFF39A900),
              backgroundColor: Color(0xFFE8EEF5),
            )
          else if (_sessionsError != null)
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'No fue posible cargar la ficha',
                    style: TextStyle(color: Color(0xFF607086), fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: _fetchSessions,
                  child: const Text('Reintentar'),
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF092F4F),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.school_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Ficha $sheetNumber',
                            style: const TextStyle(
                              color: Color(0xFF092444),
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '·',
                              style: TextStyle(color: Color(0xFF94A3B8)),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              programName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF607086),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 14,
                            color: Color(0xFF607086),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              instructor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF607086),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            journey,
                            style: const TextStyle(
                              color: Color(0xFF092444),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _sessionStatusChip(hasSession),
              ],
            ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildSessionBannerLegacy() {
    // Ã¢â€â‚¬Ã¢â€â‚¬ Extraer datos de la respuesta real del backend Ã¢â€â‚¬Ã¢â€â‚¬
    final ficha = _sessionsData?['ficha'] as Map<String, dynamic>?;
    final sesion = _sessionsData?['sesion_activa'] as Map<String, dynamic>?;

    // Ficha / Programa
    final String numeroFicha = ficha?['numero_ficha']?.toString() ?? 'No disponible';
    final programa = ficha?['programa'] as Map<String, dynamic>?;
    final String nombrePrograma =
        programa?['nombre_programa']?.toString() ?? 'No disponible';

    // Instructor líder (viene en ficha.instructor_lider)
    final instructorLider = ficha?['instructor_lider'] as Map<String, dynamic>?;
    final bool instructorRegistrado = instructorLider?['registrado'] == true;
    final String nombreInstructor = instructorRegistrado
        ? (instructorLider?['nombre_completo']?.toString() ?? 'No disponible')
        : 'No disponible';

    // Jornada del grupo
    final String jornada = ficha?['jornada']?.toString() ?? 'No disponible';

    // Fecha de la sesión activa (formateada)
    String fechaFormateada = 'No disponible';
    if (sesion != null) {
      final fechaRaw = sesion['fecha_clase']?.toString() ?? '';
      if (fechaRaw.length >= 10) {
        final parts = fechaRaw.substring(0, 10).split('-');
        if (parts.length == 3) {
          const meses = {
            '01': 'enero',
            '02': 'febrero',
            '03': 'marzo',
            '04': 'abril',
            '05': 'mayo',
            '06': 'junio',
            '07': 'julio',
            '08': 'agosto',
            '09': 'septiembre',
            '10': 'octubre',
            '11': 'noviembre',
            '12': 'diciembre',
          };
          fechaFormateada =
              '${parts[2]} de ${meses[parts[1]] ?? ''} de ${parts[0]}';
        }
      }
    }

    // Estado de sesión
    final bool haySession = sesion != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E7EF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 8),
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

          // Estado: cargando
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
                    'Cargando sesión...',
                    style: TextStyle(color: Color(0xFF607086), fontSize: 13),
                  ),
                ],
              ),
            )
          // Estado: error al cargar
          else if (_sessionsError != null)
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: Color(0xFFF6A900),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'No se pudo cargar la sesión',
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
          // Estado: datos reales del backend
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
                        // Segunda fila: Fecha (solo si hay sesión activa)
                        if (haySession) ...[
                          const SizedBox(height: 8),
                          _bannerInlineText(
                            'Fecha de sesión: ',
                            fechaFormateada,
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          Text(
                            _sessionsData?['mensaje_sesion_activa']
                                    ?.toString() ??
                                'No hay sesión activa en este momento',
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
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF607086),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF092444),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
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
        color: isActive
            ? const Color(0xFF39A900).withValues(alpha: 0.13)
            : const Color(0xFFF6A900).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Activa' : 'Sin sesión',
        style: TextStyle(
          color: isActive ? const Color(0xFF2B8A00) : const Color(0xFF9A6500),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _normalizeAttendanceState(Object? value) {
    final rawState = value?.toString().trim().toUpperCase() ?? '';
    final state = rawState
        .replaceAll('\u00C1', 'A')
        .replaceAll('\u00C9', 'E')
        .replaceAll('\u00CD', 'I')
        .replaceAll('\u00D3', 'O')
        .replaceAll('\u00DA', 'U');
    switch (state) {
      case 'ASISTENCIA':
      case 'ASISTENTE':
      case 'ASISTIO':
      case 'ASISTE':
      case 'PRESENTE':
        return 'PRESENTE';
      case 'INASISTENTE':
      case 'AUSENTE':
      case 'FALTA':
        return 'INASISTENCIA';
      case 'RETARDO':
      case 'RETARDADO':
      case 'TARDANZA':
      case 'LLEGO TARDE':
        return 'TARDE';
      case 'JUSTIFICADA':
      case 'JUSTIFICACION':
        return 'JUSTIFICADO';
      default:
        return state;
    }
  }

  int _toCount(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _firstText(List<Object?> values) {
    for (final value in values) {
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  String _instructorNameFromSession(Map<String, dynamic> session) {
    final instructor = session['instructor'] as Map<String, dynamic>?;
    final leader = session['instructor_lider'] as Map<String, dynamic>?;
    final ficha = session['ficha'] as Map<String, dynamic>?;
    final fichaLeader = ficha?['instructor_lider'] as Map<String, dynamic>?;

    return _firstText([
      instructor?['nombre_completo'],
      instructor?['nombreCompleto'],
      instructor?['nombre'],
      leader?['nombre_completo'],
      leader?['nombreCompleto'],
      leader?['nombre'],
      fichaLeader?['nombre_completo'],
      fichaLeader?['nombreCompleto'],
      fichaLeader?['nombre'],
      session['nombre_instructor'],
      session['instructor_nombre'],
    ]);
  }

  bool _sameAttendanceState(Object? item, String expected) {
    if (item is! Map<String, dynamic>) return false;
    final rawState = item['estado_ep05'] ?? item['estado_asistencia'];
    return _normalizeAttendanceState(rawState) ==
        _normalizeAttendanceState(expected);
  }

  void _showDetailBottomSheet(String apiEstado, String status, Color color) {
    final data = (_calendarData ?? [])
        .where((e) => _sameAttendanceState(e, apiEstado))
        .toList();
    final int count = data.length;
    final firstSession = data.isNotEmpty
        ? (data.first['sesion'] as Map<String, dynamic>? ?? const {})
        : const <String, dynamic>{};
    final String instructor = _firstText([
      _instructorNameFromSession(firstSession),
      'No disponible',
    ]);
    final String ultActualizacion = data.isNotEmpty
        ? (data.first['actualizado_en'] as String? ?? 'N/A')
        : 'N/A';

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
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTooltipInfo('Cantidad', '$count'),
                        _buildTooltipInfo('Instructor', instructor),
                        _buildTooltipInfo(
                          'Última act.',
                          ultActualizacion.length > 10
                              ? ultActualizacion.substring(0, 10)
                              : ultActualizacion,
                        ),
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
                          final sesion =
                              item['sesion'] as Map<String, dynamic>? ?? {};
                          final fecha =
                              sesion['fecha_clase'] as String? ?? 'Sin fecha';
                          final materia =
                              sesion['competencia']?['nombre_competencia'] ??
                              'Sin asignar';
                          final instructorName = _firstText([
                            _instructorNameFromSession(sesion),
                            'No disponible',
                          ]);
                          final diasFaltados =
                              _normalizeAttendanceState(apiEstado) == 'INASISTENCIA'
                              ? 1
                              : 0;
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
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
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
                                    const Icon(
                                      Icons.person_outline,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Instructor: $instructorName',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.book_outlined,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Materia: $materia',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.date_range_outlined,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Días faltados: $diasFaltados',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Observación: $observacion',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 13,
                                        ),
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
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Tab Resumen con dona Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  Widget _buildResumenTab() {
    if (_isLoadingDashboard) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF39A900)),
      );
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39A900),
              ),
              child: const Text(
                'Reintentar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    // Mapeo de datos reales desde el backend
    final asistenciaTrimestre = _dashboardData?['asistencia_trimestre'];
    // Fallback temporal hasta que el backend confirme el trimestre activo.
    final trimestreActivo =
        _dashboardData?['trimestre_activo'] as Map<String, dynamic>?;
    final bool trimestreRegistrado = trimestreActivo?['registrado'] == true;
    final int numeroTrimestre = trimestreRegistrado
        ? ((trimestreActivo?['numero_trimestre'] as int?) ?? 5)
        : 5;

    int presente = 0;
    int ausente = 0;
    int retardado = 0;
    int justificado = 0;

    if (asistenciaTrimestre != null && asistenciaTrimestre['estados'] != null) {
      final estadosRaw = asistenciaTrimestre['estados'];
      final estados = estadosRaw is Map
          ? estadosRaw.entries
              .map((entry) => {'estado': entry.key, 'cantidad': entry.value})
              .toList()
          : (estadosRaw as List<dynamic>? ?? []);

      for (var estadoInfo in estados) {
        if (estadoInfo is! Map) continue;
        final estado = _normalizeAttendanceState(estadoInfo['estado']);
        final cantidad = _toCount(estadoInfo['cantidad']);

        if (estado == 'PRESENTE') {
          presente += cantidad;
        } else if (estado == 'INASISTENCIA') {
          ausente += cantidad;
        } else if (estado == 'TARDE') {
          retardado += cantidad;
        } else if (estado == 'JUSTIFICADO') {
          justificado += cantidad;
        }
      }
    }

    if (presente + ausente + retardado + justificado == 0) {
      for (final item in _calendarData ?? const []) {
        if (item is! Map<String, dynamic>) continue;
        final estado = _normalizeAttendanceState(
          item['estado_ep05'] ?? item['estado_asistencia'] ?? item['estado'],
        );

        if (estado == 'PRESENTE') {
          presente += 1;
        } else if (estado == 'INASISTENCIA') {
          ausente += 1;
        } else if (estado == 'TARDE') {
          retardado += 1;
        } else if (estado == 'JUSTIFICADO') {
          justificado += 1;
        }
      }
    }

    final int chartTotal = presente + ausente + retardado + justificado;
    final int attendancePercent = chartTotal == 0
        ? 0
        : (((presente + retardado) / chartTotal) * 100).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      child: Container(
        padding: const EdgeInsets.all(14),
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
                Text(
                  'Resumen · $chartTotal ${chartTotal == 1 ? 'sesión' : 'sesiones'}',
                  style: const TextStyle(
                    color: Color(0xFF092444),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Trim. $numeroTrimestre',
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
            const SizedBox(height: 20),
            // Dona centrada
            Center(
              child: SizedBox(
                width: 150,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: MouseRegion(
                        onHover: (event) {
                          final center = const Offset(75, 75);
                          final dx = event.localPosition.dx - center.dx;
                          final dy = event.localPosition.dy - center.dy;
                          final distance = math.sqrt(dx * dx + dy * dy);

                          const double strokeWidth = 150 * 0.18;
                          const double outerRadius = 75;
                          const double innerRadius = outerRadius - strokeWidth;

                          if (distance >= innerRadius &&
                              distance <= outerRadius) {
                            double angle = math.atan2(dy, dx);
                            double adjustedAngle = angle - (-math.pi / 2);
                            if (adjustedAngle < 0) adjustedAngle += 2 * math.pi;

                            final segments = [
                              {
                                'cat': 'PRESENTE',
                                'label': 'PRESENTE',
                                'value': presente,
                                'color': const Color(0xFF39A900),
                              },
                              {
                                'cat': 'TARDE',
                                'label': 'TARDE',
                                'value': retardado,
                                'color': const Color(0xFFF6A900),
                              },
                              {
                                'cat': 'INASISTENCIA',
                                'label': 'INASISTENTE',
                                'value': ausente,
                                'color': const Color(0xFFE53935),
                              },
                              {
                                'cat': 'JUSTIFICADO',
                                'label': 'JUSTIFICADA',
                                'value': justificado,
                                'color': const Color(0xFF1565C0),
                              },
                            ];

                            double currentAngle = 0;
                            const double gap = 0.04;

                            for (final seg in segments) {
                              final val = seg['value'] as int;
                              if (val == 0) continue;

                              final double sweep =
                                  (val / chartTotal) * 2 * math.pi - gap;
                              if (adjustedAngle >= currentAngle &&
                                  adjustedAngle <= currentAngle + sweep) {
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
                            final center = const Offset(75, 75);
                            final dx = details.localPosition.dx - center.dx;
                            final dy = details.localPosition.dy - center.dy;
                            final distance = math.sqrt(dx * dx + dy * dy);

                            const double strokeWidth = 150 * 0.18;
                            const double outerRadius = 75;
                            const double innerRadius =
                                outerRadius - strokeWidth;

                            if (distance >= innerRadius &&
                                distance <= outerRadius) {
                              double angle = math.atan2(dy, dx);
                              double adjustedAngle = angle - (-math.pi / 2);
                              if (adjustedAngle < 0) {
                                adjustedAngle += 2 * math.pi;
                              }

                              final segments = [
                                {
                                  'cat': 'PRESENTE',
                                  'label': 'PRESENTE',
                                  'value': presente,
                                  'color': const Color(0xFF39A900),
                                },
                                {
                                  'cat': 'TARDE',
                                  'label': 'TARDE',
                                  'value': retardado,
                                  'color': const Color(0xFFF6A900),
                                },
                                {
                                  'cat': 'INASISTENCIA',
                                  'label': 'INASISTENTE',
                                  'value': ausente,
                                  'color': const Color(0xFFE53935),
                                },
                                {
                                  'cat': 'JUSTIFICADO',
                                  'label': 'JUSTIFICADA',
                                  'value': justificado,
                                  'color': const Color(0xFF1565C0),
                                },
                              ];

                              double currentAngle = 0;
                              const double gap = 0.04;

                              for (final seg in segments) {
                                final val = seg['value'] as int;
                                if (val == 0) continue;

                                final double sweep =
                                    (val / chartTotal) * 2 * math.pi - gap;
                                if (adjustedAngle >= currentAngle &&
                                    adjustedAngle <= currentAngle + sweep) {
                                  _showDetailBottomSheet(
                                    seg['cat'] as String,
                                    seg['label'] as String,
                                    seg['color'] as Color,
                                  );
                                  break;
                                }
                                currentAngle += sweep + gap;
                              }
                            }
                          },
                          child: CustomPaint(
                            painter: _DonutChartPainter(
                              presente: presente,
                              ausente: ausente,
                              retardado: retardado,
                              justificado: justificado,
                              total: chartTotal,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$attendancePercent%',
                                    style: const TextStyle(
                                      color: Color(0xFF092444),
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const Text(
                                    'ASISTENCIA',
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
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
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
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color:
                                            _hoveredSegmentData!['color']
                                                as Color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${_hoveredSegmentData!['label']}: ${_hoveredSegmentData!['value']} registros (${chartTotal == 0 ? 0 : (((_hoveredSegmentData!['value'] as int) / chartTotal) * 100).round()}%)',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Color(0xFF092444),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Haz clic en el ícono del ojo para ver el detalle',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
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
            _statRow(
              'PRESENTE',
              presente,
              chartTotal,
              const Color(0xFF39A900),
              'PRESENTE',
            ),
            const SizedBox(height: 16),
            _statRow(
              'TARDE',
              retardado,
              chartTotal,
              const Color(0xFFF6A900),
              'TARDE',
            ),
            const SizedBox(height: 16),
            _statRow(
              'INASISTENTE',
              ausente,
              chartTotal,
              const Color(0xFFE53935),
              'INASISTENCIA',
            ),
            const SizedBox(height: 16),
            _statRow(
              'JUSTIFICADA',
              justificado,
              chartTotal,
              const Color(0xFF1565C0),
              'JUSTIFICADO',
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(
    String label,
    int count,
    int total,
    Color color,
    String categoryId,
  ) {
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
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
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
                SizedBox(
                  width: 46,
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

  Map<String, dynamic>? _findJustificationForDate(List<dynamic> inasistencias) {
    if (_selectedJustificationDate == null) return null;

    for (final dynamic item in inasistencias) {
      if (item is! Map<String, dynamic>) continue;
      final session = item['sesion'] as Map<String, dynamic>?;
      final fechaRaw = session?['fecha_clase']?.toString() ?? '';
      if (fechaRaw.length >= 10) {
        final fecha = DateTime.tryParse(fechaRaw.substring(0, 10));
        if (fecha != null &&
            fecha.year == _selectedJustificationDate!.year &&
            fecha.month == _selectedJustificationDate!.month &&
            fecha.day == _selectedJustificationDate!.day) {
          return item;
        }
      }
    }
    return null;
  }

  Widget _buildJustificarTabBackend() {
    if (_isLoadingJustifications) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF39A900)),
      );
    }

    if (_justificationsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Error al cargar justificaciones:\n$_justificationsError',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF607086)),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchEligibleJustifications,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39A900),
              ),
              child: const Text(
                'Reintentar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    final inasistencias =
        (_eligibleJustificationsData?['inasistencias'] as List<dynamic>?) ??
            const [];
    if (inasistencias.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.assignment_turned_in_outlined,
              color: Color(0xFF607086),
              size: 50,
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _eligibleJustificationsData?['mensaje']?.toString() ??
                    'No tienes inasistencias disponibles para justificar.',
                style: const TextStyle(color: Color(0xFF607086), fontSize: 15),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _fetchEligibleJustifications,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39A900),
              ),
              child: const Text(
                'Actualizar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    final Map<String, dynamic>? selectedItem =
        _findJustificationForDate(inasistencias) ??
            (inasistencias.isNotEmpty
                ? inasistencias.first as Map<String, dynamic>
                : null);
    if (selectedItem == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.assignment_turned_in_outlined,
              color: Color(0xFF607086),
              size: 50,
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _eligibleJustificationsData?['mensaje']?.toString() ??
                    'No tienes inasistencias disponibles para justificar.',
                style: const TextStyle(color: Color(0xFF607086), fontSize: 15),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _fetchEligibleJustifications,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39A900),
              ),
              child: const Text(
                'Actualizar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    final item = selectedItem;
    final session = item['sesion'] as Map<String, dynamic>? ?? const {};
    final attendanceId = item['id_asistencia']?.toString() ?? '';
    final selectedFile = _selectedJustificationFiles[attendanceId];
    final isSubmitting = _isSubmittingJustification[attendanceId] == true;

    final competencia =
        (session['competencia'] as Map<String, dynamic>?)?['nombre_competencia']
                ?.toString() ??
            'Competencia no disponible';
    final ambiente =
        (session['ambiente'] as Map<String, dynamic>?)?['nombre_ambiente']
                ?.toString() ??
            'Ambiente no disponible';
    final fechaRaw = session['fecha_clase']?.toString() ?? '';
    var fechaLegible = 'Fecha no disponible';
    if (fechaRaw.length >= 10) {
      final parts = fechaRaw.substring(0, 10).split('-');
      if (parts.length == 3) {
        fechaLegible = '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    }

    final horaInicio = session['hora_inicio']?.toString() ?? '';
    final horaFin = session['hora_fin']?.toString() ?? '';
    final horaTexto = (horaInicio.length >= 5 && horaFin.length >= 5)
        ? '${horaInicio.substring(0, 5)} - ${horaFin.substring(0, 5)}'
        : 'Horario no disponible';
    final fechaLimite = item['fecha_limite']?.toString().split('T').first ?? '';

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
                  'Inasistencia disponible para justificar',
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
                if (fechaLimite.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildDetailRow(
                    Icons.event_available_outlined,
                    'Fecha límite',
                    fechaLimite,
                  ),
                ],
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
            onPressed: () => _pickJustificationFile(attendanceId),
            icon: const Icon(Icons.attach_file_outlined),
            label: const Text('Seleccionar archivo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF39A900),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            ),
          ),
          if (selectedFile != null) ...[
            const SizedBox(height: 12),
            Text(
              selectedFile.name,
              style: const TextStyle(
                color: Color(0xFF092444),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
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
              hintText: 'Describe el motivo de la falta',
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
              onPressed: isSubmitting
                  ? null
                  : () => _submitJustification(attendanceId),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39A900),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text('Enviar'),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Formato aceptado: PDF o PNG. Tamaño máximo 5 MB.',
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
                style: const TextStyle(color: Color(0xFF607086), fontSize: 13),
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

  // â”€â”€ Helpers de calendario â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
    const n = [
      "Lunes",
      "Martes",
      "Miércoles",
      "Jueves",
      "Viernes",
      "Sábado",
      "Domingo",
    ];
    return n[DateTime(_year, _monthIndex + 1, day).weekday - 1];
  }

  // â”€â”€ Helpers de color/texto â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Color _statusColor(String? s) {
    switch (s) {
      case 'presente':
        return const Color(0xFF44C21E);
      case 'tarde':
        return const Color(0xFFF6A900);
      case 'ausente':
        return const Color(0xFFE53935);
      case 'justificada':
        return const Color(0xFFF6A900);
      default:
        return const Color(0xFFBDBDBD);
    }
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'presente':
        return 'Presente';
      case 'tarde':
        return 'Tarde';
      case 'ausente':
        return 'Inasistente';
      case 'justificada':
        return 'Justificado';
      default:
        return 'Sin clase';
    }
  }

  bool _canShowJustifyButton(String? status, String? justificationStatus) {
    if (justificationStatus != null && justificationStatus.isNotEmpty) {
      return false;
    }
    if (status != 'ausente' && status != 'tarde') {
      return false;
    }

    final classDate = DateTime(_year, _monthIndex + 1, _selectedDay);
    final now = DateTime.now();
    final visibleUntil = classDate.add(const Duration(days: 3));
    return !now.isBefore(classDate) && now.isBefore(visibleUntil);
  }

  void _goToJustificationsTab() {
    _tabController.animateTo(2);
    _fetchEligibleJustifications();
  }

  Color _justColor(String estado) {
    switch (estado) {
      case 'APROBADA':
        return const Color(0xFF44C21E);
      case 'RECHAZADA':
        return const Color(0xFFE53935);
      case 'PENDIENTE':
        return const Color(0xFFF6A900);
      default:
        return Colors.grey;
    }
  }

  String _justLabel(String estado) {
    switch (estado) {
      case 'APROBADA':
        return 'Justificación aprobada';
      case 'RECHAZADA':
        return 'Justificación rechazada';
      case 'PENDIENTE':
        return 'Justificación pendiente de revisión';
      default:
        return '';
    }
  }

  IconData _justIcon(String estado) {
    switch (estado) {
      case 'APROBADA':
        return Icons.check_circle_outline;
      case 'RECHAZADA':
        return Icons.cancel_outlined;
      case 'PENDIENTE':
        return Icons.hourglass_empty_rounded;
      default:
        return Icons.info_outline;
    }
  }

  // â”€â”€ Widgets auxiliares â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

  DateTime get _agendaSelectedDate =>
      DateTime(_year, _monthIndex + 1, _selectedDay);

  List<DateTime> get _agendaWeek {
    final selected = _agendaSelectedDate;
    final sunday = selected.subtract(Duration(days: selected.weekday % 7));
    return List.generate(7, (index) => sunday.add(Duration(days: index)));
  }

  Future<void> _selectAgendaDate(DateTime date) async {
    final changesMonth = date.month != _monthIndex + 1 || date.year != _year;
    setState(() {
      _selectedDay = date.day;
      _monthIndex = date.month - 1;
      _year = date.year;
    });
    if (changesMonth) await _fetchCalendar();
  }

  void _changeAgendaWeek(int direction) {
    _selectAgendaDate(
      _agendaSelectedDate.add(Duration(days: direction * 7)),
    );
  }

  String? _agendaStatusForDate(DateTime date) {
    if (date.year != _year || date.month != _monthIndex + 1) return null;
    return _attendanceStatus[date.day];
  }

  List<Map<String, dynamic>> _agendaRecords() {
    final result = <Map<String, dynamic>>[];
    for (final raw in _calendarData ?? const <dynamic>[]) {
      if (raw is! Map) continue;
      final record = Map<String, dynamic>.from(raw);
      final session = record['sesion'];
      if (session is! Map) continue;
      final date = DateTime.tryParse(session['fecha_clase']?.toString() ?? '');
      if (date != null &&
          date.year == _year &&
          date.month == _monthIndex + 1 &&
          date.day == _selectedDay) {
        result.add(record);
      }
    }
    result.sort((a, b) {
      final aSession = a['sesion'] as Map?;
      final bSession = b['sesion'] as Map?;
      return (aSession?['hora_inicio_programada']?.toString() ?? '').compareTo(
        bSession?['hora_inicio_programada']?.toString() ?? '',
      );
    });
    return result;
  }

  String _agendaText(List<dynamic> values, [String fallback = '']) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return fallback;
  }

  String _agendaTime(dynamic value) {
    final text = value?.toString() ?? '';
    return text.length >= 5 ? text.substring(0, 5) : text;
  }

  String _latestJustification(Map<String, dynamic> record) {
    final raw = record['justificaciones'];
    if (raw is! List || raw.isEmpty) return '';
    final items = raw.whereType<Map>().toList()
      ..sort(
        (a, b) => (b['fecha_envio']?.toString() ?? '').compareTo(
          a['fecha_envio']?.toString() ?? '',
        ),
      );
    return items.isEmpty
        ? ''
        : items.first['estado']?.toString().toUpperCase() ?? '';
  }

  ({String label, Color color}) _agendaStatus(
    Map<String, dynamic> record,
  ) {
    final justification = _latestJustification(record);
    if (justification == 'APROBADA') {
      return (label: 'Justificado', color: const Color(0xFF1565C0));
    }
    if (justification == 'PENDIENTE') {
      return (label: 'En revisión', color: const Color(0xFFF6A900));
    }
    final state = _normalizeAttendanceState(
      record['estado_ep05'] ?? record['estado_asistencia'] ?? record['estado'],
    );
    switch (state) {
      case 'PRESENTE':
        return (label: 'Presente', color: const Color(0xFF39A900));
      case 'TARDE':
        return (label: 'Tarde', color: const Color(0xFFF6A900));
      case 'JUSTIFICADA':
      case 'JUSTIFICADO':
        return (label: 'Justificado', color: const Color(0xFF1565C0));
      case 'INASISTENTE':
      case 'INASISTENCIA':
        return (label: 'Inasistente', color: const Color(0xFFE53935));
      default:
        return (label: 'Pendiente', color: const Color(0xFF607086));
    }
  }

  String _agendaRecordKey(
    Map<String, dynamic> record,
    Map<String, dynamic> session,
  ) {
    return _agendaText([
      record['id_asistencia'],
      session['id_sesion'],
      session['id'],
      '${session['fecha_clase']}-${session['hora_inicio_programada']}',
    ]);
  }

  Widget _agendaDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF39A900)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Color(0xFF607086),
                  fontSize: 12.5,
                  height: 1.3,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(
                      color: Color(0xFF092444),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgendaRecord(Map<String, dynamic> record) {
    final session = Map<String, dynamic>.from(
      record['sesion'] as Map? ?? const {},
    );
    final competence = session['competencia'] as Map?;
    final environment = session['ambiente'] as Map?;
    final status = _agendaStatus(record);
    final justification = _latestJustification(record);
    final title = _agendaText([
      competence?['nombre_competencia'],
      session['nombre_competencia'],
      session['nombre'],
    ], 'Sesión programada');
    final instructor = _agendaText([
      _instructorNameFromSession(session),
    ], 'Sin instructor');
    final room = _agendaText([
      environment?['nombre_ambiente'],
      environment?['nombre'],
      session['ambiente_nombre'],
    ], 'Ambiente por definir');
    final start = _agendaTime(session['hora_inicio_programada']);
    final end = _agendaTime(session['hora_fin_programada']);
    final observation = _agendaText([
      record['observacion'],
      justification == 'RECHAZADA'
          ? 'Soporte rechazado. Puedes enviarlo nuevamente.'
          : null,
    ]);
    final state = _normalizeAttendanceState(
      record['estado_ep05'] ?? record['estado_asistencia'] ?? record['estado'],
    );
    final canJustify = justification == 'RECHAZADA' ||
        _canShowJustifyButton(
          state == 'TARDE'
              ? 'tarde'
              : (state == 'INASISTENTE' || state == 'INASISTENCIA')
                  ? 'ausente'
                  : null,
          justification,
        );
    final recordKey = _agendaRecordKey(record, session);
    final isExpanded = _expandedAgendaRecords.contains(recordKey);
    final sessionSheet = session['ficha'] as Map?;
    final activeSheet = _sessionsData?['ficha'] as Map?;
    final sheetNumber = _agendaText([
      sessionSheet?['numero_ficha'],
      activeSheet?['numero_ficha'],
    ], 'No disponible');
    final program = _agendaText([
      (sessionSheet?['programa'] as Map?)?['nombre_programa'],
      (activeSheet?['programa'] as Map?)?['nombre_programa'],
      session['programa_nombre'],
    ], 'No disponible');
    final date = _agendaText([session['fecha_clase']], 'No disponible');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4EAF2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF092444).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: status.color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 15,
                            color: Color(0xFF607086),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              start.isEmpty
                                  ? 'Horario por definir'
                                  : '$start${end.isEmpty ? '' : ' - $end'}',
                              style: const TextStyle(
                                color: Color(0xFF607086),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: status.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.label,
                              style: TextStyle(
                                color: status.color,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF092444),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '$instructor · $room',
                        style: const TextStyle(
                          color: Color(0xFF607086),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (observation.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          observation,
                          style: TextStyle(
                            color: status.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedAgendaRecords.remove(recordKey);
                            } else {
                              _expandedAgendaRecords.add(recordKey);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isExpanded ? 'Ver menos' : 'Ver más información',
                                style: const TextStyle(
                                  color: Color(0xFF092444),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 4),
                              AnimatedRotation(
                                turns: isExpanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 180),
                                child: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 19,
                                  color: Color(0xFF39A900),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 220),
                        crossFadeState: isExpanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        firstChild: const SizedBox(width: double.infinity),
                        secondChild: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F8FC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE1E7EF)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _agendaDetailRow(
                                Icons.calendar_today_outlined,
                                'Fecha',
                                date,
                              ),
                              _agendaDetailRow(
                                Icons.badge_outlined,
                                'Ficha',
                                sheetNumber,
                              ),
                              _agendaDetailRow(
                                Icons.school_outlined,
                                'Programa',
                                program,
                              ),
                              _agendaDetailRow(
                                Icons.menu_book_outlined,
                                'Competencia',
                                title,
                              ),
                              _agendaDetailRow(
                                Icons.person_outline_rounded,
                                'Instructor',
                                instructor,
                              ),
                              _agendaDetailRow(
                                Icons.place_outlined,
                                'Ambiente',
                                room,
                              ),
                              _agendaDetailRow(
                                Icons.verified_outlined,
                                'Estado',
                                status.label,
                              ),
                              if (justification.isNotEmpty)
                                _agendaDetailRow(
                                  Icons.description_outlined,
                                  'Justificación',
                                  _justLabel(justification),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (canJustify) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            onPressed: _goToJustificationsTab,
                            icon: const Icon(Icons.upload_file_rounded, size: 16),
                            label: Text(
                              justification == 'RECHAZADA'
                                  ? 'Reintentar'
                                  : 'Justificar',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF092444),
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgendaTab() {
    if (_isLoadingCalendar) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF39A900)),
      );
    }
    if (_calendarError != null) {
      return Center(
        child: ElevatedButton.icon(
          onPressed: _fetchCalendar,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Reintentar'),
        ),
      );
    }

    const dayNames = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    final selected = _agendaSelectedDate;
    final today = DateUtils.dateOnly(DateTime.now());
    final records = _agendaRecords();
    final isToday = DateUtils.isSameDay(selected, today);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isToday ? 'Hoy' : _dayName(_selectedDay),
                      style: const TextStyle(
                        color: Color(0xFF092444),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$_selectedDay de ${_monthNames[_monthIndex].toLowerCase()} de $_year',
                      style: const TextStyle(
                        color: Color(0xFF607086),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _navBtn(
                Icons.chevron_left_rounded,
                () => _changeAgendaWeek(-1),
              ),
              const SizedBox(width: 8),
              _navBtn(
                Icons.chevron_right_rounded,
                () => _changeAgendaWeek(1),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE4EAF2)),
            ),
            child: Row(
              children: _agendaWeek.map((date) {
                final active = DateUtils.isSameDay(date, selected);
                final current = DateUtils.isSameDay(date, today);
                final dateStatus = _agendaStatusForDate(date);
                return Expanded(
                  child: InkWell(
                    onTap: () => _selectAgendaDate(date),
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFF092F4F)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: current && !active
                            ? Border.all(color: const Color(0xFF39A900))
                            : null,
                      ),
                      child: Column(
                        children: [
                          Text(
                            dayNames[date.weekday % 7],
                            style: TextStyle(
                              color: active
                                  ? Colors.white70
                                  : const Color(0xFF607086),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              color: active
                                  ? Colors.white
                                  : const Color(0xFF092444),
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (dateStatus != null) ...[
                            const SizedBox(height: 4),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _statusColor(dateStatus),
                                shape: BoxShape.circle,
                                border: active
                                    ? Border.all(color: Colors.white, width: 1)
                                    : null,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE4EAF2)),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 7,
              children: [
                _legendDot(const Color(0xFF44C21E), 'Presente'),
                _legendDot(const Color(0xFFE53935), 'Inasistente'),
                _legendDot(const Color(0xFF1565C0), 'Justificado'),
                _legendDot(const Color(0xFFF6A900), 'Tarde'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            records.isEmpty
                ? 'Agenda del día'
                : '${records.length} ${records.length == 1 ? 'sesión' : 'sesiones'}',
            style: const TextStyle(
              color: Color(0xFF092444),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          if (records.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 34),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE4EAF2)),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.event_available_rounded,
                    color: Color(0xFF39A900),
                    size: 34,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'No hay sesiones registradas este día',
                    style: TextStyle(
                      color: Color(0xFF607086),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          else
            ...records.map(_buildAgendaRecord),
        ],
      ),
    );
  }

  // Se conserva como respaldo durante la transición a la agenda semanal.
  // ignore: unused_element
  Widget _buildHistorialTab() {
    if (_isLoadingCalendar) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF39A900)),
      );
    }

    if (_calendarError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 52,
                color: Color(0xFF607086),
              ),
              const SizedBox(height: 14),
              Text(
                _calendarError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF607086), fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchCalendar,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'Reintentar',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF44C21E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
    final bool canJustifySelected = _canShowJustifyButton(selStatus, selJust);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      child: Column(
        children: [
          // â”€â”€ Card calendario â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _card(
            child: Column(
              children: [
                // NavegaciÃ³n mes
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
                      .map(
                        (d) => Expanded(
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
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 10),

                // Grid de dÃ­as
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
                    if (index < firstWeekday ||
                        index >= firstWeekday + daysInMonth) {
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
                          if (justDay == 'PENDIENTE')
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _dot6(
                                  status != null
                                      ? _statusColor(status)
                                      : Colors.transparent,
                                ),
                                const SizedBox(width: 2),
                                _dot6(const Color(0xFFF6A900)),
                              ],
                            )
                          else
                            _dot6(
                              status != null
                                  ? _statusColor(status)
                                  : Colors.transparent,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // â”€â”€ Card detalle del dÃ­a â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                              const Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                selDetail != null
                                    ? "${selDetail['entrada']} - ${selDetail['salida']}"
                                    : "Sin registro de horario",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF607086),
                                ),
                              ),
                            ],
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
                      const Icon(
                        Icons.book_outlined,
                        size: 16,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Competencia: ',
                        style: TextStyle(
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

                if (selJust != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _justColor(selJust).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _justColor(selJust).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _justIcon(selJust),
                          size: 16,
                          color: _justColor(selJust),
                        ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Color(0xFF94A3B8),
                        ),
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

                if (canJustifySelected) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _goToJustificationsTab,
                      icon: const Icon(Icons.assignment_outlined, size: 18),
                      label: const Text('Justificar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF39A900),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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

          // â”€â”€ Leyenda â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                Wrap(
                  spacing: 14,
                  runSpacing: 10,
                  children: [
                    _legendDot(const Color(0xFF44C21E), 'Presente'),
                    _legendDot(const Color(0xFFE53935), 'Inasistente'),
                    _legendDot(const Color(0xFF1565C0), 'Justificado'),
                    _legendDot(const Color(0xFFF6A900), 'Tarde'),
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
  final int presente;
  final int ausente;
  final int retardado;
  final int justificado;
  final int total;

  _DonutChartPainter({
    required this.presente,
    required this.ausente,
    required this.retardado,
    required this.justificado,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) {
      return;
    }

    final double strokeWidth = size.width * 0.18;
    final Rect rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2 - strokeWidth / 2,
    );

    final List<Map<String, dynamic>> segments = [
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
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.presente != presente ||
        oldDelegate.ausente != ausente ||
        oldDelegate.retardado != retardado ||
        oldDelegate.justificado != justificado ||
        oldDelegate.total != total;
  }
}
