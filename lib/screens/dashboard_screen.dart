import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';
import '../models/goal_model.dart'; // Eğer kullanılıyorsa kalsın, kullanılmıyorsa silinebilir

class DashboardScreen extends StatefulWidget {
  final Function(int) onNavigate;

  const DashboardScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  // Veriler
  int _totalDailyMinutes = 0; // EKSİK OLAN DEĞİŞKEN EKLENDİ
  int _totalWeeklyMinutes = 0; // Bu hafta toplam çalışılan
  int _dailyTarget = 120; // Varsayılan
  int _weeklyTarget = 840; // Varsayılan
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  // Verileri Firestore'dan çekip hesapla
  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user != null) {
        // 1. Genel Hedefleri Çek
        final generalGoals = await _firestoreService.getGeneralGoals(user.uid);

        // 2. Günlük toplam süreyi DOĞRUDAN servisten çek
        final dailyMinutes = await _firestoreService.getTodayTotalMinutes(user.uid);

        // 3. Haftalık toplam süreyi DOĞRUDAN servisten çek
        final weeklyMinutes = await _firestoreService.getThisWeekTotalMinutes(user.uid);

        if (mounted) {
          setState(() {
            if (generalGoals != null) {
              _dailyTarget = generalGoals.dailyTargetMinutes;
              _weeklyTarget = generalGoals.weeklyTargetMinutes;
            }
            _totalDailyMinutes = dailyMinutes; // Artık hata vermez
            _totalWeeklyMinutes = weeklyMinutes;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('Dashboard veri hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('StudyTrack'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. KÜÇÜLTÜLMÜŞ ÜST KISIM (HEADER)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white24,
                    radius: 24,
                    child: Text(
                      user?.displayName?.substring(0, 1).toUpperCase() ?? 'K',
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hos geldin,',
                        style: AppStyles.bodySmall.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        user?.displayName ?? 'Kullanici',
                        style: AppStyles.heading2.copyWith(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // 2. GÜNLÜK HEDEF KARTI
                  _buildSummaryCard(
                    title: 'Gunluk Hedef',
                    period: 'Bugun',
                    currentMinutes: _totalDailyMinutes, // DÜZELTİLDİ: Artık hesaplanan değer
                    targetMinutes: _dailyTarget,
                    icon: Icons.today,
                    color: AppColors.primary,
                  ),

                  const SizedBox(height: 16),

                  // 3. HAFTALIK HEDEF KARTI
                  _buildSummaryCard(
                    title: 'Haftalik Hedef',
                    period: 'Bu Hafta',
                    currentMinutes: _totalWeeklyMinutes,
                    targetMinutes: _weeklyTarget,
                    icon: Icons.calendar_view_week,
                    color: Colors.purple,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 4. HIZLI ERİŞİM (GRID)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hizli Erisim', style: AppStyles.heading3),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _buildQuickAccessButton(
                        icon: Icons.play_circle_filled,
                        label: 'Calismaya Basla',
                        color: AppColors.success,
                        onTap: () => widget.onNavigate(1),
                      ),
                      _buildQuickAccessButton(
                        icon: Icons.flag,
                        label: 'Hedeflerim',
                        color: AppColors.warning,
                        onTap: () => widget.onNavigate(2),
                      ),
                      _buildQuickAccessButton(
                        icon: Icons.bar_chart,
                        label: 'Istatistikler',
                        color: AppColors.info,
                        onTap: () => widget.onNavigate(3),
                      ),
                      _buildQuickAccessButton(
                        icon: Icons.person,
                        label: 'Profil',
                        color: Colors.grey,
                        onTap: () => widget.onNavigate(4),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Ortak Kart Tasarımı
  Widget _buildSummaryCard({
    required String title,
    required String period,
    required int currentMinutes,
    required int targetMinutes,
    required IconData icon,
    required Color color,
  }) {
    final double progress = (targetMinutes > 0)
        ? (currentMinutes / targetMinutes).clamp(0.0, 1.0)
        : 0.0;

    final int percentage = (progress * 100).toInt();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppStyles.heading3),
                        Text(
                          '$currentMinutes / $targetMinutes dk',
                          style: AppStyles.bodyMedium.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    period,
                    style: AppStyles.bodySmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey[100],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '%$percentage tamamlandi',
                style: AppStyles.bodySmall.copyWith(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}