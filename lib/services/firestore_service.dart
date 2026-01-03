import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/study_session_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      final startOfDay = DateTime(now.year, now.month, now.day);
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
      return sessions.fold<int>(0, (total, session) => total + session.durationMinutes);
    } catch (e) {
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
}