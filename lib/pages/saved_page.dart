import 'package:flutter/material.dart';

class SavedPage extends StatelessWidget {
  const SavedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'No tienes lugares guardados aún.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
