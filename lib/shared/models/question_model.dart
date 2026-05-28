class QuestionModel {
  final String id;
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;
  final String? imageUrl;
  final String? imageData;
  final String? imageContentType;

  QuestionModel({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
    this.imageUrl,
    this.imageData,
    this.imageContentType,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionText': questionText,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
      if (imageData != null && imageData!.isNotEmpty) 'imageData': imageData,
      if (imageContentType != null && imageContentType!.isNotEmpty)
        'imageContentType': imageContentType,
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
      imageUrl: map['imageUrl']?.toString(),
      imageData: map['imageData']?.toString(),
      imageContentType: map['imageContentType']?.toString(),
    );
  }
}
