class ExamModel {
  final String id;
  final String title;
  final String description;
  final int duration; // in minutes
  final int totalQuestions;
  final String category;
  final bool isActive;

  ExamModel({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.totalQuestions,
    required this.category,
    required this.isActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'duration': duration,
      'totalQuestions': totalQuestions,
      'category': category,
      'isActive': isActive,
    };
  }

  factory ExamModel.fromMap(Map<String, dynamic> map, String docId) {
    return ExamModel(
      id: docId,
      title: map['title'] ?? 'Teste Sem Título',
      description: map['description'] ?? 'La iha deskrisaun.',
      duration: map['duration'] is int
          ? map['duration']
          : int.tryParse(map['duration'].toString()) ?? 60,
      totalQuestions: map['totalQuestions'] is int
          ? map['totalQuestions']
          : int.tryParse(map['totalQuestions'].toString()) ?? 0,
      category: map['category'] ?? 'Geral',
      isActive: map['isActive'] ?? true,
    );
  }
}
