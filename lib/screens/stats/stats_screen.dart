import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Istatistikler'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 100,
              color: AppColors.info,
            ),
            SizedBox(height: 16),
            Text(
              'Istatistikler Ekrani',
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