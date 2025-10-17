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
    if (!_formKey.currentState!.validate() || _questions.isEmpty) return;

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
              ..._questions.map((q) => ListTile(title: Text(q['questionText']))).toList(),
            ],
          ),
        ),
      ),
    );
  }
}


class QuizTakingScreen extends StatefulWidget {
  final String quizId;
  final String quizTitle;
  const QuizTakingScreen({super.key, required this.quizId, required this.quizTitle});

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _showResults = false;
  Map<int, int> _userAnswers = {};

  Widget _buildResultWidget(int totalQuestions) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Score', style: TextStyle(fontSize: 24, color: Colors.grey)),
          Text('$_score / $totalQuestions', style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizWidget(AsyncSnapshot<QuerySnapshot> snapshot) {
    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No questions.'));

    final questions = snapshot.data!.docs;
    final currentQuestion = questions[_currentQuestionIndex];
    final options = List<String>.from(currentQuestion['options']);

    void nextOrSubmit() {
      if (_currentQuestionIndex == questions.length - 1) {
        int finalScore = 0;
        for (int i = 0; i < questions.length; i++) {
          if (_userAnswers[i] == questions[i]['correctAnswerIndex']) {
            finalScore++;
          }
        }
        setState(() {
          _score = finalScore;
          _showResults = true;
        });
      } else {
        setState(() => _currentQuestionIndex++);
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('(${_currentQuestionIndex + 1}/${questions.length}) ${currentQuestion['questionText']}', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          ...List.generate(options.length, (index) {
            return Card(
              child: RadioListTile<int>(
                title: Text(options[index]),
                value: index,
                groupValue: _userAnswers[_currentQuestionIndex],
                onChanged: (value) => setState(() => _userAnswers[_currentQuestionIndex] = value!),
              ),
            );
          }),
          const Spacer(),
          ElevatedButton(
            onPressed: _userAnswers[_currentQuestionIndex] == null ? null : nextOrSubmit,
            child: Text(_currentQuestionIndex == questions.length - 1 ? 'Submit' : 'Next'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.quizTitle)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('quizzes').doc(widget.quizId).collection('questions').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          return _showResults
              ? _buildResultWidget(snapshot.data!.docs.length)
              : _buildQuizWidget(snapshot);
        },
      ),
    );
  }
}