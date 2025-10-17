// lib/screens/add_edit_quiz_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class QuestionEditorController {
  final TextEditingController questionController = TextEditingController();
  final List<TextEditingController> optionControllers =
      List.generate(4, (_) => TextEditingController());
  int correctAnswerIndex = 0;

  void dispose() {
    questionController.dispose();
    for (var controller in optionControllers) {
      controller.dispose();
    }
  }
}

class AddEditQuizScreen extends StatefulWidget {
  final String? quizId; // รับ ID ของ Quiz, ถ้าเป็น null หมายถึงสร้างใหม่
  const AddEditQuizScreen({super.key, this.quizId});

  @override
  State<AddEditQuizScreen> createState() => _AddEditQuizScreenState();
}

class _AddEditQuizScreenState extends State<AddEditQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<QuestionEditorController> _questionControllers = [];
  bool _isLoading = false;
  String _appBarTitle = 'Add Quiz';

  @override
  void initState() {
    super.initState();
    if (widget.quizId != null) {
      _appBarTitle = 'Edit Quiz';
      _loadQuizData();
    }
  }

  Future<void> _loadQuizData() async {
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(widget.quizId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _titleController.text = data['title'];
        _descriptionController.text = data['description'];

        final questionsSnapshot = await doc.reference.collection('questions').get();
        for (final qDoc in questionsSnapshot.docs) {
          final qData = qDoc.data();
          final controller = QuestionEditorController();
          controller.questionController.text = qData['questionText'];
          controller.correctAnswerIndex = qData['correctAnswerIndex'];
          for (int i = 0; i < 4; i++) {
            controller.optionControllers[i].text = qData['options'][i];
          }
          _questionControllers.add(controller);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to load quiz: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (var controller in _questionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate()) return;
    if (_questionControllers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one question.')));
      return;
    }

    List<Map<String, dynamic>> questionsToSave = [];
    for (var qController in _questionControllers) {
      if (qController.questionController.text.trim().isEmpty ||
          qController.optionControllers.any((c) => c.text.trim().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please fill all question and option fields.')));
        return;
      }
      questionsToSave.add({
        'questionText': qController.questionController.text.trim(),
        'options': qController.optionControllers.map((c) => c.text.trim()).toList(),
        'correctAnswerIndex': qController.correctAnswerIndex,
      });
    }

    setState(() => _isLoading = true);
    try {
      if (widget.quizId == null) {
        // --- โหมดสร้างใหม่ (ADD) ---
        DocumentReference quizRef =
            await FirebaseFirestore.instance.collection('quizzes').add({
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'questionCount': questionsToSave.length,
        });

        for (final questionData in questionsToSave) {
          await quizRef.collection('questions').add(questionData);
        }
      } else {
        // --- โหมดแก้ไข (EDIT) ---
        final quizRef =
            FirebaseFirestore.instance.collection('quizzes').doc(widget.quizId);
        
        WriteBatch batch = FirebaseFirestore.instance.batch();

        batch.update(quizRef, {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'questionCount': questionsToSave.length,
        });

        final oldQuestions = await quizRef.collection('questions').get();
        for (final doc in oldQuestions.docs) {
          batch.delete(doc.reference);
        }

        for (final questionData in questionsToSave) {
          batch.set(quizRef.collection('questions').doc(), questionData);
        }
        
        await batch.commit();
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to save quiz: $e')));
      }
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  void _addQuestion() {
    setState(() {
      _questionControllers.add(QuestionEditorController());
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questionControllers[index].dispose();
      _questionControllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(_appBarTitle),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Quiz',
            onPressed: _saveQuiz,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              TextFormField(
                                  controller: _titleController,
                                  decoration:
                                      const InputDecoration(labelText: 'Title'),
                                  validator: (v) =>
                                      v!.isEmpty ? 'Required' : null),
                              const SizedBox(height: 16),
                              TextFormField(
                                  controller: _descriptionController,
                                  decoration: const InputDecoration(
                                      labelText: 'Description'),
                                  validator: (v) =>
                                      v!.isEmpty ? 'Required' : null),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Questions",
                                  style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 10),
                              if (_questionControllers.isEmpty)
                                const Center(
                                    child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                      "Press the '+' button to add questions."),
                                ))
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _questionControllers.length,
                                  itemBuilder: (context, index) {
                                    return _buildQuestionCard(index);
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addQuestion,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        tooltip: 'Add Question',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildQuestionCard(int index) {
    final controller = _questionControllers[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Question ${index + 1}',
                  style: Theme.of(context).textTheme.titleMedium),
              IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                  onPressed: () => _removeQuestion(index)),
            ],
          ),
          TextFormField(
              controller: controller.questionController,
              decoration: const InputDecoration(labelText: 'Question Text')),
          ...List.generate(4, (optionIndex) {
            return Row(
              children: [
                Radio<int>(
                    value: optionIndex,
                    groupValue: controller.correctAnswerIndex,
                    onChanged: (v) =>
                        setState(() => controller.correctAnswerIndex = v!)),
                Expanded(
                    child: TextFormField(
                        controller: controller.optionControllers[optionIndex],
                        decoration: InputDecoration(
                            labelText: 'Option ${'ABCD'[optionIndex]}'))),
              ],
            );
          }),
          if (index < _questionControllers.length - 1)
            const Divider(height: 30, thickness: 0.5),
        ],
      ),
    );
  }
}