import 'package:flutter/material.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _MsgTile(name: 'Support', message: 'Messages placeholder item'),
          SizedBox(height: 10),
          _MsgTile(name: 'System', message: 'This is just a UI placeholder'),
        ],
      ),
    );
  }
}

class _MsgTile extends StatelessWidget {
  const _MsgTile({required this.name, required this.message});
  final String name;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: Colors.black.withOpacity(0.03),
      leading: CircleAvatar(child: Text(name.characters.first)),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(message),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
