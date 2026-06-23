import 'package:flutter/material.dart';

class SimaBottomNavBar extends StatelessWidget {
  const SimaBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  static const _activeColor = Color(0xFF39A900);
  static const _inactiveColor = Color(0xFFB9C4D3);
  static const _navy = Color(0xFF062E4F);

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavBarItem(icon: Icons.home_rounded, label: 'Inicio'),
      _NavBarItem(
        icon: Icons.assignment_turned_in_outlined,
        label: 'Asistencia',
      ),
      _NavBarItem(icon: Icons.track_changes_rounded, label: 'Observaciones'),
      _NavBarItem(icon: Icons.person_outline_rounded, label: 'Perfil'),
    ];

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _navy,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: _navy.withValues(alpha: 0.26),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SizedBox(
          height: 64,
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
                        size: 24,
                      ),
                      const SizedBox(height: 4),
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
