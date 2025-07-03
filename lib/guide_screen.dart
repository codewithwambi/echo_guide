import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GuideScreen extends StatelessWidget {
  final String routeId; // e.g. "echo1"

  const GuideScreen({Key? key, required this.routeId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Echo Guide - Route')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('routes')
            .doc(routeId)
            .collection('steps')
            .orderBy('order') // Assuming you add an "order" field to steps
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading steps'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final steps = snapshot.data!.docs;

          return ListView.builder(
            itemCount: steps.length,
            itemBuilder: (context, index) {
              final step = steps[index];
              return ListTile(
                leading: Icon(Icons.navigation),
                title: Text(step['instruction']),
              );
            },
          );
        },
      ),
    );
  }
}
