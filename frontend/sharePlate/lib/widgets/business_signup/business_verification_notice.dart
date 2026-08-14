import 'package:flutter/material.dart';

class BusinessVerificationNotice extends StatelessWidget {
  const BusinessVerificationNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: const Text(
        'Add one official document that verifies your business, such as a registration certificate, PAN card, or tax clearance. After verification, you can post surplus food for nearby organizations to claim.',
        style: TextStyle(
          fontSize: 13,
          height: 1.4,
          color: Color(0xFF8D6E63),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
