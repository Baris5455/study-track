import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hedeflerim'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag,
              size: 100,
              color: AppColors.warning,
            ),
            SizedBox(height: 16),
            Text(
              'Hedefler Ekrani',
              style: AppStyles.heading2,
            ),
            SizedBox(height: 8),
            Text(
              'Cok yakinda...',
              style: AppStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}