import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zamanlayici'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timer,
              size: 100,
              color: AppColors.primary,
            ),
            SizedBox(height: 16),
            Text(
              'Zamanlayici Ekrani',
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