import 'package:cloud_firestore/cloud_firestore.dart';

class AlertModel {
  const AlertModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.recipientIds,
    required this.readBy,
    required this.scheduledAt,
    required this.createdAt,
    required this.examEndTime,
    this.examId = '',
    this.examTitle = '',
    this.subjectId = '',
    this.subject = '',
    this.titleKey = '',
    this.messageKey = '',
    this.messageArgs = const [],
  });

  final String id;
  final String title;
  final String message;
  final String type;
  final String titleKey;
  final String messageKey;
  final List<String> messageArgs;
  final List<String> recipientIds;
  final List<String> readBy;
  final DateTime scheduledAt;
  final DateTime createdAt;
  final DateTime examEndTime;
  final String examId;
  final String examTitle;
  final String subjectId;
  final String subject;

  bool get isExpired => DateTime.now().isAfter(examEndTime);

  bool isReadBy(String uid) => readBy.contains(uid);

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }

  static DateTime _dateWithFallback(dynamic value, DateTime fallback) {
    if (value is Timestamp) return value.toDate();
    return DateTime.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static List<String> _strings(dynamic value) {
    if (value is List) return value.map((item) => item.toString()).toList();
    return const [];
  }

  factory AlertModel.fromMap(Map<String, dynamic> map, String id) {
    return AlertModel(
      id: id,
      title: map['title']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      titleKey: map['titleKey']?.toString() ?? '',
      messageKey: map['messageKey']?.toString() ?? '',
      messageArgs: _strings(map['messageArgs']),
      recipientIds: _strings(map['recipientIds']),
      readBy: _strings(map['readBy']),
      scheduledAt: _date(map['scheduledAt']),
      createdAt: _date(map['createdAt']),
      examEndTime: _dateWithFallback(
        map['examEndTime'],
        DateTime.now().add(const Duration(days: 365)),
      ),
      examId: map['examId']?.toString() ?? '',
      examTitle: map['examTitle']?.toString() ?? '',
      subjectId: map['subjectId']?.toString() ?? '',
      subject: map['subject']?.toString() ?? '',
    );
  }
}
