import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({Key? key}) : super(key: key);

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  final supabase = Supabase.instance.client;
  List<dynamic> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        print('Usuario no autenticado');
        return;
      }

      final response = await supabase
          .from('event_participation')
          .select('event_id')
          .eq('user_id', userId)
          .eq('status', 'aceptado');

      print('Participaciones: $response');

      final eventIds =
          (response as List<dynamic>).map((e) => e['event_id']).toList();

      if (eventIds.isEmpty) {
        print('Sin eventos aceptados');
        return;
      }

      final chatResponse = await supabase
          .from('chats')
          .select('id, name, event_id') // incluir event_id
          .inFilter('event_id', eventIds);

      print('Chats encontrados: $chatResponse');

      setState(() {
        _chats = chatResponse as List<dynamic>;
        _isLoading = false;
      });
    } catch (error) {
      print('Error: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _chats.isEmpty
              ? const Center(child: Text('No hay chats disponibles'))
              : ListView.builder(
                itemCount: _chats.length,
                itemBuilder: (context, index) {
                  final chat = _chats[index];
                  final eventId = chat['event_id'] as String;

                  return ListTile(
                    title: Text(chat['name'] ?? 'Chat sin nombre'),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/chat_detail',
                        arguments: eventId,
                      );
                    },
                  );
                },
              ),
    );
  }
}
