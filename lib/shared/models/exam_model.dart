import 'package:cloud_firestore/cloud_firestore.dart';

class ExamModel {
  final String id;
  final String title;
  final String subject;
  final String subjectId;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final int duration; // in minutes
  final int totalQuestions;
  final String category;
  final bool isActive;
  final bool published;
  final String status;
  final bool shuffleQuestions;
  final bool antiCheatEnabled;
  final int notificationLeadMinutes;
  final String createdBy;
  final String teacherId;
  final DateTime createdAt;

  ExamModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.subjectId,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.totalQuestions,
    required this.category,
    required this.isActive,
    required this.published,
    required this.status,
    required this.shuffleQuestions,
    required this.antiCheatEnabled,
    required this.notificationLeadMinutes,
    required this.createdBy,
    required this.teacherId,
    required this.createdAt,
  });

  bool get isDone =>
      status == 'done' ||
      (published && !isActive && DateTime.now().isAfter(endTime));
  bool get isSending => status == 'sending';
  bool get isDraft => !published && !isSending && !isDone;
  bool get isPublished => published && !isDone;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subject': subject,
      'subjectId': subjectId,
      'description': description,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'duration': duration,
      'totalQuestions': totalQuestions,
      'category': category,
      'isActive': isActive,
      'published': published,
      'status': status,
      'shuffleQuestions': shuffleQuestions,
      'antiCheatEnabled': antiCheatEnabled,
      'notificationLeadMinutes': notificationLeadMinutes,
      'createdBy': createdBy,
      'teacherId': teacherId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static DateTime _readDate(dynamic value, DateTime fallback) {
    if (value is Timestamp) return value.toDate();
    if (value != null) {
      return DateTime.tryParse(value.toString()) ?? fallback;
    }
    return fallback;
  }

  factory ExamModel.fromMap(Map<String, dynamic> map, String docId) {
    final now = DateTime.now();
    final parsedCreatedAt = _readDate(map['createdAt'], now);
    final parsedStartTime = _readDate(map['startTime'], parsedCreatedAt);
    final duration = map['duration'] is int
        ? map['duration'] as int
        : int.tryParse(map['duration'].toString()) ?? 60;
    final parsedEndTime = _readDate(
      map['endTime'],
      parsedStartTime.add(Duration(minutes: duration)),
    );
    final subject = map['subject'] ?? map['category'] ?? 'Geral';
    final subjectId = map['subjectId'] ?? '';
    final teacherId = map['teacherId'] ?? map['createdBy'] ?? '';

    return ExamModel(
      id: docId,
      title: map['title'] ?? 'Teste Sem Titulo',
      subject: subject,
      subjectId: subjectId,
      description: map['description'] ?? 'La iha deskrisaun.',
      startTime: parsedStartTime,
      endTime: parsedEndTime,
      duration: duration,
      totalQuestions: map['totalQuestions'] is int
          ? map['totalQuestions'] as int
          : int.tryParse(map['totalQuestions'].toString()) ?? 0,
      category: map['category'] ?? subject,
      isActive: map['isActive'] ?? true,
      published: map['published'] == true,
      status: map['status']?.toString() ?? '',
      shuffleQuestions: map['shuffleQuestions'] ?? true,
      antiCheatEnabled: map['antiCheatEnabled'] ?? true,
      notificationLeadMinutes: map['notificationLeadMinutes'] is int
          ? map['notificationLeadMinutes'] as int
          : int.tryParse(map['notificationLeadMinutes']?.toString() ?? '') ??
                10,
      createdBy: map['createdBy'] ?? teacherId,
      teacherId: teacherId,
      createdAt: parsedCreatedAt,
    );
  }
}
