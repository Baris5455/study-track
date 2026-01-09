import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String userId;
  final String userName;
  final String message;
  final DateTime createdAt;
  final String? imageUrl;
  final List<String> likes;

  PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.message,
    required this.createdAt,
    this.imageUrl,
    required this.likes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'imageUrl': imageUrl,
      'likes': likes, // Listeyi kaydediyoruz
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
      // Firestore'dan gelen dynamic listeyi String listesine çeviriyoruz
      likes: List<String>.from(json['likes'] ?? []),
    );
  }
}