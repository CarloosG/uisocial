import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatDetailPage extends StatefulWidget {
  const ChatDetailPage({Key? key}) : super(key: key);

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final supabase = Supabase.instance.client;
  final TextEditingController _messageController = TextEditingController();
  List<dynamic> _messages = [];
  late final String chatId;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    chatId = ModalRoute.of(context)!.settings.arguments as String;
    _loadMessages();
  }

Future<void> _loadMessages() async {
  try {
    final response = await supabase
        .from('messages')
        .select('*')
        .eq('event_id', chatId)
        .order('created_at', ascending: true);

    setState(() {
      _messages = response as List<dynamic>;
      _isLoading = false;
    });
  } catch (error) {
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error cargando mensajes: $error')),
    );
  }
}

Future<void> _sendMessage() async {
  final text = _messageController.text.trim();
  if (text.isEmpty) return;

  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return;

  try {
    await supabase.from('messages').insert({
      'event_id': chatId,
      'sender_id': userId,
      'content': text,
      'created_at': DateTime.now().toIso8601String(),
    });

    _messageController.clear();
    await _loadMessages();
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error enviando mensaje: $error')),
    );
  }
}


  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isMine =
                            message['user_id'] == supabase.auth.currentUser?.id;
                        return ListTile(
                          title: Align(
                            alignment:
                                isMine
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    isMine
                                        ? Colors.blue[200]
                                        : Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(message['content']),
                            ),
                          ),
                        );
                      },
                    ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
