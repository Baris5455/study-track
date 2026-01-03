import 'package:cloud_firestore/cloud_firestore.dart';

class StudySessionModel {
  final String id;
  final String userId;
  final String subject; // Ders adı
  final String? category; // Kategori (opsiyonel)
  final int durationMinutes;
  final DateTime date;
  final DateTime createdAt;

  StudySessionModel({
    required this.id,
    required this.userId,
    required this.subject,
    this.category,
    required this.durationMinutes,
    required this.date,
    required this.createdAt,
  });

  // Firestore'dan veri çekerken
  factory StudySessionModel.fromJson(Map<String, dynamic> json) {
    return StudySessionModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      subject: json['subject'] ?? '',
      category: json['category'],
      durationMinutes: json['durationMinutes'] ?? 0,
      date: (json['date'] as Timestamp).toDate(),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  // Firestore'a veri gönderirken
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'subject': subject,
      'category': category,
      'durationMinutes': durationMinutes,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}