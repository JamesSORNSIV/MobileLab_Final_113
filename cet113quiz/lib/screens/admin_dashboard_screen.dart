import 'package:cet113quiz/screens/auth_screen.dart';
import 'package:cet113quiz/screens/quiz_list_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                _buildInfoCard(
                    'Users', FirebaseFirestore.instance.collection('users').snapshots()),
                const SizedBox(width: 16),
                _buildInfoCard('Quizzes',
                    FirebaseFirestore.instance.collection('quizzes').snapshots()),
              ],
            ),
            const SizedBox(height: 24),
            _buildNavCard(
              context,
              icon: Icons.quiz,
              title: 'Manage Quizzes',
              subtitle: 'Create, edit, delete',
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const QuizListScreen(isAdmin: true),
                ));
              },
            ),
            const SizedBox(height: 16),
            _buildNavCard(
              context,
              icon: Icons.bar_chart,
              title: 'View Statistics',
              subtitle: 'Scores and performance',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Statistics feature coming soon!')));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, Stream<QuerySnapshot> stream) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(title.toUpperCase(),
                  style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  return Text(
                    '${snapshot.data?.docs.length ?? 0}',
                    style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavCard(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Colors.indigo, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}