import 'package:flutter/material.dart';

class ScoreSelector extends StatelessWidget {
  final String label;
  final int min;
  final int max;
  final int? value;
  final ValueChanged<int> onChanged;
  final bool useColors;

  const ScoreSelector({
    super.key,
    required this.label,
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
    this.useColors = false,
  });

  Color _getColor(int index) {
    if (!useColors) return const Color(0xFF0F766E);
    switch (index) {
      case 1:
        return const Color(0xFF10B981);
      case 2:
        return const Color(0xFFF59E0B);
      case 3:
        return const Color(0xFFF97316);
      case 4:
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF0F766E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<int> range = [for (var i = min; i <= max; i++) i];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: range.map((score) {
            final isSelected = value == score;
            final activeColor = _getColor(score);

            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onChanged(score),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 36,
                height: 34,
                decoration: BoxDecoration(
                  color: isSelected ? activeColor : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? activeColor : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: activeColor.withValues(alpha: 0.25), blurRadius: 4, offset: const Offset(0, 1))]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  score.toString(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
