// lib/Components/radial_menu_button.dart
import 'package:flutter/material.dart';
import 'package:pomodoro/utilites/app_colors.dart';

class RadialMenuButton extends StatefulWidget {
  final bool isDarkMode;
  final Function(String label, int studyMin, int breakMin, Color color) onTimerSelected;
  final String selectedTimer;

  const RadialMenuButton({super.key, required this.isDarkMode, required this.onTimerSelected, required this.selectedTimer});

  @override
  State<RadialMenuButton> createState() => _RadialMenuButtonState();
}

class _RadialMenuButtonState extends State<RadialMenuButton> with TickerProviderStateMixin {
  late AnimationController _mainCtrl, _menuCtrl;
  bool _open = false;

  final List<Map<String, dynamic>> _items = [
    {'icon': Icons.timer, 'label': '90/20 Ultradian', 'subtitle': '90 min study · 20 min break', 'color': Colors.deepPurple, 'studyMin': 90, 'breakMin': 20},
    {'icon': Icons.timer, 'label': '52/17 Ratio', 'subtitle': '52 min study · 17 min break', 'color': Colors.blue, 'studyMin': 52, 'breakMin': 17},
    {'icon': Icons.timer, 'label': '30/5 Pomodoro', 'subtitle': '30 min study · 5 min break', 'color': Colors.orange, 'studyMin': 30, 'breakMin': 5},
    {'icon': Icons.timer, 'label': '25/5 Micro', 'subtitle': '25 min study · 5 min break', 'color': Colors.green, 'studyMin': 25, 'breakMin': 5},
  ];

  @override
  void initState() {
    super.initState();
    _mainCtrl = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _menuCtrl = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    Future.delayed(const Duration(milliseconds: 200), () { if (mounted) _mainCtrl.forward(); });
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _menuCtrl.dispose();
    super.dispose();
  }

  void _toggle() => setState(() { _open = !_open; _open ? _menuCtrl.forward() : _menuCtrl.reverse(); });

  @override
  Widget build(BuildContext context) {
    final spacing = 65.0;
    final fabSize = 56.0;
    return SizedBox(
      width: 220, height: fabSize + _items.length * spacing + 30,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ...List.generate(_items.length, (i) => Positioned(bottom: 70 + i * spacing, right: 0, child: _animItem(i))),
          Positioned(
            bottom: 0, right: 0,
            child: AnimatedBuilder(
              animation: _mainCtrl,
              builder: (_, child) => Transform.scale(
                scale: _mainCtrl.value,
                child: FloatingActionButton(
                  onPressed: _toggle,
                  backgroundColor: widget.isDarkMode ? AppColors.primaryDark : AppColors.primaryLight,
                  elevation: 8, shape: const CircleBorder(),
                  child: AnimatedRotation(duration: const Duration(milliseconds: 300), turns: _open ? 0.125 : 0, child: const Icon(Icons.add, color: Colors.white, size: 28)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _animItem(int i) {
    return AnimatedBuilder(
      animation: _menuCtrl,
      builder: (_, child) {
        final start = i * 0.2, end = start + 0.3;
        double scale, opacity;
        if (_menuCtrl.value < start) { scale = 0; opacity = 0; }
        else if (_menuCtrl.value > end) { scale = 1; opacity = 1; }
        else {
          final p = (_menuCtrl.value - start) / (end - start);
          scale = Curves.elasticOut.transform(p).clamp(0.0, 1.0);
          opacity = p.clamp(0.0, 1.0);
        }
        return Transform.scale(scale: scale, child: Opacity(opacity: opacity, child: _item(_items[i])));
      },
    );
  }

  Widget _item(Map<String, dynamic> item) {
    final sel = widget.selectedTimer == item['label'];
    final color = item['color'] as Color;
    return GestureDetector(
      onTap: () {
        setState(() { _open = false; _menuCtrl.reverse(); });
        widget.onTimerSelected(item['label'], item['studyMin'], item['breakMin'], color);
      },
      child: Container(
        height: 44, margin: const EdgeInsets.only(right: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? color : (widget.isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0)),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: sel ? color.withOpacity(0.5) : Colors.transparent, width: 1.5),
                boxShadow: [BoxShadow(color: color.withOpacity(sel ? 0.4 : 0.15), blurRadius: sel ? 12 : 6, offset: const Offset(0, 2))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                Text(item['label'], style: TextStyle(fontWeight: sel ? FontWeight.w800 : FontWeight.w600, fontSize: 10, color: sel ? Colors.white : (widget.isDarkMode ? Colors.white : Colors.black87)), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 1),
                Text(item['subtitle'], style: TextStyle(fontSize: 7, fontWeight: FontWeight.w500, color: sel ? Colors.white.withOpacity(0.85) : (widget.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600)), maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
            const SizedBox(width: 8),
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: sel ? color.withOpacity(0.15) : (widget.isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0)),
                shape: BoxShape.circle,
                border: Border.all(color: sel ? color : color.withOpacity(0.3), width: sel ? 2.5 : 2),
                boxShadow: [if (sel) BoxShadow(color: color.withOpacity(0.5), blurRadius: 10, spreadRadius: 1, offset: const Offset(0, 2))],
              ),
              child: Icon(item['icon'] as IconData, color: color, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}