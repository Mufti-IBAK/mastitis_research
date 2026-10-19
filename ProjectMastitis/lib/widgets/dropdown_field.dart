import 'package:flutter/material.dart';

class CustomDropdownField extends StatelessWidget {
  final String label;
  final List<String> options;
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool isRequired;

  const CustomDropdownField({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF64748B)),
      value: options.contains(value) ? value : null,
      items: options.map((opt) {
        return DropdownMenuItem(
          value: opt,
          child: Text(opt, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
        );
      }).toList(),
      onChanged: onChanged,
      validator: isRequired ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
    );
  }
}
