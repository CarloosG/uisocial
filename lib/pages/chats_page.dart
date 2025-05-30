import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

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
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 1. Obtener eventos donde el usuario participa
      final participationResponse = await supabase
          .from('event_participation')
          .select('event_id')
          .eq('user_id', userId)
          .eq('status', 'aceptado');

      print('Participaciones: $participationResponse');

      final eventIds = (participationResponse as List<dynamic>)
          .map((e) => e['event_id'] as String)
          .toList();

      if (eventIds.isEmpty) {
        print('Sin eventos aceptados');
        setState(() {
          _chats = [];
          _isLoading = false;
        });
        return;
      }

      // 2. Para cada evento, verificar si existe un chat, si no, crearlo
      List<dynamic> chats = [];
      
      for (String eventId in eventIds) {
        // Verificar si ya existe un chat para este evento
        final existingChatResponse = await supabase
            .from('chats')
            .select('id, name, event_id')
            .eq('event_id', eventId)
            .maybeSingle();

        if (existingChatResponse != null) {
          // El chat ya existe
          chats.add(existingChatResponse);
        } else {
          // Crear un nuevo chat para este evento
          final eventResponse = await supabase
              .from('events')
              .select('name')
              .eq('id', eventId)
              .single();

          final eventName = eventResponse['name'] as String;
          
          final newChatResponse = await supabase
              .from('chats')
              .insert({
                'name': 'Chat: $eventName',
                'event_id': eventId,
              })
              .select('id, name, event_id')
              .single();

          chats.add(newChatResponse);

          // Agregar al usuario como participante del chat
          await supabase.from('chat_participants').insert({
            'chat_id': newChatResponse['id'],
            'user_id': userId,
          });
        }
      }

      print('Chats encontrados/creados: $chats');

      setState(() {
        _chats = chats;
        _isLoading = false;
      });
    } catch (error) {
      print('Error: $error');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando chats: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chats.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No hay chats disponibles',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Únete a un evento para acceder a su chat',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadChats,
                  child: ListView.builder(
                    itemCount: _chats.length,
                    itemBuilder: (context, index) {
                      final chat = _chats[index];
                      final chatId = chat['id'] as String;
                      final chatName = chat['name'] as String? ?? 'Chat sin nombre';

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.shade100,
                            child: Icon(
                              Icons.chat,
                              color: Colors.green.shade700,
                            ),
                          ),
                          title: Text(
                            chatName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text('Toca para abrir el chat'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/chat_detail',
                              arguments: chatId, // Pasar chat_id, no event_id
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}