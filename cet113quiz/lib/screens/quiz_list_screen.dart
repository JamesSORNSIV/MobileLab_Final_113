// lib/screens/quiz_list_screen.dart
import 'package:cet113quiz/screens/add_edit_quiz_screen.dart';
import 'package:cet113quiz/screens/auth_screen.dart';
import 'package:cet113quiz/screens/quiz_taking_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class QuizListScreen extends StatelessWidget {
  final bool isAdmin;
  const QuizListScreen({super.key, required this.isAdmin});

  // ⭐⭐⭐ --- START OF NEW CODE --- ⭐⭐⭐
  Future<void> _deleteQuiz(
      BuildContext context, String quizId, String quizTitle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete the quiz "$quizTitle"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final quizRef =
            FirebaseFirestore.instance.collection('quizzes').doc(quizId);
        final questionsSnapshot = await quizRef.collection('questions').get();

        WriteBatch batch = FirebaseFirestore.instance.batch();

        for (final doc in questionsSnapshot.docs) {
          batch.delete(doc.reference);
        }

        batch.delete(quizRef);

        await batch.commit();

        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"$quizTitle" deleted successfully.'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
         if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete quiz: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
  // ⭐⭐⭐ --- END OF NEW CODE --- ⭐⭐⭐

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Quizzes'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: isAdmin,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => logout(context),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search quizzes...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('quizzes')
                  .orderBy('title')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No quizzes found.'));
                }

                final quizzes = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: quizzes.length,
                  itemBuilder: (context, index) {
                    final quizDoc = quizzes[index];
                    final data = quizDoc.data() as Map<String, dynamic>;

                    final title = data['title'] as String? ?? 'No Title';
                    final count = data['questionCount'] as int? ?? 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        title: Text(title,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('$count questions · ${count * 1.5} min'),
                        // ⭐⭐⭐ --- START OF CHANGE --- ⭐⭐⭐
                        trailing: isAdmin
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blueGrey),
                                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                                      builder: (context) => AddEditQuizScreen(quizId: quizDoc.id),
                                    )),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red.shade400),
                                    onPressed: () => _deleteQuiz(context, quizDoc.id, title),
                                  ),
                                ],
                              )
                            : const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          if (!isAdmin) {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => QuizTakingScreen(
                                  quizId: quizDoc.id, quizTitle: title),
                            ));
                          }
                        },
                        // ⭐⭐⭐ --- END OF CHANGE --- ⭐⭐⭐
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const AddEditQuizScreen()));
              },
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              tooltip: 'Add Quiz',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}