import 'package:flutter/material.dart';
import '../services/api_service.dart'; // adapte le chemin

class NotificationsScreen extends StatefulWidget {
  final String token;

  const NotificationsScreen({required this.token});

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends State<NotificationsScreen> {
  List notifications = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      final data =
          await ApiService.getNotifications(widget.token);

      setState(() {
        notifications = data;
        loading = false;
      });
    } catch (e) {
      print("Erreur: $e");
      setState(() => loading = false);
    }
  }

  int get unreadCount =>
      notifications.where((n) => n['read'] == false).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),

      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Notifications",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 8),

            /// 🔴 BADGE
            if (unreadCount > 0)
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "$unreadCount",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),

      body: loading
          ? Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? _emptyState()
              : ListView.separated(
                  padding: EdgeInsets.all(16),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) =>
                      SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    return _notificationCard(n);
                  },
                ),
    );
  }

  /// =========================
  /// 🔔 CARD DYNAMIQUE
  /// =========================
  Widget _notificationCard(Map<String, dynamic> n) {
    final iconData = _getIcon(n['type']);
    final color = _getColor(n['type']);

    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          )
        ],
      ),
      child: Row(
        children: [
          /// ICON
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, color: color, size: 22),
          ),

          SizedBox(width: 14),

          /// TEXT
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  n["title"],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  n["message"],
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          /// RIGHT SIDE
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              Text(
                _formatTime(n["created_at"]),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 6),

              /// 🔴 UNREAD DOT
              if (n["read"] == false)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                )
            ],
          )
        ],
      ),
    );
  }

  /// =========================
  /// ICON PAR TYPE
  /// =========================
  IconData _getIcon(String? type) {
    switch (type) {
      case 'appointment_created':
        return Icons.calendar_today;
      case 'appointment_confirmed':
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }

  /// =========================
  /// COULEUR PAR TYPE
  /// =========================
  Color _getColor(String? type) {
    switch (type) {
      case 'appointment_created':
        return Color(0xFF3B82F6);
      case 'appointment_confirmed':
        return Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  /// =========================
  /// FORMAT TEMPS SIMPLE
  /// =========================
  String _formatTime(String date) {
    final d = DateTime.parse(date);
    final now = DateTime.now();
    final diff = now.difference(d);

    if (diff.inMinutes < 1) return "Maintenant";
    if (diff.inMinutes < 60)
      return "Il y a ${diff.inMinutes} min";
    if (diff.inHours < 24)
      return "Il y a ${diff.inHours}h";

    return "${d.day}/${d.month}/${d.year}";
  }

  /// =========================
  /// EMPTY STATE
  /// =========================
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none,
              size: 60, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            "Aucune notification",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 5),
          Text(
            "Vous serez informé ici",
            style: TextStyle(color: Colors.grey),
          )
        ],
      ),
    );
  }
}