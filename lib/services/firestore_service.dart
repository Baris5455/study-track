import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/study_session_model.dart';
import '../models/goal_model.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // =============== STUDY SESSIONS (ÇALIŞMA OTURUMLARI) ===============

  // Çalışma oturumu ekleme
  Future<void> addStudySession({
    required String userId,
    required String subject,
    String? category,
    required int durationMinutes,
  }) async {
    try {
      final docRef = _firestore.collection('study_sessions').doc();

      final session = StudySessionModel(
        id: docRef.id,
        userId: userId,
        subject: subject,
        category: category,
        durationMinutes: durationMinutes,
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await docRef.set(session.toJson());
    } catch (e) {
      throw 'Calisma oturumu kaydedilemedi: $e';
    }
  }

  // Kullanıcının bugünkü çalışma oturumlarını getirme
  Future<List<StudySessionModel>> getTodayStudySessions(String userId) async {
    try {
      final now = DateTime.now();
      // Günün başlangıcı (00:00:00)
      final startOfDay = DateTime(now.year, now.month, now.day);
      // Günün bitişi (23:59:59)
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final querySnapshot = await _firestore
          .collection('study_sessions')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => StudySessionModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw 'Bugunun calisma kayitlari alinamadi: $e';
    }
  }

  // Kullanıcının bugünkü toplam çalışma süresini hesaplama
  Future<int> getTodayTotalMinutes(String userId) async {
    try {
      final sessions = await getTodayStudySessions(userId);
      // fold metodu tüm durationMinutes değerlerini toplar
      return sessions.fold<int>(0, (total, session) => total + session.durationMinutes);
    } catch (e) {
      print('Gunluk sure hesaplanamadi: $e');
      return 0;
    }
  }

  Future<int> getThisWeekTotalMinutes(String userId) async {
    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      final startDate = DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day);

      final querySnapshot = await _firestore
          .collection('study_sessions')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .get();

      final sessions = querySnapshot.docs
          .map((doc) => StudySessionModel.fromJson(doc.data()))
          .toList();

      return sessions.fold<int>(0, (total, session) => total + session.durationMinutes);
    } catch (e) {
      print('Haftalik sure hesaplanamadi: $e');
      return 0;
    }
  }

  // Kullanıcının belirli tarih aralığındaki çalışma oturumlarını getirme
  Future<List<StudySessionModel>> getStudySessionsByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('study_sessions')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => StudySessionModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw 'Calisma kayitlari alinamadi: $e';
    }
  }

  // Son 7 günün çalışma oturumlarını getirme
  Future<List<StudySessionModel>> getLast7DaysSessions(String userId) async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    return getStudySessionsByDateRange(
      userId: userId,
      startDate: sevenDaysAgo,
      endDate: now,
    );
  }

  // =============== GOALS (HEDEFLER) ===============

  // Ders bazlı hedef ekleme
  Future<void> addGoal({
    required String userId,
    required String subject,
    String? category,
    required int weeklyTargetMinutes,
  }) async {
    try {
      final docRef = _firestore.collection('goals').doc();

      final goal = GoalModel(
        id: docRef.id,
        userId: userId,
        subject: subject,
        category: category,
        weeklyTargetMinutes: weeklyTargetMinutes,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );

      await docRef.set(goal.toJson());
    } catch (e) {
      throw 'Hedef eklenemedi: $e';
    }
  }

  // Kullanıcının tüm hedeflerini getirme
  Future<List<GoalModel>> getUserGoals(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('goals')
          .where('userId', isEqualTo: userId)
          .orderBy('subject')
          .get();

      return querySnapshot.docs
          .map((doc) => GoalModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw 'Hedefler alinamadi: $e';
    }
  }

  // Hedef güncelleme
  Future<void> updateGoal({
    required String goalId,
    String? subject,
    String? category,
    int? weeklyTargetMinutes,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      };

      if (subject != null) updateData['subject'] = subject;
      if (category != null) updateData['category'] = category;
      if (weeklyTargetMinutes != null) updateData['weeklyTargetMinutes'] = weeklyTargetMinutes;

      await _firestore.collection('goals').doc(goalId).update(updateData);
    } catch (e) {
      throw 'Hedef guncellenemedi: $e';
    }
  }

  // Hedef silme
  Future<void> deleteGoal(String goalId) async {
    try {
      await _firestore.collection('goals').doc(goalId).delete();
    } catch (e) {
      throw 'Hedef silinemedi: $e';
    }
  }

  // Hedefin mevcut hafta ilerlemesini güncelleme
  Future<void> updateGoalProgress({
    required String goalId,
    required int minutesToAdd,
  }) async {
    try {
      final docRef = _firestore.collection('goals').doc(goalId);
      final doc = await docRef.get();

      if (doc.exists) {
        final goal = GoalModel.fromJson(doc.data()!);
        final newMinutes = goal.currentWeekMinutes + minutesToAdd;

        await docRef.update({
          'currentWeekMinutes': newMinutes,
          'lastUpdated': Timestamp.fromDate(DateTime.now()),
        });
      }
    } catch (e) {
      throw 'Hedef ilerlemesi guncellenemedi: $e';
    }
  }

  // Haftalık hedefleri sıfırlama (her hafta başında çağrılacak)
  Future<void> resetWeeklyGoals(String userId) async {
    try {
      final goals = await getUserGoals(userId);

      for (var goal in goals) {
        await _firestore.collection('goals').doc(goal.id).update({
          'currentWeekMinutes': 0,
          'lastUpdated': Timestamp.fromDate(DateTime.now()),
        });
      }
    } catch (e) {
      throw 'Haftalik hedefler sifirlanamadi: $e';
    }
  }

  // =============== GENERAL GOALS (GENEL HEDEFLER) ===============

  // Genel hedefleri kaydetme/güncelleme
  Future<void> setGeneralGoals({
    required String userId,
    required int dailyTargetMinutes,
    required int weeklyTargetMinutes,
  }) async {
    try {
      final generalGoal = GeneralGoalsModel(
        userId: userId,
        dailyTargetMinutes: dailyTargetMinutes,
        weeklyTargetMinutes: weeklyTargetMinutes,
        lastUpdated: DateTime.now(),
      );

      await _firestore
          .collection('general_goals')
          .doc(userId)
          .set(generalGoal.toJson());
    } catch (e) {
      throw 'Genel hedefler kaydedilemedi: $e';
    }
  }

  // Genel hedefleri getirme
  Future<GeneralGoalsModel> getGeneralGoals(String userId) async {
    try {
      final doc = await _firestore.collection('general_goals').doc(userId).get();

      if (doc.exists) {
        return GeneralGoalsModel.fromJson(doc.data()!);
      } else {
        // Varsayılan hedefler
        return GeneralGoalsModel(
          userId: userId,
          lastUpdated: DateTime.now(),
        );
      }
    } catch (e) {
      // Hata durumunda varsayılan döndür
      return GeneralGoalsModel(
        userId: userId,
        lastUpdated: DateTime.now(),
      );
    }
  }

  // =============== COMMUNITY (TOPLULUK) ===============

  // Paylaşım Ekleme
  Future<void> addPost({
    required String userId,
    required String userName,
    required String message,
  }) async {
    try {
      final docRef = _firestore.collection('posts').doc();

      final post = PostModel(
        id: docRef.id,
        userId: userId,
        userName: userName,
        message: message,
        createdAt: DateTime.now(),
        likes: [], // Boş liste ile başlatıyoruz
        imageUrl: null,
      );

      await docRef.set(post.toJson());
    } catch (e) {
      throw 'Paylasim gonderilemedi: $e';
    }
  }

  // Paylaşımları Getirme
  Future<List<PostModel>> getPosts() async {
    try {
      final querySnapshot = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return querySnapshot.docs
          .map((doc) => PostModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw 'Paylasimlar yuklenemedi: $e';
    }
  }

  Future<void> toggleLike(String postId, String userId) async {
    try {
      final docRef = _firestore.collection('posts').doc(postId);
      final doc = await docRef.get();

      if (doc.exists) {
        List<dynamic> currentLikes = doc.data()?['likes'] ?? [];

        if (currentLikes.contains(userId)) {
          await docRef.update({
            'likes': FieldValue.arrayRemove([userId])
          });
        } else {
          await docRef.update({
            'likes': FieldValue.arrayUnion([userId])
          });
        }
      }
    } catch (e) {
      throw 'Begeni islemi basarisiz: $e';
    }
  }

  Future<void> addComment(String postId, String userName, String message) async {
    try {
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .add({
        'userName': userName,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(), // Sunucu saati
      });
    } catch (e) {
      throw 'Yorum eklenemedi: $e';
    }
  }

  Stream<QuerySnapshot> getCommentsStream(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false) // Eskiden yeniye sırala
        .snapshots();
  }

  // =============== USER PROFILE ===============

  // Kullanıcı verisini tekil olarak çekme
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Kullanici verisi cekilemedi: $e');
      return null;
    }
  }

  // Kullanıcı bilgilerini güncelleme
  Future<void> updateUserProfile({
    required String userId,
    String? displayName,
    String? department,
    String? year,
    String? photoURL,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (displayName != null) updateData['displayName'] = displayName;
      if (department != null) updateData['department'] = department;
      if (year != null) updateData['year'] = year;
      if (photoURL != null) updateData['photoURL'] = photoURL;

      await _firestore.collection('users').doc(userId).update(updateData);
    } catch (e) {
      throw 'Profil guncellenemedi: $e';
    }
  }
}