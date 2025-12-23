import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  final String itineraryId;
  final String itineraryTitle;

  const NotificationsScreen({
    Key? key,
    required this.itineraryId,
    required this.itineraryTitle,
  }) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> notifications = [];
  List<dynamic> travelers = [];
  bool _isSending = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRealTravelers();
  }

  // 🔥 FIXED: Backend field names दोनों handle करता है
  Future<void> _loadRealTravelers() async {
    setState(() => _isLoading = true);
    try {
      print('🔄 Loading travelers for: ${widget.itineraryId}');
      final res = await ApiService.getItinerary(widget.itineraryId);

      if (res['status'] == true) {
        final data = res['data'] ?? {};
        // ✅ BOTH field names handle करता है
        travelers = data['travelers'] ?? data['travellers'] ?? [];

        // 🔥 DEBUG PRINT - Console check करो
        print('✅ FULL TRAVELERS DATA: $travelers');
        print('✅ Traveler count: ${travelers.length}');

        setState(() => _isLoading = false);
        _generateNotificationsForRealTravelers();
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'No travelers found')),
        );
      }
    } catch (e) {
      print('❌ API Error: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    }
  }

  void _generateNotificationsForRealTravelers() {
    notifications.clear();

    for (var traveler in travelers) {
      // 🔥 FIXED: Multiple field names handle करता है
      final name = traveler['name'] ??
          traveler['travelerName'] ??
          traveler['travellerName'] ?? 'Traveler';
      final phone = traveler['phone'] ??
          traveler['mobile'] ??
          traveler['phoneNumber'] ?? '';

      print('👤 Processing: $name | $phone');

      notifications.addAll([
        {
          'id': '${phone}_flight',
          'travelerName': name,
          'travelerPhone': phone,
          'title': '✈️ $name - Flight Reminder',
          'message': 'Mumbai to Shimla - IX1234 • 19 Dec 6:00 AM',
          'time': '19 Dec 6:00 AM',
          'type': 'flight',
          'status': 'scheduled',
        },
        {
          'id': '${phone}_hotel',
          'travelerName': name,
          'travelerPhone': phone,
          'title': '🏨 $name - Hotel Check-in',
          'message': 'Taj Mumbai • Check-in after 2:00 PM',
          'time': '19 Dec 2:00 PM',
          'type': 'hotel',
          'status': 'scheduled',
        },
        {
          'id': '${phone}_pickup',
          'travelerName': name,
          'travelerPhone': phone,
          'title': '🚗 $name - Airport Pickup',
          'message': 'Cab booked • Driver: Rajesh • +91 98765 43210',
          'time': '19 Dec 5:00 AM',
          'type': 'transfer',
          'status': 'scheduled',
        },
      ]);
    }

    setState(() {
      print('✅ Generated ${notifications.length} notifications');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      // ✅ ADAPTIVE BACKGROUND
      backgroundColor: colorScheme.surfaceVariant,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 12 : 8),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.notifications,
                color: colorScheme.onTertiaryContainer,
                size: isTablet ? 28 : 24,
              ),
            ),
            SizedBox(width: isTablet ? 16 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifications',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  Text(
                    widget.itineraryTitle,
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      color: colorScheme.onPrimary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: colorScheme.primary,
        elevation: 0,
      ),
      body: _buildResponsiveBody(theme, colorScheme, isTablet),
    );
  }

  Widget _buildResponsiveBody(ThemeData theme, ColorScheme colorScheme, bool isTablet) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: colorScheme.primary,
              strokeWidth: 4,
            ),
            SizedBox(height: 20),
            Text(
              'Loading notifications...',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (travelers.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 60 : 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: isTablet ? 100 : 80,
                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              SizedBox(height: isTablet ? 32 : 24),
              Text(
                'कोई traveler नहीं है',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Detail screen से travelers add करें',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back),
                label: Text('Add Travelers'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // 🔥 RESPONSIVE TWO BIG BUTTONS
        Container(
          margin: EdgeInsets.all(isTablet ? 24 : 16),
          child: Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.phone_android,
                  label: '📱 Device WhatsApp (${travelers.length})',
                  bgColor: Colors.blue.shade600,
                  onTap: _isSending ? null : _sendToAllTravelers,
                  theme: theme,
                  isTablet: isTablet,
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.rocket_launch,
                  label: '🚀 Real WhatsApp (${travelers.length})',
                  bgColor: Colors.green.shade600,
                  onTap: _isSending ? null : _sendRealWhatsAppToAll,
                  theme: theme,
                  isTablet: isTablet,
                ),
              ),
            ],
          ),
        ),

        // 🔥 STATS ROW
        Container(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 28 : 20, vertical: 12),
          margin: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.2),
            borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
          ),
          child: Row(
            children: [
              Icon(Icons.people,
                color: colorScheme.primary,
                size: isTablet ? 24 : 20,
              ),
              SizedBox(width: isTablet ? 12 : 8),
              Text(
                '${travelers.length} travelers • ${notifications.length} notifications',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // 🔥 RESPONSIVE LIST
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(isTablet ? 24 : 16),
            itemCount: notifications.length,
            itemBuilder: (context, index) =>
                _buildResponsiveNotificationCard(notifications[index], theme, colorScheme, isTablet),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color bgColor,
    required VoidCallback? onTap,
    required ThemeData theme,
    required bool isTablet,
  }) {
    return Container(
      height: isTablet ? 68 : 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isTablet ? 28 : 25),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.3),
            blurRadius: isTablet ? 25 : 16,
            offset: Offset(0, isTablet ? 10 : 8),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: isTablet ? 28 : 24, color: Colors.white),
        label: Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isTablet ? 28 : 25),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildResponsiveNotificationCard(
      Map<String, dynamic> notif,
      ThemeData theme,
      ColorScheme colorScheme,
      bool isTablet,
      ) {
    final travelerName = notif['travelerName'];
    final travelerPhone = notif['travelerPhone'];
    final isScheduled = notif['status'] == 'scheduled';

    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isTablet ? 24 : 16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: isTablet ? 20 : 12,
            offset: Offset(0, isTablet ? 6 : 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isTablet ? 24 : 16),
          side: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
        ),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 24 : 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ AVATAR
              Container(
                width: isTablet ? 56 : 48,
                height: isTablet ? 56 : 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primaryContainer, colorScheme.secondaryContainer],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.2),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person,
                  color: colorScheme.onPrimaryContainer,
                  size: isTablet ? 26 : 22,
                ),
              ),
              SizedBox(width: isTablet ? 20 : 16),

              // ✅ CONTENT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notif['title'],
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: isTablet ? 8 : 4),
                    Text(
                      notif['message'],
                      style: theme.textTheme.bodyMedium,
                    ),
                    SizedBox(height: isTablet ? 12 : 8),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 14 : 12,
                        vertical: isTablet ? 8 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                      ),
                      child: Text(
                        travelerName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                          fontSize: isTablet ? 14 : 13,
                        ),
                      ),
                    ),
                    SizedBox(height: isTablet ? 12 : 8),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                          size: isTablet ? 18 : 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(width: 6),
                        Text(
                          notif['time'],
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Spacer(),
                        if (isScheduled)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'SCHEDULED',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: isTablet ? 13 : 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // ✅ SEND BUTTON
              Container(
                width: isTablet ? 52 : 48,
                height: isTablet ? 52 : 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF25D366).withOpacity(0.4),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () => _sendWhatsAppToTraveler(notif),
                  icon: Icon(Icons.send, color: Colors.white, size: isTablet ? 22 : 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ALL OTHER METHODS SAME - _sendToAllTravelers, _sendRealWhatsAppToAll, _sendWhatsAppToTraveler
  Future<void> _sendToAllTravelers() async {
    setState(() => _isSending = true);
    int sent = 0;

    for (var traveler in travelers) {
      final phone = traveler['phone']?.toString().replaceAll('+91', '') ?? '';
      final name = traveler['name'] ?? 'Traveler';

      if (phone.isNotEmpty && phone.length >= 10) {
        final message = '🎉 ${widget.itineraryTitle}\nHi $name! Trip ready!';
        final uri = Uri.parse('https://wa.me/91$phone?text=${Uri.encodeComponent(message)}');

        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          sent++;
          await Future.delayed(Duration(milliseconds: 1000));
        } catch (e) {
          print('Device WhatsApp Error: $e');
        }
      }
    }

    setState(() => _isSending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ $sent/${travelers.length} को Device WhatsApp भेजा!')),
    );
  }

  Future<void> _sendRealWhatsAppToAll() async {
    setState(() => _isSending = true);
    try {
      print('🚀 Sending to ${travelers.length} travelers: $travelers');
      final res = await ApiService.sendWhatsAppToAll(widget.itineraryId);

      print('✅ Backend Response: $res');

      if (res['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${res['sent'] ?? 0}/${res['total'] ?? travelers.length} को Real WhatsApp भेजा!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${res['message'] ?? 'Failed'} (${res['sent'] ?? 0}/${res['total'] ?? 0})'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Network Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _sendWhatsAppToTraveler(Map<String, dynamic> notif) async {
    final phone = notif['travelerPhone'].toString().replaceAll('+91', '');
    final name = notif['travelerName'];
    final message = notif['message'];

    final fullMessage = '$message\n\n${widget.itineraryTitle}';
    final uri = Uri.parse('https://wa.me/91$phone?text=${Uri.encodeComponent(fullMessage)}');

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ $name को भेजा!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }
}
