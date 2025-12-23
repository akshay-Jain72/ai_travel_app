import 'package:flutter/material.dart';
import 'ai_chat_screen.dart';
import 'add_traveler_screen.dart';
import 'notifications_screen.dart';
import '../api/api_service.dart';

class ItineraryDetailScreen extends StatefulWidget {
  final Map<String, dynamic> itinerary;

  const ItineraryDetailScreen({
    Key? key,
    required this.itinerary,
  }) : super(key: key);

  @override
  State<ItineraryDetailScreen> createState() => _ItineraryDetailScreenState();
}

class _ItineraryDetailScreenState extends State<ItineraryDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final data = widget.itinerary;
    final title = data['title'] ?? 'Untitled';
    final destination = data['destination'] ?? 'No destination';

    return Scaffold(
      // ✅ ADAPTIVE BACKGROUND
      backgroundColor: colorScheme.surfaceVariant,
      appBar: AppBar(
        title: Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
          ),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: colorScheme.onPrimary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'delete') {
                _deleteItinerary(data['_id']?.toString() ?? '');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$value itinerary')),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: colorScheme.primary),
                    SizedBox(width: 12),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, color: colorScheme.primary),
                    SizedBox(width: 12),
                    Text('Share'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isTablet ? 28 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔥 RESPONSIVE HEADER
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isTablet ? 32 : 25),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.primaryContainer],
                ),
                borderRadius: BorderRadius.circular(isTablet ? 28 : 20),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: isTablet ? 40 : 25,
                    offset: Offset(0, isTablet ? 20 : 12),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on,
                        color: colorScheme.onPrimary,
                        size: isTablet ? 32 : 28,
                      ),
                      SizedBox(width: isTablet ? 16 : 12),
                      Expanded(
                        child: Text(
                          destination,
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: isTablet ? 26 : 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isTablet ? 12 : 8),
                  Text(
                    title,
                    style: TextStyle(
                      color: colorScheme.onPrimary.withOpacity(0.95),
                      fontSize: isTablet ? 18 : 16,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isTablet ? 32 : 25),

            // 🔥 RESPONSIVE INFO CARDS
            _infoRow('🗓️ Start Date', _formatDate(data['startDate']), theme, isTablet),
            SizedBox(height: isTablet ? 20 : 15),
            _infoRow('🗓️ End Date', _formatDate(data['endDate']), theme, isTablet),
            SizedBox(height: isTablet ? 20 : 15),
            _infoRow('📊 Status', (data['status'] ?? 'DRAFT').toString().toUpperCase(), theme, isTablet),
            SizedBox(height: isTablet ? 20 : 15),
            _infoRow('👥 Type', data['travelerType'] ?? 'Solo', theme, isTablet),
            SizedBox(height: isTablet ? 32 : 25),

            // 🔥 RESPONSIVE TIMELINE TITLE
            Text(
              '📅 Itinerary Timeline',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: isTablet ? 28 : 20),
            _buildTimeline(theme, isTablet),

            // 🔥 RESPONSIVE ACTIONS
            SizedBox(height: isTablet ? 48 : 40),
            Row(
              children: [
                Expanded(
                  child: _bigButton(
                    Icons.person_add,
                    'Add Traveler',
                    colorScheme.secondaryContainer,
                    colorScheme.onSecondaryContainer,
                        () => _navigateToAddTraveler(),
                    theme,
                    isTablet,
                  ),
                ),
                SizedBox(width: isTablet ? 16 : 12),
                Expanded(
                  child: _bigButton(
                    Icons.smart_toy,
                    'AI Chat',
                    colorScheme.primaryContainer,
                    colorScheme.onPrimaryContainer,
                        () => _navigateToAIChat(),
                    theme,
                    isTablet,
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 20 : 16),
            Row(
              children: [
                Expanded(
                  child: _bigButton(
                    Icons.notifications_active,
                    'Notifications',
                    colorScheme.tertiaryContainer,
                    colorScheme.onTertiaryContainer,
                        () => _navigateToNotifications(),
                    theme,
                    isTablet,
                  ),
                ),
                SizedBox(width: isTablet ? 16 : 12),
                Expanded(
                  child: _bigButton(
                    Icons.share,
                    'Share Itinerary',
                    colorScheme.surfaceVariant,
                    colorScheme.onSurfaceVariant,
                        () {},
                    theme,
                    isTablet,
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 32 : 20),
          ],
        ),
      ),
    );
  }

  // 🔥 RESPONSIVE TIMELINE
  Widget _buildTimeline(ThemeData theme, bool isTablet) {
    final destinations = ['Mumbai', 'Shimla', 'Manali', 'Udaipur'];
    return Column(
      children: List.generate(
        destinations.length,
            (index) => _timelineDay(
          day: index + 1,
          date: '19-20 Dec',
          destination: destinations[index],
          activities: _getActivities(index + 1),
          theme: theme,
          isTablet: isTablet,
        ),
      ),
    );
  }

  Widget _timelineDay({
    required int day,
    required String date,
    required String destination,
    required List<String> activities,
    required ThemeData theme,
    required bool isTablet,
  }) {
    final colorScheme = theme.colorScheme;
    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 24 : 20),
      padding: EdgeInsets.all(isTablet ? 28 : 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(isTablet ? 28 : 20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.15),
            blurRadius: isTablet ? 25 : 20,
            offset: Offset(0, isTablet ? 8 : 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 16 : 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.primaryContainer],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.4),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: isTablet ? 18 : 16,
                  ),
                ),
              ),
              SizedBox(width: isTablet ? 20 : 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Day $day',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '$date • $destination',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: isTablet ? 28 : 20),
          ...activities.map(
                (activity) => Padding(
              padding: EdgeInsets.only(bottom: isTablet ? 16 : 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: isTablet ? 6 : 4,
                    height: isTablet ? 24 : 20,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(isTablet ? 3 : 2),
                    ),
                  ),
                  SizedBox(width: isTablet ? 16 : 12),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(isTablet ? 16 : 12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(isTablet ? 20 : 12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(isTablet ? 8 : 4),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.access_time,
                              size: isTablet ? 20 : 16,
                              color: colorScheme.primary,
                            ),
                          ),
                          SizedBox(width: isTablet ? 16 : 12),
                          Expanded(
                            child: Text(
                              activity,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, ThemeData theme, bool isTablet) => Container(
    padding: EdgeInsets.all(isTablet ? 28 : 20),
    decoration: BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(isTablet ? 24 : 16),
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.shadow.withOpacity(0.1),
          blurRadius: isTablet ? 25 : 15,
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );

  Widget _bigButton(IconData icon, String label, Color bgColor, Color fgColor, VoidCallback onTap, ThemeData theme, bool isTablet) =>
      Container(
        height: isTablet ? 64 : 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isTablet ? 24 : 16),
          boxShadow: [
            BoxShadow(
              color: bgColor.withOpacity(0.3),
              blurRadius: isTablet ? 20 : 12,
              offset: Offset(0, isTablet ? 8 : 6),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: isTablet ? 26 : 24, color: fgColor),
          label: Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: fgColor,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: fgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isTablet ? 24 : 16),
            ),
            elevation: 0,
          ),
        ),
      );

  List<String> _getActivities(int day) {
    final activities = [
      ['9:00 AM: Hotel Check-in', '2:00 PM: Gateway of India', '7:00 PM: Marine Drive Dinner'],
      ['8:00 AM: Flight to Shimla', '12:00 PM: Mall Road Walk', '6:00 PM: Hotel Check-in'],
      ['9:00 AM: Drive to Manali', '3:00 PM: Rohtang Pass', '7:00 PM: Snow activities'],
      ['10:00 AM: City Palace', '2:00 PM: Lake Pichola Boat', '6:00 PM: Cultural Show'],
    ];

    if (day >= 1 && day <= activities.length) {
      return activities[day - 1];
    }
    return ['No activities planned for this day'];
  }

  void _navigateToAddTraveler() {
    Navigator.pushNamed(
      context,
      '/add-traveler',
      arguments: {
        'id': widget.itinerary['_id']?.toString() ?? '',
        'title': widget.itinerary['title']?.toString() ?? '',
      },
    );
  }

  void _navigateToAIChat() {
    Navigator.pushNamed(
      context,
      '/ai-chat',
      arguments: {
        'id': widget.itinerary['_id']?.toString() ?? '',
        'title': widget.itinerary['title']?.toString() ?? '',
      },
    );
  }

  void _navigateToNotifications() {
    Navigator.pushNamed(
      context,
      '/notifications',
      arguments: {
        'id': widget.itinerary['_id']?.toString() ?? '',
        'title': widget.itinerary['title']?.toString() ?? '',
      },
    );
  }

  Future<void> _deleteItinerary(String id) async {
    final response = await ApiService.delete(id);
    if (response['status'] == true) {
      if (context.mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Trip deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Delete failed')),
        );
      }
    }
  }

  String _formatDate(String? date) {
    if (date == null) return 'Not set';
    try {
      final parsed = DateTime.parse(date);
      return '${parsed.day}/${parsed.month}/${parsed.year}';
    } catch (e) {
      return date;
    }
  }
}
