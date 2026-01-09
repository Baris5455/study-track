import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/study_session_model.dart';
import '../../utils/constants.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  bool _isLoading = true;

  // Veriler
  List<StudySessionModel> _last7DaysSessions = [];
  Map<String, int> _dailyTotals = {};
  Map<String, int> _subjectTotals = {};
  int _dailyTarget = 120;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final sessions = await _firestoreService.getLast7DaysSessions(user.uid);
        final generalGoals = await _firestoreService.getGeneralGoals(user.uid);
        _processData(sessions);

        if (mounted) {
          setState(() {
            _last7DaysSessions = sessions;
            if (generalGoals != null) {
              _dailyTarget = generalGoals.dailyTargetMinutes;
            }
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Istatistikler yuklenemedi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Verileri grafik ve listeler için hazırla
  void _processData(List<StudySessionModel> sessions) {
    _dailyTotals.clear();
    _subjectTotals.clear();

    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = _formatDateKey(date);
      _dailyTotals[dateKey] = 0; // Başlangıçta 0 ata
    }

    // Oturumları döngüye al ve hesapla
    for (var session in sessions) {
      final dateKey = _formatDateKey(session.date);
      if (_dailyTotals.containsKey(dateKey)) {
        _dailyTotals[dateKey] = (_dailyTotals[dateKey] ?? 0) + session.durationMinutes;
      }
      _subjectTotals[session.subject] = (_subjectTotals[session.subject] ?? 0) + session.durationMinutes;
    }
  }

  String _formatDateKey(DateTime date) {
    return "${date.year}-${date.month}-${date.day}";
  }

  String _getDayName(DateTime date) {
    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return days[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Istatistikler'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _loadStats, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Son 7 Günlük Çalisma', style: AppStyles.heading3),
            const SizedBox(height: 12),
            _buildWeeklyChartCard(),

            const SizedBox(height: 24),

            Text('Günlük Hedef Analizi', style: AppStyles.heading3),
            const SizedBox(height: 12),
            _buildDailyGoalsList(),

            const SizedBox(height: 24),

            Text('Ders Bazlı Dagilim (Son 7 Gün)', style: AppStyles.heading3),
            const SizedBox(height: 12),
            _buildSubjectSummaryList(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // === WIDGET: GRAFİK ===
  Widget _buildWeeklyChartCard() {
    int maxMinutes = 1; // 0'a bölünmeyi önlemek için min 1
    _dailyTotals.forEach((_, minutes) {
      if (minutes > maxMinutes) maxMinutes = minutes;
    });

    final sortedKeys = _dailyTotals.keys.toList().reversed.toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              height: 180,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: sortedKeys.map((dateKey) {
                  // Key'den tarihi tekrar oluştur (gün ismini bulmak için)
                  final parts = dateKey.split('-');
                  final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));

                  final minutes = _dailyTotals[dateKey] ?? 0;
                  final double barHeight = (minutes / maxMinutes) * 120;
                  final isToday = _formatDateKey(DateTime.now()) == dateKey;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Dakika yazısı
                      Text(
                        minutes > 0 ? '$minutes' : '',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),

                      // Bar Çubuğu
                      Container(
                        width: 16,
                        height: barHeight > 0 ? barHeight : 4, // Minik bir nokta kalsın 0 ise
                        decoration: BoxDecoration(
                          color: isToday ? AppColors.primary : AppColors.primary.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Gün İsmi
                      Text(
                        _getDayName(date),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          color: isToday ? AppColors.primary : Colors.black87,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '* Dakika bazinda gösterilmektedir',
              style: AppStyles.bodySmall.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // === WIDGET: GÜNLÜK HEDEF LİSTESİ ===
  Widget _buildDailyGoalsList() {
    // Bugünden geriye doğru sıralı
    final sortedKeys = _dailyTotals.keys.toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sortedKeys.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final dateKey = sortedKeys[index];
          final parts = dateKey.split('-');
          final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));

          final minutes = _dailyTotals[dateKey] ?? 0;
          final double progress = (minutes / _dailyTarget).clamp(0.0, 1.0);
          final int percentage = (progress * 100).toInt();

          // Tarih formatı
          final dayName = _getDayName(date);
          final dayNumber = date.day;
          final isToday = index == 0;

          return ListTile(
            leading: Container(
              width: 50,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isToday ? AppColors.primary.withOpacity(0.1) : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$dayNumber', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(dayName, style: const TextStyle(fontSize: 10)),
                ],
              ),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isToday ? 'Bugün' : 'Gecmis'),
                Text('%$percentage', style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: percentage >= 100 ? AppColors.success : AppColors.primary,
                )),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percentage >= 100 ? AppColors.success : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text('$minutes / $_dailyTarget dk hedeflendi', style: const TextStyle(fontSize: 11)),
              ],
            ),
          );
        },
      ),
    );
  }

  // === WIDGET: DERS BAZLI ÖZET ===
  Widget _buildSubjectSummaryList() {
    if (_subjectTotals.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('Son 7 günde çalışma kaydı bulunamadı.')),
        ),
      );
    }

    final sortedSubjects = _subjectTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sortedSubjects.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final entry = sortedSubjects[index];
          final subject = entry.key;
          final minutes = entry.value;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: const Icon(Icons.book, color: AppColors.primary, size: 20),
            ),
            title: Text(subject, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$minutes dk',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}