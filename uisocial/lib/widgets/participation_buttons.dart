import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uisocial/auth/auth_service.dart';

class ParticipationButtons extends StatefulWidget {
  final String eventId;

  const ParticipationButtons({super.key, required this.eventId});

  @override
  State<ParticipationButtons> createState() => _ParticipationButtonsState();
}

class _ParticipationButtonsState extends State<ParticipationButtons> {
  final SupabaseClient supabase = Supabase.instance.client;
  final authService = AuthService();
  String? _status;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadParticipationStatus();
  }

  Future<void> _loadParticipationStatus() async {
    final userId = authService.getCurrentUserId();
    if (userId == null) return;

    final response = await supabase
        .from('event_participation')
        .select('status')
        .eq('user_id', userId)
        .eq('event_id', widget.eventId)
        .maybeSingle();

    if (mounted) {
      setState(() {
        _status = response != null ? response['status'] as String : null;
        _loading = false;
      });
    }
  }

  Future<void> _respond(String responseStatus) async {
    final userId = authService.getCurrentUserId();
    if (userId == null) return;

    setState(() {
      _loading = true;
    });

    await supabase.from('event_participation').upsert({
      'user_id': userId,
      'event_id': widget.eventId,
      'status': responseStatus,
    });

    setState(() {
      _status = responseStatus;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_status != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          'Ya respondiste: ${_status!}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _status == 'aceptado' ? Colors.green : Colors.red,
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          icon: const Icon(Icons.check_circle, color: Colors.green),
          label: const Text("Aceptar"),
          onPressed: () => _respond('aceptado'),
        ),
        TextButton.icon(
          icon: const Icon(Icons.cancel, color: Colors.red),
          label: const Text("Rechazar"),
          onPressed: () => _respond('rechazado'),
        ),
      ],
    );
  }
}