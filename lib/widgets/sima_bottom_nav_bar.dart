import 'package:flutter/material.dart';

class SimaBottomNavBar extends StatelessWidget {
  const SimaBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  static const _activeColor = Color(0xFF44C21E);
  static const _inactiveColor = Color(0xFF6E7B8D);

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavBarItem(icon: Icons.home_rounded, label: 'Inicio'),
      _NavBarItem(
        icon: Icons.assignment_turned_in_outlined,
        label: 'Asistencia',
      ),
      _NavBarItem(icon: Icons.track_changes_rounded, label: 'Observatorio'),
      _NavBarItem(icon: Icons.person_outline_rounded, label: 'Perfil'),
    ];

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = currentIndex == index;

              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: () => onItemSelected(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        color: isSelected ? _activeColor : _inactiveColor,
                        size: 23,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected ? _activeColor : _inactiveColor,
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem {
  const _NavBarItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
