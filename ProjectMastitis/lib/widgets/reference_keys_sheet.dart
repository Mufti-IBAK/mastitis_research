import 'package:flutter/material.dart';

class ReferenceKeysSheet extends StatelessWidget {
  const ReferenceKeysSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Reference Guide', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Divider(),
          const Text('CMT Scores', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text('N (Negative): Liquid, homogeneous, no gel\n'
              'T (Trace): Slight, fleeting thickening\n'
              '1 (Weak Positive): Distinct thickening/gel\n'
              '2 (Distinct Positive): Immediate gel, moves to center\n'
              '3 (Strong Positive): Heavy, viscous gel, central peak'),
          const Divider(),
          const Text('Clinical Mastitis Grades', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text('Grade 1 (Mild): Changes in milk only\n'
              'Grade 2 (Moderate): Milk changes + local udder inflammation\n'
              'Grade 3 (Severe): Milk changes + local signs + systemic illness'),
          const Divider(),
          const Text('Udder Hygiene Scale', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text('1: Completely clean\n'
              '2: Slightly dirty (<2% soiled)\n'
              '3: Moderately dirty (2-30% soiled)\n'
              '4: Severely dirty (>30% covered)'),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
