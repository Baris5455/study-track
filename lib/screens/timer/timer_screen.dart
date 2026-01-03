import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
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

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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

  // Çalışmayı bitirme - Dialog göster
  Future<void> _finishStudy() async {
    if (_seconds < 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('En az 1 dakika calismaniz gerekiyor!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });

    final minutes = (_seconds / 60).round();

    // Dialog göster
    final result = await showDialog<Map<String, String?>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SaveStudyDialog(totalMinutes: minutes),
    );

    if (result != null) {
      // Kaydet
      await _saveStudySession(
        subject: result['subject']!,
        category: result['category'],
        minutes: minutes,
      );
    }
  }

  // Firestore'a kaydetme
  Future<void> _saveStudySession({
    required String subject,
    String? category,
    required int minutes,
  }) async {
    try {
      // Loading göster
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Firestore'a kaydet
      final user = _authService.currentUser;
      if (user != null) {
        await _firestoreService.addStudySession(
          userId: user.uid,
          subject: subject,
          category: category,
          durationMinutes: minutes,
        );
      }

      // Loading kapat
      if (mounted) {
        Navigator.pop(context);
      }

      // Başarı mesajı
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$minutes dakika $subject calismasi kaydedildi!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Timer'ı sıfırla
      setState(() {
        _seconds = 0;
        _isRunning = false;
      });
    } catch (e) {
      // Loading kapat
      if (mounted) {
        Navigator.pop(context);
      }

      // Hata mesajı
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Manuel çalışma ekleme
  Future<void> _showManualAddDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _ManualAddDialog(),
    );

    if (result != null) {
      await _saveStudySession(
        subject: result['subject'] as String,
        category: result['category'] as String?,
        minutes: result['minutes'] as int,
      );
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
          // Manuel ekle butonu
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
                      Icon(
                        Icons.info_outline,
                        color: AppColors.info,
                      ),
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
                      // Circular timer
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
                                  fontFeatures: [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isRunning ? 'Calisiyor...' : 'Durakladi',
                                style: AppStyles.bodyMedium.copyWith(
                                  color: _isRunning
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Dakika gösterimi
                      if (_seconds >= 60)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
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
                  // Ana buton (Başlat/Duraklat)
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: _isRunning ? _pauseTimer : _startTimer,
                      icon: Icon(
                        _isRunning ? Icons.pause : Icons.play_arrow,
                        size: 28,
                      ),
                      label: Text(
                        _isRunning ? 'Duraklat' : 'Baslat',
                        style: const TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRunning
                            ? AppColors.warning
                            : AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Sıfırla ve Bitir butonları
                  Row(
                    children: [
                      // Sıfırla
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Bitir ve Kaydet
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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

// Çalışma bitince gösterilecek dialog
class _SaveStudyDialog extends StatefulWidget {
  final int totalMinutes;

  const _SaveStudyDialog({required this.totalMinutes});

  @override
  State<_SaveStudyDialog> createState() => _SaveStudyDialogState();
}

class _SaveStudyDialogState extends State<_SaveStudyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _categoryController = TextEditingController();

  @override
  void dispose() {
    _subjectController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final result = <String, String?>{
        'subject': _subjectController.text.trim(),
        'category': _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
      };
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Calisma Bilgileri'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${widget.totalMinutes} dakika calisma kaydedilecek',
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Ders adı
            TextFormField(
              controller: _subjectController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Ders Adi *',
                hintText: 'Ornek: Matematik',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ders adi gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Kategori (opsiyonel)
            TextFormField(
              controller: _categoryController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Kategori (Opsiyonel)',
                hintText: 'Ornek: Sinav Hazirligi',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 8),

            Text(
              '* Ders adi zorunludur',
              style: AppStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Iptal'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}

// Manuel çalışma ekleme dialog
class _ManualAddDialog extends StatefulWidget {
  const _ManualAddDialog();

  @override
  State<_ManualAddDialog> createState() => _ManualAddDialogState();
}

class _ManualAddDialogState extends State<_ManualAddDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _categoryController = TextEditingController();
  final _minutesController = TextEditingController();

  @override
  void dispose() {
    _subjectController.dispose();
    _categoryController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final result = {
        'subject': _subjectController.text.trim(),
        'category': _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
        'minutes': int.parse(_minutesController.text),
      };
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manuel Calisma Ekle'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ders adı
              TextFormField(
                controller: _subjectController,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Ders Adi *',
                  hintText: 'Ornek: Matematik',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.book),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ders adi gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Kategori (opsiyonel)
              TextFormField(
                controller: _categoryController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Kategori (Opsiyonel)',
                  hintText: 'Ornek: Sinav Hazirligi',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
              ),
              const SizedBox(height: 16),

              // Süre
              TextFormField(
                controller: _minutesController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'Sure (Dakika) *',
                  hintText: '60',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timer),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Sure gerekli';
                  }
                  final minutes = int.tryParse(value);
                  if (minutes == null || minutes <= 0) {
                    return 'Gecerli bir sure girin';
                  }
                  if (minutes > 1440) {
                    return 'Sure 1440 dakikadan fazla olamaz';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _save(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Iptal'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Ekle'),
        ),
      ],
    );
  }
}