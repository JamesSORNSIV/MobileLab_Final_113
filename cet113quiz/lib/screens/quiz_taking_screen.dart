// lib/screens/quiz_taking_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class QuizTakingScreen extends StatefulWidget {
  final String quizId;
  final String quizTitle;
  const QuizTakingScreen(
      {super.key, required this.quizId, required this.quizTitle});

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _showResults = false;
  Map<int, int> _userAnswers = {};
  int? _selectedOption;

  // ⭐⭐⭐ --- START OF CHANGE --- ⭐⭐⭐
  Future<void> _submitAndSaveScore(List<QueryDocumentSnapshot> questions) async {
    int finalScore = 0;
    for (int i = 0; i < questions.length; i++) {
      final questionData = questions[i].data() as Map<String, dynamic>;
      final correctAnswer = questionData['correctAnswerIndex'] as int;
      if (_userAnswers[i] == correctAnswer) {
        finalScore++;
      }
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // เพิ่ม field 'userEmail': user.email เข้าไปที่นี่
      await FirebaseFirestore.instance.collection('quiz_results').add({
        'userId': user.uid,
        'userEmail': user.email, // <-- เพิ่มอีเมลของผู้ใช้
        'quizId': widget.quizId,
        'quizTitle': widget.quizTitle,
        'score': finalScore,
        'totalQuestions': questions.length,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to save score: $e');
    }

    if (mounted) {
      setState(() {
        _score = finalScore;
        _showResults = true;
      });
    }
  }
  // ⭐⭐⭐ --- END OF CHANGE --- ⭐⭐⭐

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('quizzes')
              .doc(widget.quizId)
              .collection('questions')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }
            if (snapshot.hasError) {
              return Center(
                  child: Text('Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white)));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                  child: Text('No questions found.',
                      style: TextStyle(color: Colors.white)));
            }

            final questions = snapshot.data!.docs;

            return _showResults
                ? _buildResultWidget(questions.length)
                : _buildQuizWidget(questions);
          },
        ),
      ),
    );
  }

  Widget _buildQuizWidget(List<QueryDocumentSnapshot> questions) {
    final currentQuestionDoc = questions[_currentQuestionIndex];
    final currentQuestion = currentQuestionDoc.data() as Map<String, dynamic>;
    final options = List<String>.from(currentQuestion['options']);

    void handleAnswer(int selectedIndex) {
      if (_userAnswers.containsKey(_currentQuestionIndex)) return;

      setState(() {
        _userAnswers[_currentQuestionIndex] = selectedIndex;
        _selectedOption = selectedIndex;
      });

      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        if (_currentQuestionIndex < questions.length - 1) {
          setState(() {
            _currentQuestionIndex++;
            _selectedOption = null;
          });
        } else {
          _submitAndSaveScore(questions);
        }
      });
    }

    Color getOptionColor(int index) {
      if (_selectedOption != null) {
        final correctAnswerIndex = currentQuestion['correctAnswerIndex'] as int;
        if (index == correctAnswerIndex) {
          return Colors.green;
        } else if (index == _selectedOption) {
          return Colors.red;
        }
      }
      return Colors.grey.shade300;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Text(
            'Quiz · ${_currentQuestionIndex + 1}/${questions.length}',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 18),
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentQuestion['questionText'] ?? 'Question not available',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: ListView.builder(
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        return _buildOptionTile(
                          text: options[index],
                          borderColor: getOptionColor(index),
                          onTap: () => handleAnswer(index),
                        );
                      }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionTile(
      {required String text,
      required Color borderColor,
      required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: borderColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(text, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildResultWidget(int totalQuestions) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your Result',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: Colors.grey.shade700)),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('$_score',
                    style: const TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo)),
                Text('/$totalQuestions',
                    style: const TextStyle(fontSize: 40, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to Quizzes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}