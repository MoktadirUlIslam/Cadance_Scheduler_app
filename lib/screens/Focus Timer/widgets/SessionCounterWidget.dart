// lib/Components/session_counter_widget.dart
import 'package:flutter/material.dart';

class SessionCounterWidget extends StatefulWidget {
  final int initialValue;
  final Color accentColor;
  final Function(int) onChanged;

  const SessionCounterWidget({super.key, required this.initialValue, required this.accentColor, required this.onChanged});

  @override
  State<SessionCounterWidget> createState() => _SessionCounterWidgetState();
}

class _SessionCounterWidgetState extends State<SessionCounterWidget> with SingleTickerProviderStateMixin {
  late int _count;
  late AnimationController _bounce;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _count = widget.initialValue;
    _bounce = AnimationController(duration: const Duration(milliseconds: 250), vsync: this);
    _bounceAnim = Tween<double>(begin: 1.0, end: 1.15).animate(CurvedAnimation(parent: _bounce, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  void _change(int delta) {
    final n = _count + delta;
    if (n >= 1 && n <= 10) {
      setState(() => _count = n);
      _bounce.forward().then((_) => _bounce.reverse());
      widget.onChanged(_count);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _btn(Icons.remove, () => _change(-1), _count <= 1),
        const SizedBox(width: 20),
        AnimatedBuilder(
          animation: _bounceAnim,
          builder: (_, child) => Transform.scale(scale: _bounceAnim.value, child: Text('$_count', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: widget.accentColor))),
        ),
        const SizedBox(width: 20),
        _btn(Icons.add, () => _change(1), _count >= 10),
      ],
    );
  }

  Widget _btn(IconData icon, VoidCallback tap, bool disabled) {
    return GestureDetector(
      onTap: disabled ? null : tap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: disabled ? Colors.grey.withOpacity(0.15) : widget.accentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: disabled ? Colors.grey.withOpacity(0.3) : widget.accentColor.withOpacity(0.4)),
        ),
        child: Icon(icon, color: disabled ? Colors.grey : widget.accentColor, size: 22),
      ),
    );
  }
}