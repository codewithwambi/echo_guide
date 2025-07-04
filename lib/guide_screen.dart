import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GuideScreen extends StatelessWidget {
  final String routeId; // e.g. "echo1"

  const GuideScreen({super.key, required this.routeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Echo Guide - Route')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('routes')
            .doc(routeId)
            .collection('steps')
            .orderBy('order') // Assuming you add an "order" field to steps
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading steps'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final steps = snapshot.data!.docs;

          return ListView.builder(
            itemCount: steps.length,
            itemBuilder: (context, index) {
              final step = steps[index];
              return ListTile(
                leading: const Icon(Icons.navigation),
                title: Text(step['instruction']),
              );
            },
          );
        },
      ),
    );
  }
}
