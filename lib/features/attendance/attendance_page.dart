import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedMonth = 'Mayo 2024';
  String _selectedFilter = 'Todos';

  final List<Map<String, dynamic>> _mockData = [
    {
      'date': 'Lun, 20 mayo',
      'time': '07:58 a. m. - 12:02 p. m.',
      'status': 'Presente',
    },
    {
      'date': 'Vie, 17 mayo',
      'time': '07:55 a. m. - 12:05 p. m.',
      'status': 'Presente',
    },
    {
      'date': 'Jue, 16 mayo',
      'time': '08:00 a. m. - 12:00 p. m.',
      'status': 'Presente',
    },
    {
      'date': 'Mié, 15 mayo',
      'time': '07:50 a. m. - 12:03 p. m.',
      'status': 'Presente',
    },
    {
      'date': 'Mar, 14 mayo',
      'time': 'Sin registro',
      'status': 'Ausente',
    },
    {
      'date': 'Lun, 13 mayo',
      'time': '07:48 a. m. - 12:00 p. m.',
      'status': 'Presente',
    },
    {
      'date': 'Vie, 10 mayo',
      'time': 'Soporte enviado',
      'status': 'Justificada',
    },
    {
      'date': 'Jue, 09 mayo',
      'time': '07:59 a. m. - 12:01 p. m.',
      'status': 'Presente',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openScanner(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const ScannerScreen(),
    ));
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
                title: const Text('Presente'),
                onTap: () {
                  setState(() => _selectedFilter = 'Presente');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Ausente'),
                onTap: () {
                  setState(() => _selectedFilter = 'Ausente');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Justificada'),
                onTap: () {
                  setState(() => _selectedFilter = 'Justificada');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Tardanza'),
                onTap: () {
                  setState(() => _selectedFilter = 'Tardanza');
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
    switch (status.toLowerCase()) {
      case 'presente':
        return const Color(0xFF39A900);
      case 'ausente':
        return const Color(0xFFE53935);
      case 'tardanza':
      case 'justificada':
        return const Color(0xFFF6A900);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              onPressed: () => _openScanner(context),
              backgroundColor: const Color(0xFF39A900),
              elevation: 6,
              shape: const CircleBorder(),
              child: const Icon(
                Icons.qr_code_scanner,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Escanear QR',
              style: TextStyle(
                color: Color(0xFF39A900),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Principal ──
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

            // ── Banner Control de Asistencia (visible en todas las pestañas) ──
            _buildSessionBanner(),

            // TabBar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
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
                  Tab(text: 'Estadísticas'),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ── Tab 0: Resumen ──
                  _buildResumenTab(),

                  // ── Tab 1: Historial ──
                  _buildHistorialTab(),

                  // ── Tab 2: Justificar (vacío) ──
                  const Center(
                    child: Text(
                      'Justificar próximamente',
                      style: TextStyle(color: Color(0xFF607086), fontSize: 15),
                    ),
                  ),

                  // ── Tab 3: Estadísticas (vacío) ──
                  const Center(
                    child: Text(
                      'Estadísticas próximamente',
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

  // ─── Banner "Control de Asistencia de Aprendices" ───────────────────────
  Widget _buildSessionBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
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
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _bannerInlineText('Ficha: ', '235698'),
                      _bannerDivider(),
                      _bannerInlineText('Programa: ', 'ADSO'),
                      _bannerDivider(),
                      _bannerInlineText('Instructor lider: ', 'Franco'),
                      _bannerDivider(),
                      _bannerInlineText('Fecha: ', '27 de mayo de 2026'),
                      _bannerDivider(),
                      _bannerInlineText('Horario: ', 'Tarde'),
                      _bannerDivider(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Estado de sesion: ',
                            style: TextStyle(color: Color(0xFF607086), fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 4),
                          _sessionStatusChip(),
                        ],
                      ),
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

  Widget _sessionStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF39A900),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Activa',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ─── Tab Resumen con dona ────────────────────────────────────────────────
  Widget _buildResumenTab() {
    const int presente = 11;
    const int ausente = 2;
    const int retardado = 3;
    const int justificado = 0;
    const int total = presente + ausente + retardado + justificado;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen de asistencia',
              style: TextStyle(
                color: Color(0xFF092444),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
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
                height: 180,
                child: CustomPaint(
                  painter: _DonutChartPainter(
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
                          '${((presente / total) * 100).round()}%',
                          style: const TextStyle(
                            color: Color(0xFF092444),
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'Asistencias',
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
            const SizedBox(height: 28),
            // Leyendas
            _statRow('Asistencias', presente, total, const Color(0xFF39A900)),
            const SizedBox(height: 16),
            _statRow('Faltas', ausente, total, const Color(0xFFE53935)),
            const SizedBox(height: 16),
            _statRow('Retardos', retardado, total, const Color(0xFFF6A900)),
            const SizedBox(height: 16),
            _statRow('Faltas justificadas', justificado, total, const Color(0xFF1565C0)),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, int count, int total, Color color) {
    final double pct = total == 0 ? 0 : count / total;
    final int pctInt = (pct * 100).round();
    return Column(
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
    );
  }

  Widget _buildHistorialTab() {

    final filteredData = _selectedFilter == 'Todos'
        ? _mockData
        : _mockData.where((e) => e['status'] == _selectedFilter).toList();

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
                            : const Color(0xFF39A900).withOpacity(0.1),
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
          child: ListView.builder(
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
                      color: Colors.grey.withOpacity(0.05),
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
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item['status'] == 'Presente'
                            ? Icons.check_circle_outline
                            : item['status'] == 'Ausente'
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
                        color: statusColor.withOpacity(0.1),
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

// ─────────────────────────────────────────────
// Scanner Screen (sin cambios)
// ─────────────────────────────────────────────
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off:
                  case TorchState.unavailable:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                  case TorchState.auto:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, state, child) {
                switch (state.cameraDirection) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                  case CameraFacing.unknown:
                  case CameraFacing.external:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (_isProcessing) return;

              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final barcode = barcodes.first;
                if (barcode.rawValue != null) {
                  setState(() => _isProcessing = true);
                  controller.stop();

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: Row(
                        children: const [
                          Icon(Icons.check_circle,
                              color: Color(0xFF39A900), size: 30),
                          SizedBox(width: 10),
                          Text('Lectura Exitosa'),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Código detectado:'),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              barcode.rawValue!,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                          },
                          child: const Text('Aceptar',
                              style: TextStyle(color: Color(0xFF39A900))),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'Busque un código',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: const Color(0xFF39A900), width: 3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Text(
                    'Alinee el código QR dentro del marco',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
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

// ─── Donut Chart Painter ────────────────────────────────────────────────────
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
    final double strokeWidth = size.width * 0.18;
    final Rect rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2 - strokeWidth / 2,
    );

    final List<Map<String, dynamic>> segments = [
      {'value': presente, 'color': const Color(0xFF39A900)},
      {'value': ausente, 'color': const Color(0xFFE53935)},
      {'value': retardado, 'color': const Color(0xFFF6A900)},
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
