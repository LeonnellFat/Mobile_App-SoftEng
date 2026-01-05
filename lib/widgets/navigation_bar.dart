import 'package:flutter/material.dart';
import '../config/theme.dart';

class AppNavigationBar extends StatelessWidget {
  final String activeTab;
  final Function(String) onTabChange;

  const AppNavigationBar({
    super.key,
    required this.activeTab,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      {
        'id': 'home',
        'label': 'Home',
        'icon': Icons.home_outlined,
        'activeIcon': Icons.home,
      },
      {
        'id': 'products',
        'label': 'Products',
        'icon': Icons.local_florist_outlined,
        'activeIcon': Icons.local_florist,
      },
      {
        'id': 'categories',
        'label': 'Categories',
        'icon': Icons.grid_view_outlined,
        'activeIcon': Icons.grid_view,
      },
      {
        'id': 'profile',
        'label': 'Profile',
        'icon': Icons.person_outline,
        'activeIcon': Icons.person,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.95 * 255).round()),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFFCE4EC).withAlpha((0.5 * 255).round()),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: tabs.map((tab) {
              final isActive = activeTab == tab['id'];
              final icon = isActive
                  ? tab['activeIcon'] as IconData
                  : tab['icon'] as IconData;

              return Expanded(
                child: _NavBarItem(
                  icon: icon,
                  label: tab['label'] as String,
                  isActive: isActive,
                  onTap: () => onTabChange(tab['id'] as String),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_NavBarItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            gradient: widget.isActive
                ? LinearGradient(
                    colors: [
                      AppTheme.primary.withAlpha((0.1 * 255).round()),
                      const Color(0xFFFCE4EC),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(AppTheme.radius2xl),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  if (widget.isActive)
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha((0.2 * 255).round()),
                        shape: BoxShape.circle,
                      ),
                    ),
                  Icon(
                    widget.icon,
                    size: 22,
                    color: widget.isActive
                        ? AppTheme.primary
                        : AppTheme.mutedForeground,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: widget.isActive
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: widget.isActive
                      ? AppTheme.primary
                      : AppTheme.mutedForeground,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.isActive)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
