import 'dart:io';
import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/widgets/custom_textfield.dart';
import '../../../shared/widgets/custom_button.dart';

import '../providers/professor_exam_provider.dart';
import '../providers/question_provider.dart';

class ManageQuestionsScreen extends ConsumerStatefulWidget {
  const ManageQuestionsScreen({super.key, required this.examId});
  final String examId;

  @override
  ConsumerState<ManageQuestionsScreen> createState() =>
      _ManageQuestionsScreenState();
}

class _ManageQuestionsScreenState extends ConsumerState<ManageQuestionsScreen> {
  bool _isAdding = false;
  bool _isSaving = false;
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  int _correctIndex = 0;
  XFile? _selectedImage;

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1100,
    );
    if (image == null || !mounted) return;
    setState(() => _selectedImage = image);
  }

  Future<String?> _uploadQuestionImage() async {
    final image = _selectedImage;
    if (image == null) return null;

    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
    final ref = FirebaseStorage.instance
        .ref()
        .child('exams')
        .child(widget.examId)
        .child('questions')
        .child(fileName);
    await ref.putFile(
      File(image.path),
      SettableMetadata(contentType: image.mimeType ?? 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }

  Future<Map<String, String>> _fallbackQuestionImageData() async {
    final image = _selectedImage;
    if (image == null) return const {};

    final bytes = await image.readAsBytes();
    if (bytes.length > 650 * 1024) {
      throw Exception(tr('image_too_large'));
    }
    return {
      'imageData': base64Encode(bytes),
      'imageContentType': image.mimeType ?? 'image/jpeg',
    };
  }

  Widget _questionImagePreview(String? imageUrl, String? imageData) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imageError(),
      );
    }
    if (imageData != null && imageData.isNotEmpty) {
      return Image.memory(
        base64Decode(imageData),
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imageError(),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _imageError() {
    return Container(
      height: 90,
      alignment: Alignment.center,
      color: const Color(0xFFF1F5F9),
      child: Text(tr('image_load_failed')),
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _addQuestion() async {
    final questionText = _questionController.text.trim();
    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((o) => o.isNotEmpty)
        .toList();
    if (questionText.isEmpty || options.length < 2) return;

    setState(() => _isSaving = true);
    try {
      String? imageUrl;
      Map<String, String> imageFallback = const {};
      if (_selectedImage != null) {
        try {
          imageUrl = await _uploadQuestionImage();
        } on FirebaseException {
          imageFallback = await _fallbackQuestionImageData();
        }
      }
      final data = {
        'questionText': questionText,
        'options': options,
        'correctAnswerIndex': _correctIndex,
        if (imageUrl != null) 'imageUrl': imageUrl,
        ...imageFallback,
        'point': 5,
        'points': 5,
        'createdAt': DateTime.now().toIso8601String(),
      };
      await ref
          .read(professorRepositoryProvider)
          .addQuestion(widget.examId, data);
      setState(() {
        _isAdding = false;
        _questionController.clear();
        for (var c in _optionControllers) {
          c.clear();
        }
        _correctIndex = 0;
        _selectedImage = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteQuestion(String qId) async {
    await ref
        .read(professorRepositoryProvider)
        .deleteQuestion(widget.examId, qId);
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(examQuestionsProvider(widget.examId));
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('manage_questions')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => setState(() => _isAdding = true),
          ),
        ],
      ),
      body: questionsAsync.when(
        data: (questions) {
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: questions.length,
            itemBuilder: (context, i) {
              final q = questions[i];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(q.questionText),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((q.imageUrl != null && q.imageUrl!.isNotEmpty) ||
                          (q.imageData != null && q.imageData!.isNotEmpty)) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _questionImagePreview(q.imageUrl, q.imageData),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Text(
                        '${tr('option_a')}: ${q.options.isNotEmpty ? q.options[0] : ''}\n${tr('option_b')}: ${q.options.length > 1 ? q.options[1] : ''}\n${tr('option_c')}: ${q.options.length > 2 ? q.options[2] : ''}\n${tr('option_d')}: ${q.options.length > 3 ? q.options[3] : ''}\n${tr('correct_option')}: ${q.correctAnswerIndex + 1}',
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteQuestion(q.id),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      // Add question overlay
      bottomSheet: _isAdding
          ? SafeArea(
              child: Material(
                elevation: 18,
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomTextField(
                        controller: _questionController,
                        labelText: tr('question_text'),
                      ),
                      const SizedBox(height: 8),
                      if (_selectedImage != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            File(_selectedImage!.path),
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () =>
                                setState(() => _selectedImage = null),
                            icon: const Icon(Icons.close),
                            label: Text(tr('remove_image')),
                          ),
                        ),
                      ] else
                        OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.image_outlined),
                          label: Text(tr('add_question_image')),
                        ),
                      ...List.generate(
                        4,
                        (idx) => CustomTextField(
                          controller: _optionControllers[idx],
                          labelText: '${tr('option_a')} ${idx + 1}',
                        ),
                      ),
                      DropdownButton<int>(
                        value: _correctIndex,
                        items: List.generate(
                          4,
                          (i) => DropdownMenuItem(
                            value: i,
                            child: Text('${tr('option_a')} ${i + 1}'),
                          ),
                        ),
                        onChanged: (v) =>
                            setState(() => _correctIndex = v ?? 0),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSaving
                                  ? null
                                  : () => setState(() {
                                      _isAdding = false;
                                      _selectedImage = null;
                                    }),
                              child: Text(tr('cancel')),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomButton(
                              text: tr('save'),
                              onPressed: _addQuestion,
                              isLoading: _isSaving,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
