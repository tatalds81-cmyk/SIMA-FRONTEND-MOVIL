import 'package:flutter/material.dart';
import 'package:sima_movil_froned/features/attendance/attendance_page.dart';
import 'package:sima_movil_froned/features/attendance/qr_attendance_flow.dart';
import 'package:sima_movil_froned/features/home/home_page.dart';
import 'package:sima_movil_froned/features/observatory/observatory_page.dart';
import 'package:sima_movil_froned/features/profile/profile_page.dart';
import 'package:sima_movil_froned/widgets/sima_bottom_nav_bar.dart';
import 'package:sima_movil_froned/theme/app_colors.dart';

class AccessPage extends StatefulWidget {
  const AccessPage({super.key});

  @override
  State<AccessPage> createState() => _AccessPageState();
}

class _AccessPageState extends State<AccessPage> {
  int _currentIndex = 0;
  int _attendanceRefreshTick = 0;
  bool _isQrFlowRunning = false;

  Future<void> _startQrFlow() async {
    if (_isQrFlowRunning) {
      return;
    }

    setState(() => _isQrFlowRunning = true);

    final success = await startQrAttendanceFlow(context);

    if (!mounted) {
      return;
    }

    setState(() {
      _isQrFlowRunning = false;
      if (success) {
        _attendanceRefreshTick++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomePage(),
      AttendancePage(key: ValueKey(_attendanceRefreshTick)),
      const ObservatoryPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      extendBody: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 78),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              heroTag: 'global_qr_attendance_button',
              onPressed: _isQrFlowRunning ? null : _startQrFlow,
              backgroundColor: AppColors.accentGreen,
              elevation: 6,
              shape: const CircleBorder(),
              child: _isQrFlowRunning
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Escanear QR',
              style: TextStyle(
                color: AppColors.accentGreen,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: SimaBottomNavBar(
        currentIndex: _currentIndex,
        onItemSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
