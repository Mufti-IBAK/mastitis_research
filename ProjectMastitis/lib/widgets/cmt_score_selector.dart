import 'package:flutter/material.dart';

class CmtScoreSelector extends StatelessWidget {
  final String? value;
  final ValueChanged<String> onChanged;

  const CmtScoreSelector({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scores = [
      {'code': 'N', 'label': 'N', 'name': 'Negative', 'bg': const Color(0xFFECFDF5), 'border': const Color(0xFFA7F3D0), 'text': const Color(0xFF15803D), 'active': const Color(0xFF10B981)},
      {'code': 'T', 'label': 'T', 'name': 'Trace', 'bg': const Color(0xFFFFFBEB), 'border': const Color(0xFFFDE68A), 'text': const Color(0xFFB45309), 'active': const Color(0xFFF59E0B)},
      {'code': '1', 'label': '1', 'name': 'Weak +', 'bg': const Color(0xFFFFF7ED), 'border': const Color(0xFFFED7AA), 'text': const Color(0xFFC2410C), 'active': const Color(0xFFEA580C)},
      {'code': '2', 'label': '2', 'name': 'Mod +', 'bg': const Color(0xFFFFF1F2), 'border': const Color(0xFFFECDD3), 'text': const Color(0xFFBE123C), 'active': const Color(0xFFE11D48)},
      {'code': '3', 'label': '3', 'name': 'Severe +', 'bg': const Color(0xFFFEF2F2), 'border': const Color(0xFFFCA5A5), 'text': const Color(0xFFB91C1C), 'active': const Color(0xFFDC2626)},
      {'code': 'Not done', 'label': 'ND', 'name': 'Not done', 'bg': const Color(0xFFF8FAFC), 'border': const Color(0xFFE2E8F0), 'text': const Color(0xFF64748B), 'active': const Color(0xFF64748B)},
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: scores.map((s) {
        final code = s['code'] as String;
        final label = s['label'] as String;
        final isSelected = value == code || (code == 'Not done' && value == 'ND');
        final bg = s['bg'] as Color;
        final border = s['border'] as Color;
        final textColor = s['text'] as Color;
        final activeColor = s['active'] as Color;

        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onChanged(code),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected ? activeColor : bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? activeColor : border,
                width: 1,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: activeColor.withValues(alpha: 0.25), blurRadius: 4, offset: const Offset(0, 1))]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : textColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
