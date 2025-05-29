import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uisocial/models/notification_model.dart';
import 'package:uisocial/services/notification_service.dart';
import 'package:uisocial/widgets/custom_bottom_navigation.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:async';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final int _currentIndex = 3;
  late final NotificationService _notificationService;
  List<EventNotification> _notifications = [];
  bool _isLoading = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    final supabase = Supabase.instance.client;
    _notificationService = NotificationService(supabase);
    timeago.setLocaleMessages('es', timeago.EsMessages());
    timeago.setDefaultLocale('es');
    _loadNotifications();
    // Actualizar la vista cada minuto para mantener los tiempos relativos actualizados
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  String _getRelativeTime(DateTime dateTime) {
    // Convertir la fecha UTC a la zona horaria local
    final localDateTime = dateTime.toLocal();
    final now = DateTime.now();
    final difference = now.difference(localDateTime);

    if (difference.inMinutes < 1) {
      return 'hace un momento';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return 'hace $minutes ${minutes == 1 ? 'minuto' : 'minutos'}';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'hace $hours ${hours == 1 ? 'hora' : 'horas'}';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return 'hace $days ${days == 1 ? 'día' : 'días'}';
    } else {
      // Para fechas más antiguas, mostrar la fecha completa
      return DateFormat('dd/MM/yyyy HH:mm').format(localDateTime);
    }
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final notifications = await _notificationService.getNotifications(userId);
      setState(() {
        _notifications = notifications;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar notificaciones: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final unreadNotifications = _notifications.where((n) => !n.isRead).toList();
      if (unreadNotifications.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay notificaciones sin leer')),
        );
        return;
      }

      for (var notification in unreadNotifications) {
        await _notificationService.markAsRead(notification.id!);
      }

      await _loadNotifications();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todas las notificaciones han sido marcadas como leídas')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al marcar notificaciones como leídas: $e')),
      );
    }
  }

  Future<void> _deleteNotification(String id) async {
    try {
      await _notificationService.deleteNotification(id);
      await _loadNotifications();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notificación eliminada')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar notificación: $e')),
      );
    }
  }

  Future<void> _deleteAllNotifications() async {
    try {
      if (_notifications.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay notificaciones para eliminar')),
        );
        return;
      }

      // Mostrar diálogo de confirmación
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Eliminar todas las notificaciones'),
          content: const Text('¿Estás seguro de que quieres eliminar todas las notificaciones?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        for (var notification in _notifications) {
          await _notificationService.deleteNotification(notification.id!);
        }
        await _loadNotifications();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todas las notificaciones han sido eliminadas')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar notificaciones: $e')),
      );
    }
  }

  void _navigateToPage(int index) {
    if (index == _currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/search');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/eventos');
        break;
      case 3:
        // Ya estamos en la página de notificaciones
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  Future<void> _handleNotificationTap(EventNotification notification) async {
    if (!notification.isRead) {
      await _notificationService.markAsRead(notification.id!);
    }

    if (!mounted) return;

    switch (notification.type) {
      case 'event_created':
        if (notification.eventId != null) {
          Navigator.pushReplacementNamed(
            context,
            '/home',
            arguments: {'highlightedEventId': notification.eventId},
          );
        }
        break;
      
      case 'friend_request':
        Navigator.pushReplacementNamed(
          context,
          '/friends',
          arguments: {'initialTab': 1}, // 1 es el índice de la pestaña de solicitudes
        );
        break;
      
      case 'friend_accepted':
        Navigator.pushReplacementNamed(
          context,
          '/friends',
          arguments: {'initialTab': 0}, // 0 es el índice de la pestaña de amigos
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Marcar todas como leídas',
            onPressed: _markAllAsRead,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Eliminar todas',
            onPressed: _deleteAllNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: _notifications.isEmpty
                  ? const Center(child: Text('No tienes notificaciones'))
                  : ListView.builder(
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return Dismissible(
                          key: Key(notification.id!),
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16.0),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          direction: DismissDirection.endToStart,
                          onDismissed: (direction) {
                            _deleteNotification(notification.id!);
                          },
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: notification.isRead
                                  ? Colors.grey
                                  : Theme.of(context).primaryColor,
                              child: Icon(
                                _getNotificationIcon(notification.type),
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight:
                                    notification.isRead ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(notification.message),
                                const SizedBox(height: 4),
                                Text(
                                  _getRelativeTime(notification.createdAt),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _showDeleteConfirmation(notification),
                              tooltip: 'Eliminar notificación',
                            ),
                            onTap: () => _handleNotificationTap(notification),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
            ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _navigateToPage,
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'event_created':
        return Icons.event;
      case 'friend_request':
        return Icons.person_add;
      case 'friend_accepted':
        return Icons.people;
      default:
        return Icons.notifications;
    }
  }

  Future<void> _showDeleteConfirmation(EventNotification notification) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar notificación'),
        content: const Text('¿Estás seguro de que quieres eliminar esta notificación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteNotification(notification.id!);
    }
  }
} 