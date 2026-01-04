import 'package:cloud_firestore/cloud_firestore.dart';

class GoalModel {
  final String id;
  final String userId;
  final String subject; // Ders adı
  final String? category; // Kategori (opsiyonel)
  final int weeklyTargetMinutes; // Haftalık hedef dakika
  final int currentWeekMinutes; // Bu hafta yapılan toplam dakika
  final DateTime createdAt;
  final DateTime lastUpdated;

  GoalModel({
    required this.id,
    required this.userId,
    required this.subject,
    this.category,
    required this.weeklyTargetMinutes,
    this.currentWeekMinutes = 0,
    required this.createdAt,
    required this.lastUpdated,
  });

  // İlerleme yüzdesi hesaplama
  double get progressPercentage {
    if (weeklyTargetMinutes == 0) return 0;
    return (currentWeekMinutes / weeklyTargetMinutes * 100).clamp(0, 100);
  }

  // Kalan süre
  int get remainingMinutes {
    return (weeklyTargetMinutes - currentWeekMinutes).clamp(0, weeklyTargetMinutes);
  }

  // Hedef tamamlandı mı?
  bool get isCompleted => currentWeekMinutes >= weeklyTargetMinutes;

  // Firestore'dan veri çekerken
  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      subject: json['subject'] ?? '',
      category: json['category'],
      weeklyTargetMinutes: json['weeklyTargetMinutes'] ?? 0,
      currentWeekMinutes: json['currentWeekMinutes'] ?? 0,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      lastUpdated: (json['lastUpdated'] as Timestamp).toDate(),
    );
  }

  // Firestore'a veri gönderirken
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'subject': subject,
      'category': category,
      'weeklyTargetMinutes': weeklyTargetMinutes,
      'currentWeekMinutes': currentWeekMinutes,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  // Kopyalama (güncelleme için)
  GoalModel copyWith({
    String? subject,
    String? category,
    int? weeklyTargetMinutes,
    int? currentWeekMinutes,
    DateTime? lastUpdated,
  }) {
    return GoalModel(
      id: id,
      userId: userId,
      subject: subject ?? this.subject,
      category: category ?? this.category,
      weeklyTargetMinutes: weeklyTargetMinutes ?? this.weeklyTargetMinutes,
      currentWeekMinutes: currentWeekMinutes ?? this.currentWeekMinutes,
      createdAt: createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

// Kullanıcının genel hedefleri
class GeneralGoalsModel {
  final String userId;
  final int dailyTargetMinutes; // Günlük toplam hedef
  final int weeklyTargetMinutes; // Haftalık toplam hedef
  final DateTime lastUpdated;

  GeneralGoalsModel({
    required this.userId,
    this.dailyTargetMinutes = 120, // Varsayılan 120 dakika (2 saat)
    this.weeklyTargetMinutes = 840, // Varsayılan 840 dakika (14 saat)
    required this.lastUpdated,
  });

  factory GeneralGoalsModel.fromJson(Map<String, dynamic> json) {
    return GeneralGoalsModel(
      userId: json['userId'] ?? '',
      dailyTargetMinutes: json['dailyTargetMinutes'] ?? 120,
      weeklyTargetMinutes: json['weeklyTargetMinutes'] ?? 840,
      lastUpdated: (json['lastUpdated'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'dailyTargetMinutes': dailyTargetMinutes,
      'weeklyTargetMinutes': weeklyTargetMinutes,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  GeneralGoalsModel copyWith({
    int? dailyTargetMinutes,
    int? weeklyTargetMinutes,
    DateTime? lastUpdated,
  }) {
    return GeneralGoalsModel(
      userId: userId,
      dailyTargetMinutes: dailyTargetMinutes ?? this.dailyTargetMinutes,
      weeklyTargetMinutes: weeklyTargetMinutes ?? this.weeklyTargetMinutes,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}