class QuestionModel {
  final String id;
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;

  QuestionModel({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionText': questionText,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
    };
  }

  factory QuestionModel.fromMap(Map<String, dynamic> map, String docId) {
    var rawOptions = map['options'] ?? [];
    List<String> parsedOptions = [];
    if (rawOptions is List) {
      parsedOptions = rawOptions.map((e) => e.toString()).toList();
    }

    return QuestionModel(
      id: docId,
      questionText: map['questionText'] ?? '',
      options: parsedOptions,
      correctAnswerIndex: map['correctAnswerIndex'] is int
          ? map['correctAnswerIndex']
          : int.tryParse(map['correctAnswerIndex'].toString()) ?? 0,
    );
  }
}
