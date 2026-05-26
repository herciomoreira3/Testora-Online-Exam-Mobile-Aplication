import 'package:cloud_firestore/cloud_firestore.dart';

class ResultModel {
  final String id;
  final String userId;
  final String examId;
  final String examTitle; // Cached for history list UI rendering
  final int score;
  final double percentage;
  final int timeTaken; // in seconds
  final DateTime submittedAt;

  ResultModel({
    required this.id,
    required this.userId,
    required this.examId,
    required this.examTitle,
    required this.score,
    required this.percentage,
    required this.timeTaken,
    required this.submittedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'examId': examId,
      'examTitle': examTitle,
      'score': score,
      'percentage': percentage,
      'timeTaken': timeTaken,
      'submittedAt': Timestamp.fromDate(submittedAt),
    };
  }

  factory ResultModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parsedDate;
    if (map['submittedAt'] != null) {
      if (map['submittedAt'] is Timestamp) {
        parsedDate = (map['submittedAt'] as Timestamp).toDate();
      } else {
        parsedDate = DateTime.tryParse(map['submittedAt'].toString()) ?? DateTime.now();
      }
    } else {
      parsedDate = DateTime.now();
    }

    double parsedPercentage = 0.0;
    if (map['percentage'] != null) {
      parsedPercentage = double.tryParse(map['percentage'].toString()) ?? 0.0;
    }

    return ResultModel(
      id: docId,
      userId: map['userId'] ?? '',
      examId: map['examId'] ?? '',
      examTitle: map['examTitle'] ?? 'Teste Ujian',
      score: map['score'] is int
          ? map['score']
          : int.tryParse(map['score'].toString()) ?? 0,
      percentage: parsedPercentage,
      timeTaken: map['timeTaken'] is int
          ? map['timeTaken']
          : int.tryParse(map['timeTaken'].toString()) ?? 0,
      submittedAt: parsedDate,
    );
  }
}
