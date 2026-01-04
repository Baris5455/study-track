import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/goal_model.dart';
import '../../utils/constants.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  // Timer değişkenleri
  int _seconds = 0;
  Timer? _timer;
  bool _isRunning = false;

  // Hedefler
  List<GoalModel> _goals = [];
  bool _goalsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  // Kullanıcının hedeflerini yükle
  Future<void> _loadGoals() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final goals = await _firestoreService.getUserGoals(user.uid);
        setState(() {
          _goals = goals;
          _goalsLoaded = true;
        });
      }
    } catch (e) {
      setState(() => _goalsLoaded = true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Zamanlayıcıyı başlatma
  void _startTimer() {
    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _seconds++;
      });
    });
  }

  // Zamanlayıcıyı duraklatma
  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  // Zamanlayıcıyı sıfırlama
  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _seconds = 0;
      _isRunning = false;
    });
  }

  // Çalışma bittiğinde çalışır
  Future<void> _finishStudy() async {
    if (_seconds < 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az 1 dakika...'), backgroundColor: Colors.orange),
      );
      return;
    }

    _pauseTimer();

    await _loadGoals();

    if (!mounted) return;

    final minutes = (_seconds / 60).round();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SelectGoalDialog(
        goals: _goals,
        totalMinutes: minutes,
      ),
    );

    if (result != null) {
      await _handleSaveOperation(
        subject: result['subject'],
        category: result['category'],
        minutes: minutes,
        goalId: result['goalId'],
      );
    }
  }

  // Manuel çalışma ekleme butonu
  Future<void> _showManualAddDialog() async {
    // ÇÖZÜM BURADA: Dialog açılmadan önce güncel listeyi çek
    await _loadGoals();

    if (!mounted) return; // Sayfa kapandıysa işlemi durdur

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ManualSelectGoalDialog(goals: _goals),
    );

    if (result != null) {
      await _handleSaveOperation(
        subject: result['subject'],
        category: result['category'],
        minutes: result['minutes'],
        goalId: result['goalId'],
      );
    }
  }

  // ORTAK KAYIT FONKSİYONU (Hem Timer bitince hem Manuel eklemede çalışır)
  Future<void> _handleSaveOperation({
    required String subject,
    String? category,
    required int minutes,
    String? goalId,
  }) async {
    try {
      // Loading göster
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final user = _authService.currentUser;
      if (user != null) {
        // 1. Çalışmayı kaydet
        await _firestoreService.addStudySession(
          userId: user.uid,
          subject: subject,
          category: category,
          durationMinutes: minutes,
        );

        // 2. Hedef varsa ilerlemeyi güncelle
        if (goalId != null) {
          await _firestoreService.updateGoalProgress(
            goalId: goalId,
            minutesToAdd: minutes,
          );
        }
      }

      // Loading kapat
      if (mounted) Navigator.pop(context);

      // Başarı mesajı
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$minutes dakika $subject calismasi kaydedildi!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Ekranı temizle ve hedefleri yenile
      setState(() {
        _seconds = 0;
        _isRunning = false;
      });
      _loadGoals();

    } catch (e) {
      // Hata durumunda loading kapat
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Süreyi formatla (HH:MM:SS)
  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Calisma Zamanlayicisi'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showManualAddDialog,
            tooltip: 'Manuel Ekle',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Bilgi kartı
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.info),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Calismaya baslayin, bitirince ders bilgilerini gireceksiniz.',
                          style: AppStyles.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Zamanlayıcı gösterimi
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _formatTime(_seconds),
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isRunning ? 'Calisiyor...' : 'Durakladi',
                                style: AppStyles.bodyMedium.copyWith(
                                  color: _isRunning ? AppColors.success : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      if (_seconds >= 60)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${(_seconds / 60).floor()} dakika',
                            style: AppStyles.bodyLarge.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Kontrol butonları
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: _isRunning ? _pauseTimer : _startTimer,
                      icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow, size: 28),
                      label: Text(
                        _isRunning ? 'Duraklat' : 'Baslat',
                        style: const TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRunning ? AppColors.warning : AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: _seconds > 0 ? _resetTimer : null,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Sifirla'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: const BorderSide(color: AppColors.danger),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _seconds >= 60 ? _finishStudy : null,
                            icon: const Icon(Icons.check),
                            label: const Text('Bitir'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============= DIALOG: TIMER SONRASI SEÇİM =============
class _SelectGoalDialog extends StatefulWidget {
  final List<GoalModel> goals;
  final int totalMinutes;

  const _SelectGoalDialog({required this.goals, required this.totalMinutes});

  @override
  State<_SelectGoalDialog> createState() => _SelectGoalDialogState();
}

class _SelectGoalDialogState extends State<_SelectGoalDialog> {
  String? _selectedGoalId;

  void _next() {
    if (_selectedGoalId != null) {
      final selectedGoal = widget.goals.firstWhere((g) => g.id == _selectedGoalId);
      Navigator.of(context).pop({
        'goalId': selectedGoal.id,
        'subject': selectedGoal.subject,
        'category': selectedGoal.category,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lutfen listeden bir ders secin!'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        children: [
          Text('Calisma Tamamlandi', style: AppStyles.heading3),
          const SizedBox(height: 4),
          Text(
            '${widget.totalMinutes} dakika',
            style: AppStyles.bodyLarge.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hangi ders icin calistin?', style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (widget.goals.isEmpty)
              _buildEmptyGoalsWarning()
            else
              ...widget.goals.map((goal) => _buildGoalRadioTile(goal)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Iptal')),
        ElevatedButton(onPressed: _next, child: const Text('Kaydet')),
      ],
    );
  }

  Widget _buildEmptyGoalsWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Henuz hedef eklemediniz. Once "Hedefler" sayfasindan ders eklemelisiniz.',
              style: TextStyle(fontSize: 12, color: Colors.orange[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalRadioTile(GoalModel goal) {
    final newProgress = goal.currentWeekMinutes + widget.totalMinutes;
    final newPercentage = (newProgress / goal.weeklyTargetMinutes * 100).clamp(0, 100);

    return RadioListTile<String>(
      value: goal.id,
      groupValue: _selectedGoalId,
      onChanged: (value) => setState(() => _selectedGoalId = value),
      title: Text(goal.subject),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (goal.category != null) Text(goal.category!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text('Hedef: ${goal.currentWeekMinutes}/${goal.weeklyTargetMinutes} dk', style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: newPercentage / 100,
                    minHeight: 6,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(newPercentage >= 100 ? Colors.green : Colors.blue),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('+${widget.totalMinutes}dk', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
        ],
      ),
      secondary: Icon(Icons.book, color: _selectedGoalId == goal.id ? AppColors.primary : Colors.grey),
    );
  }
}

// ============= DIALOG: MANUEL EKLEME =============
class _ManualSelectGoalDialog extends StatefulWidget {
  final List<GoalModel> goals;

  const _ManualSelectGoalDialog({required this.goals});

  @override
  State<_ManualSelectGoalDialog> createState() => _ManualSelectGoalDialogState();
}

class _ManualSelectGoalDialogState extends State<_ManualSelectGoalDialog> {
  String? _selectedGoalId;

  Future<void> _next() async {
    if (_selectedGoalId != null) {
      final selectedGoal = widget.goals.firstWhere((g) => g.id == _selectedGoalId);
      final minutes = await _showMinutesDialog();

      if (minutes != null && mounted) {
        Navigator.of(context).pop({
          'goalId': selectedGoal.id,
          'subject': selectedGoal.subject,
          'category': selectedGoal.category,
          'minutes': minutes,
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lutfen bir ders secin!'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<int?> _showMinutesDialog() async {
    final controller = TextEditingController();
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Calisma Suresi'),
        content: TextFormField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Sure (Dakika)',
            hintText: '60',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.timer),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Iptal')),
          ElevatedButton(
            onPressed: () {
              final minutes = int.tryParse(controller.text);
              if (minutes != null && minutes > 0 && minutes <= 1440) {
                Navigator.pop(context, minutes);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gecerli bir sure girin (1-1440)'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manuel Calisma Ekle'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hangi ders icin calistin?', style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (widget.goals.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700]),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Henuz hedef eklemediniz. Once hedef eklemelisiniz.', style: TextStyle(fontSize: 12, color: Colors.orange[700]))),
                  ],
                ),
              )
            else
              ...widget.goals.map((goal) => RadioListTile<String>(
                value: goal.id,
                groupValue: _selectedGoalId,
                onChanged: (value) => setState(() => _selectedGoalId = value),
                title: Text(goal.subject),
                subtitle: goal.category != null ? Text(goal.category!) : null,
                secondary: const Icon(Icons.book),
              )),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Iptal')),
        ElevatedButton(onPressed: _next, child: const Text('Devam')),
      ],
    );
  }
}