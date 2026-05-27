import 'package:flutter/material.dart';

class TankLevelIndicator extends StatelessWidget {
  final double level; // 0.0 to 100.0

  const TankLevelIndicator({super.key, required this.level});

  Color get _color {
    if (level < 20) return const Color(0xFFEF4444);
    if (level < 50) return const Color(0xFFF59E0B);
    return const Color(0xFF3B82F6);
  }

  String get _status {
    if (level < 20) return 'Low';
    if (level < 50) return 'Medium';
    return 'Good';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.water_drop_rounded, color: _color, size: 18),
                  const SizedBox(width: 6),
                  const Text(
                    'Tank Level',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1F36),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${level.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _color,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: level / 100,
              minHeight: 12,
              backgroundColor: const Color(0xFFF4F6FA),
              valueColor: AlwaysStoppedAnimation<Color>(_color),
            ),
          ),
        ],
      ),
    );
  }
}
