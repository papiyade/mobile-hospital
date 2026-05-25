import 'package:flutter/material.dart';

class PrescriptionCardWidget extends StatelessWidget {
  final Map prescription;

  const PrescriptionCardWidget({super.key, required this.prescription});

  @override
  Widget build(BuildContext context) {
    final meds = prescription['medications'] ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Ordonnance",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            ...List.generate(meds.length, (i) {
              final m = meds[i];
              final pivot = m['pivot'] ?? {};

              return Text(
                "• ${m['name']} - ${pivot['dosage'] ?? '-'}",
              );
            }),
          ],
        ),
      ),
    );
  }
}