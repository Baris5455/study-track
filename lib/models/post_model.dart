import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String userId;
  final String userName; // Performans için ismi burada tutuyoruz
  final String message;
  final DateTime createdAt;

  // İleriye dönük opsiyonel alanlar (Şimdilik null veya 0)
  final String? imageUrl;
  final int likesCount;

  PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.message,
    required this.createdAt,
    this.imageUrl,
    this.likesCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'imageUrl': imageUrl,
      'likesCount': likesCount,
    };
  }

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Anonim',
      message: json['message'] ?? '',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      imageUrl: json['imageUrl'],
      likesCount: json['likesCount'] ?? 0,
    );
  }
}