// lib/add_quiz_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddQuizScreen extends StatefulWidget {
  const AddQuizScreen({super.key});
  @override
  State<AddQuizScreen> createState() => _AddQuizScreenState();
}

class _AddQuizScreenState extends State<AddQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<Map<String, dynamic>> _questions = [];

  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate() || _questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one question.')),
      );
      return;
    }

    DocumentReference quizRef = await FirebaseFirestore.instance.collection('quizzes').add({
      'title': _titleController.text,
      'description': _descriptionController.text,
    });

    for (var q in _questions) {
      await quizRef.collection('questions').add(q);
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _addQuestion() {
    setState(() {
      _questions.add({
        'questionText': 'New Question ${_questions.length + 1}',
        'options': ['Option A', 'Option B', 'Option C', 'Option D'],
        'correctAnswerIndex': 0,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Quiz'), actions: [IconButton(icon: const Icon(Icons.save), onPressed: _saveQuiz)]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Quiz Title'), validator: (v) => v!.isEmpty ? 'Required' : null),
              TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description'), validator: (v) => v!.isEmpty ? 'Required' : null),
              const Divider(height: 40),
              FilledButton.tonal(onPressed: _addQuestion, child: const Text('Add Simple Question')),
              const SizedBox(height: 20),
              // แสดงรายการคำถามที่เพิ่มเข้ามา
              if (_questions.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _questions.length,
                  itemBuilder: (context, index) {
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text('${index + 1}')),
                        title: Text(_questions[index]['questionText']),
                      ),
                    );
                  },
                )
              else
                const Text('No questions added yet.'),
            ],
          ),
        ),
      ),
    );
  }
}