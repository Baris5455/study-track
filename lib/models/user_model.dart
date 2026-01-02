class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final String? department;
  final String? year;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    this.department,
    this.year,
    required this.createdAt,
  });

  // Firestore'dan veri çekerken kullanılır
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'],
      photoURL: json['photoURL'],
      department: json['department'],
      year: json['year'],
      createdAt: json['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  // Firestore'a veri gönderirken kullanılır
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'department': department,
      'year': year,
      'createdAt': createdAt,
    };
  }

  // Kullanıcı bilgilerini güncellemek için
  UserModel copyWith({
    String? displayName,
    String? photoURL,
    String? department,
    String? year,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      department: department ?? this.department,
      year: year ?? this.year,
      createdAt: createdAt,
    );
  }
}