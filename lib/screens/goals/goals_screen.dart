import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/goal_model.dart';
import '../../utils/constants.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  List<GoalModel> _goals = [];
  GeneralGoalsModel? _generalGoals;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  // EKSİK OLAN FONKSİYON BURASIYDI, GERİ EKLENDİ:
  Future<void> _loadGoals() async {
    // Sadece ilk yüklemede loading göster, _handleOperation içinden çağrıldığında ekranı titretme
    if (_goals.isEmpty) {
      setState(() => _isLoading = true);
    }

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final goals = await _firestoreService.getUserGoals(user.uid);
        final generalGoals = await _firestoreService.getGeneralGoals(user.uid);

        if (mounted) {
          setState(() {
            _goals = goals;
            _generalGoals = generalGoals;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ORTAK İŞLEM YÖNETİCİSİ
  Future<void> _handleOperation(Future<void> Function() operation, String successMessage) async {
    try {
      // Loading dialog göster (İsteğe bağlı, işlem uzun sürerse kullanıcı anlasın)
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await operation(); // Verilen işlemi yap (Ekle/Sil/Güncelle)
      await _loadGoals(); // Listeyi yenile

      // Loading dialog'u kapat
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      // Hata olursa da loading'i kapat
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Yeni hedef ekleme
  Future<void> _showAddGoalDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _GoalFormDialog(),
    );

    if (result != null) {
      final user = _authService.currentUser;
      if (user != null) {
        await _handleOperation(() async {
          await _firestoreService.addGoal(
            userId: user.uid,
            subject: result['subject'],
            category: result['category'],
            weeklyTargetMinutes: result['weeklyTarget'],
          );
        }, 'Hedef eklendi!');
      }
    }
  }

  // Hedef düzenleme
  Future<void> _showEditGoalDialog(GoalModel goal) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _GoalFormDialog(goal: goal),
    );

    if (result != null) {
      await _handleOperation(() async {
        await _firestoreService.updateGoal(
          goalId: goal.id,
          subject: result['subject'],
          category: result['category'],
          weeklyTargetMinutes: result['weeklyTarget'],
        );
      }, 'Hedef guncellendi!');
    }
  }

  // Hedef silme
  Future<void> _deleteGoal(GoalModel goal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hedefi Sil'),
        content: Text('${goal.subject} hedefini silmek istiyor musunuz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Iptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _handleOperation(() async {
        await _firestoreService.deleteGoal(goal.id);
      }, 'Hedef silindi');
    }
  }

  // Genel hedefler
  Future<void> _showGeneralGoalsDialog() async {
    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => _GeneralGoalsDialog(generalGoals: _generalGoals),
    );

    if (result != null) {
      final user = _authService.currentUser;
      if (user != null) {
        await _handleOperation(() async {
          await _firestoreService.setGeneralGoals(
            userId: user.uid,
            dailyTargetMinutes: result['daily']!,
            weeklyTargetMinutes: result['weekly']!,
          );
        }, 'Genel hedefler guncellendi!');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hedeflerim'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showGeneralGoalsDialog,
            tooltip: 'Genel Hedefler',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadGoals,
        child: _goals.isEmpty
            ? _buildEmptyState()
            : _buildGoalsList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddGoalDialog,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Hedef'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.flag_outlined,
                size: 100,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                'Henuz hedef eklemediniz',
                style: AppStyles.heading3.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Ders bazli hedefler ekleyerek ilerlemenizi takip edin',
                style: AppStyles.bodyMedium.copyWith(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _showAddGoalDialog,
                icon: const Icon(Icons.add),
                label: const Text('Ilk Hedefinizi Ekleyin'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _goals.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildGeneralGoalsCard();
        }

        final goal = _goals[index - 1];
        return _buildGoalCard(goal);
      },
    );
  }

  Widget _buildGeneralGoalsCard() {
    if (_generalGoals == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: _showGeneralGoalsDialog,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.track_changes, color: AppColors.info, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Genel Hedefler', style: AppStyles.heading3),
                        Text(
                          'Gunluk ve haftalik hedefleriniz',
                          style: AppStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.edit, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTargetInfo(
                      'Gunluk',
                      _generalGoals!.dailyTargetMinutes,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTargetInfo(
                      'Haftalik',
                      _generalGoals!.weeklyTargetMinutes,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTargetInfo(String label, int minutes, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: AppStyles.bodySmall),
          const SizedBox(height: 4),
          Text(
            '${minutes} dk',
            style: AppStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(GoalModel goal) {
    final progress = goal.progressPercentage;
    final isCompleted = goal.isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showEditGoalDialog(goal),
        onLongPress: () => _deleteGoal(goal),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.subject,
                          style: AppStyles.heading3,
                        ),
                        if (goal.category != null)
                          Text(
                            goal.category!,
                            style: AppStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text(
                            'Tamamlandi',
                            style: AppStyles.bodySmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${goal.currentWeekMinutes} / ${goal.weeklyTargetMinutes} dk',
                    style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '%${progress.toInt()}',
                    style: AppStyles.bodyMedium.copyWith(
                      color: isCompleted ? AppColors.success : AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted ? AppColors.success : AppColors.primary,
                  ),
                ),
              ),
              if (goal.remainingMinutes > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${goal.remainingMinutes} dakika kaldi',
                    style: AppStyles.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============= DIALOG SINIFLARI =============

class _GoalFormDialog extends StatefulWidget {
  final GoalModel? goal;

  const _GoalFormDialog({this.goal});

  @override
  State<_GoalFormDialog> createState() => _GoalFormDialogState();
}

class _GoalFormDialogState extends State<_GoalFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _subjectController;
  late TextEditingController _categoryController;
  late TextEditingController _weeklyTargetController;

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(text: widget.goal?.subject ?? '');
    _categoryController = TextEditingController(text: widget.goal?.category ?? '');
    _weeklyTargetController = TextEditingController(
      text: widget.goal?.weeklyTargetMinutes.toString() ?? '300',
    );
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _categoryController.dispose();
    _weeklyTargetController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final result = <String, dynamic>{
        'subject': _subjectController.text.trim(),
        'category': _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
        'weeklyTarget': int.parse(_weeklyTargetController.text),
      };
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.goal != null;

    return AlertDialog(
      title: Text(isEditing ? 'Hedef Duzenle' : 'Yeni Hedef Ekle'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isEditing) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.green[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bu hafta: ${widget.goal!.currentWeekMinutes} dakika',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _subjectController,
                autofocus: !isEditing,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Ders Adi *',
                  hintText: 'Ornek: Matematik',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.book),
                ),
                validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'Ders adi gerekli' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Kategori (Opsiyonel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weeklyTargetController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Haftalik Hedef (Dakika) *',
                  hintText: '300',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timer),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Gerekli';
                  final m = int.tryParse(value);
                  if (m == null || m <= 0) return 'Gecersiz sure';
                  if (m > 10080) return 'Cok yuksek sure';
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
          child: Text(isEditing ? 'Guncelle' : 'Ekle'),
        ),
      ],
    );
  }
}

class _GeneralGoalsDialog extends StatefulWidget {
  final GeneralGoalsModel? generalGoals;

  const _GeneralGoalsDialog({this.generalGoals});

  @override
  State<_GeneralGoalsDialog> createState() => _GeneralGoalsDialogState();
}

class _GeneralGoalsDialogState extends State<_GeneralGoalsDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _dailyController;
  late TextEditingController _weeklyController;

  @override
  void initState() {
    super.initState();
    _dailyController = TextEditingController(
      text: (widget.generalGoals?.dailyTargetMinutes ?? 120).toString(),
    );
    _weeklyController = TextEditingController(
      text: (widget.generalGoals?.weeklyTargetMinutes ?? 840).toString(),
    );
  }

  @override
  void dispose() {
    _dailyController.dispose();
    _weeklyController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final result = <String, int>{
        'daily': int.parse(_dailyController.text),
        'weekly': int.parse(_weeklyController.text),
      };
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Genel Hedefler'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Toplam gunluk ve haftalik calisma hedefleriniz',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _dailyController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                labelText: 'Gunluk Hedef (Dakika)',
                hintText: '120',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.today),
                helperText: 'Ornek: 120 dk = 2 saat/gun',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Gunluk hedef gerekli';
                }
                final minutes = int.tryParse(value);
                if (minutes == null || minutes <= 0) {
                  return 'Gecerli bir sure girin';
                }
                if (minutes > 1440) {
                  return 'Gunluk hedef 1440 dakikadan fazla olamaz';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weeklyController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                labelText: 'Haftalik Hedef (Dakika)',
                hintText: '840',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
                helperText: 'Ornek: 840 dk = 14 saat/hafta',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Haftalik hedef gerekli';
                }
                final minutes = int.tryParse(value);
                if (minutes == null || minutes <= 0) {
                  return 'Gecerli bir sure girin';
                }
                if (minutes > 10080) {
                  return 'Haftalik hedef 10080 dakikadan fazla olamaz';
                }
                return null;
              },
              onFieldSubmitted: (_) => _save(),
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