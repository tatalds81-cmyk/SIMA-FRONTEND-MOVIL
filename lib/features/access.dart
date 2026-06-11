import 'package:flutter/material.dart';
import 'package:sima_movil_froned/features/attendance/attendance_page.dart';
import 'package:sima_movil_froned/features/attendance/qr_attendance_flow.dart';
import 'package:sima_movil_froned/features/home/dashboard_qr_flow.dart';
import 'package:sima_movil_froned/features/home/home_page.dart';
import 'package:sima_movil_froned/features/observatory/observatory_page.dart';
import 'package:sima_movil_froned/features/profile/profile_page.dart';
import 'package:sima_movil_froned/widgets/sima_bottom_nav_bar.dart';

class AccessPage extends StatefulWidget {
  const AccessPage({super.key});

  @override
  State<AccessPage> createState() => _AccessPageState();
}

class _AccessPageState extends State<AccessPage> {
  int _currentIndex = 0;
  int _attendanceRefreshTick = 0;
  bool _isQrFlowRunning = false;
  bool _hasActiveSession = false;
  bool _hasVerifiedSession = false;

  Future<void> _startQrFlow() async {
    if (_isQrFlowRunning) {
      return;
    }

    setState(() => _isQrFlowRunning = true);

    final isDashboardQr = _currentIndex == 0;

    try {
      final success = isDashboardQr
          ? await startDashboardQrFlow(context)
          : await startQrAttendanceFlow(context);

      if (!mounted) {
        return;
      }

      setState(() {
        if (success && isDashboardQr) {
          _hasActiveSession = true;
          _hasVerifiedSession = true;
        }
        if (success && !isDashboardQr) {
          _attendanceRefreshTick++;
        }
      });
    } finally {
      if (mounted) {
        setState(() => _isQrFlowRunning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        hasActiveSession: _hasActiveSession,
        hasVerifiedSession: _hasVerifiedSession,
      ),
      AttendancePage(key: ValueKey(_attendanceRefreshTick)),
      const ObservatoryPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      extendBody: true,
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
