import 'package:flutter/material.dart';

class YesNoSelector extends StatelessWidget {
  final String label;
  final bool includeUnknown;
  final String? value;
  final ValueChanged<String> onChanged;

  const YesNoSelector({
    super.key,
    required this.label,
    this.includeUnknown = false,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final options = ['Yes', 'No', if (includeUnknown) 'Unknown'];

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
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: options.map((opt) {
              final isSelected = value == opt;
              final shortLabel = opt == 'Unknown' ? 'Unk' : opt;

              return InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => onChanged(opt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: isSelected
                        ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 3, offset: const Offset(0, 1))]
                        : null,
                  ),
                  child: Text(
                    shortLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
