// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:sima_movil_froned/features/attendance/attendance_page.dart';

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
  bool _hasActiveSession = false;
  bool _hasVerifiedSession = false;
  int _attendanceTabIndex = 0;
  int _observatoryTabIndex = 0;


  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        hasActiveSession: _hasActiveSession,
        hasVerifiedSession: _hasVerifiedSession,
        onNavigateToAttendance: (tabIndex) {
          setState(() {
            _currentIndex = 1;
            _attendanceTabIndex = tabIndex;
          });
        },
        onNavigateToObservatory: (tabIndex) {
          setState(() {
            _currentIndex = 2;
            _observatoryTabIndex = tabIndex;
          });
        },
      ),
      AttendancePage(
        key: ValueKey('attendance_${_attendanceRefreshTick}_$_attendanceTabIndex'),
        initialTabIndex: _attendanceTabIndex,
      ),
      ObservatoryPage(
        key: ValueKey('observatory_$_observatoryTabIndex'),
        initialTabIndex: _observatoryTabIndex,
      ),
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
