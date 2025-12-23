import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';
import 'upload_itinerary_screen.dart';
import 'itinerary_detail_screen.dart';
import 'ai_chat_screen.dart';
import 'notifications_screen.dart';
import 'add_traveler_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List itineraries = [];
  bool loading = true;
  bool isEmpty = false;
  Map<String, dynamic>? analytics;

  @override
  void initState() {
    super.initState();
    _loadItineraries();
    _loadAnalytics();
  }

  Future<void> _loadItineraries() async {
    setState(() => loading = true);
    try {
      final res = await ApiService.getItineraries();
      print('📡 API RESPONSE: ${jsonEncode(res)}');

      if (res['status'] == true) {
        setState(() {
          itineraries = res['data'] ?? [];
          isEmpty = itineraries.isEmpty;
        });
      } else {
        setState(() => isEmpty = true);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Failed to load')),
          );
        }
      }
    } catch (e) {
      print('❌ ERROR: $e');
      setState(() => isEmpty = true);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _loadAnalytics() async {
    try {
      final res = await ApiService.getAnalytics();
      print('📊 ANALYTICS: ${jsonEncode(res)}');
      if (res['status'] == true && mounted) {
        setState(() => analytics = res['data']);
      }
    } catch (e) {
      print('📊 Analytics error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: colorScheme.surfaceVariant,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.dashboard,
              color: colorScheme.onPrimary,
              size: isTablet ? 28 : 24,
            ),
            SizedBox(width: isTablet ? 16 : 12),
            Text(
              'My Trips',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimary,
              ),
            ),
          ],
        ),
        backgroundColor: colorScheme.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: colorScheme.onPrimary),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: loading
            ? _buildResponsiveLoading(theme, isTablet)
            : Column(
          children: [
            Expanded(
              child: isEmpty
                  ? _buildResponsiveEmpty(theme, isTablet)
                  : RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    _loadItineraries(),
                    _loadAnalytics(),
                  ]);
                },
                color: colorScheme.primary,
                child: ListView.builder(
                  padding: EdgeInsets.all(isTablet ? 24 : 16),
                  itemCount: itineraries.length,
                  itemBuilder: (context, index) {
                    final item = itineraries[index] as Map<String, dynamic>;
                    return _buildResponsiveTripCard(item, theme, isTablet);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/upload').then((_) => _loadItineraries()),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 8,
        icon: Icon(Icons.add, size: isTablet ? 24 : 20),
        label: Text(
          'New Trip',
          style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onPrimary),
        ),
      ),
    );
  }

  Widget _buildResponsiveAnalyticsCard(ThemeData theme, bool isTablet) {
    final colorScheme = theme.colorScheme;
    if (analytics == null) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.all(isTablet ? 24 : 16),
      padding: EdgeInsets.all(isTablet ? 28 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withOpacity(0.4),
            colorScheme.surfaceVariant.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isTablet ? 28 : 20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.2),
            blurRadius: isTablet ? 30 : 20,
            offset: Offset(0, isTablet ? 15 : 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined,
                  color: colorScheme.primary,
                  size: isTablet ? 32 : 28),
              SizedBox(width: isTablet ? 16 : 12),
              Text(
                '📊 Agency Stats',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _loadAnalytics,
                icon: Icon(Icons.refresh, size: isTablet ? 20 : 18),
                label: Text(
                  'Refresh',
                  style: TextStyle(color: colorScheme.primary),
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 28 : 20),
          Row(
            children: [
              Expanded(
                child: _buildResponsiveStatTile(
                  '📋',
                  analytics!['totalItineraries'] ?? 0,
                  'Itineraries',
                  theme,
                  isTablet,
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: _buildResponsiveStatTile(
                  '👥',
                  analytics!['totalTravelers'] ?? 0,
                  'Travelers',
                  theme,
                  isTablet,
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: _buildResponsiveStatTile(
                  '📱',
                  analytics!['whatsappSent'] ?? 0,
                  'WhatsApp',
                  theme,
                  isTablet,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveStatTile(
      String icon,
      dynamic value,
      String label,
      ThemeData theme,
      bool isTablet,
      ) {
    final colorScheme = theme.colorScheme;
    return Column(
      children: [
        Text(
          '$icon ${value.toString()}',
          style: TextStyle(
            fontSize: isTablet ? 36 : 28,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
            height: 1.1,
          ),
        ),
        SizedBox(height: isTablet ? 8 : 4),
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 15 : 13,
            color: colorScheme.primaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveTripCard(
      Map<String, dynamic> item,
      ThemeData theme,
      bool isTablet,
      ) {
    final colorScheme = theme.colorScheme;
    return Card(
        margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
        elevation: isTablet ? 8 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
        ),
        child: InkWell(
            borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
            onTap: () => Navigator.pushNamed(
              context,
              '/itinerary-detail',
              arguments: item,
            ).then((_) => _loadItineraries()),
            child: Padding(
                padding: EdgeInsets.all(isTablet ? 24 : 20),
                child: Row(
                  children: [
                Container(
                width: isTablet ? 80 : 70,
                  height: isTablet ? 80 : 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primaryContainer,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(isTablet ? 20 : 18),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.flight_takeoff,
                    color: colorScheme.onPrimary,
                    size: isTablet ? 36 : 32,
                  ),
                ),
                SizedBox(width: isTablet ? 20 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] ?? 'Untitled Trip',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['destination'] ?? 'Unknown Destination',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: isTablet ? 12 : 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: isTablet ? 16 : 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatDateRange(
                              item['startDate'],
                              item['endDate'],
                            ),
                            style: TextStyle(
                              fontSize: isTablet ? 14 : 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 12 : 10,
                              vertical: isTablet ? 8 : 6,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(isTablet ? 18 : 15),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people,
                                  size: isTablet ? 16 : 14,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${item['travelerCount'] ?? 0}',
                                  style: TextStyle(
                                    fontSize: isTablet ? 14 : 12,
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'chat':
                        _openChat(item);
                        break;
                      case 'add_traveler':
                        _openAddTraveler(item);
                        break;
                      case 'notify':
                        _openNotifications(item);
                        break;
                      case 'stats':
                        _showAnalyticsBottomSheet();
                        break;
                      case 'delete':
                        _deleteItinerary(item['_id'].toString());
                        break;
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                  ),
                  itemBuilder: (context) => [
                  PopupMenuItem(
                  value: 'chat',
                  child: Row(
                    children: [
                      Icon(Icons.chat, size: 20, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      const Text('AI Chat'),
                    ],
                  ),
                ),
                    PopupMenuItem(
                      value: 'add_traveler',
                      child: Row(
                        children: [
                          Icon(Icons.person_add, size: 20, color: colorScheme.secondary),
                          const SizedBox(width: 12),
                          const Text('Add Travelers'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'notify',
                      child: Row(
                        children: [
                          Icon(Icons.notifications, size: 20, color: Colors.orange),
                          const SizedBox(width: 12),
                          const Text('Notifications'),
                        ],
                      ),
                    ),
                    if (analytics != null)
                      PopupMenuItem(
                        value: 'stats',
                        child: Row(
                          children: [
                            Icon(Icons.analytics_outlined, size: 20, color: Colors.teal),
                            const SizedBox(width: 12),
                            const Text('View Stats'),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          const SizedBox(width: 12),
                          const Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: EdgeInsets.all(isTablet ? 12 : 8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
                  ),
                ),
                  ],
                ),
            ),
        ),
    );
  }

  Widget _buildResponsiveLoading(ThemeData theme, bool isTablet) => Center(
    child: Padding(
      padding: EdgeInsets.all(isTablet ? 60 : 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.colorScheme.primary, strokeWidth: 4),
          SizedBox(height: isTablet ? 24 : 16),
          Text(
            'Loading your trips...',
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    ),
  );

  Widget _buildResponsiveEmpty(ThemeData theme, bool isTablet) => Center(
    child: Padding(
      padding: EdgeInsets.all(isTablet ? 60 : 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.flight_land,
            size: isTablet ? 100 : 80,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          SizedBox(height: isTablet ? 32 : 24),
          Text(
            'No Trips Yet',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Create your first travel itinerary to get started',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          SizedBox(height: isTablet ? 48 : 40),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/upload').then((_) => _loadItineraries()),
            icon: Icon(Icons.add, size: isTablet ? 24 : 20),
            label: Text('Plan First Trip', style: theme.textTheme.titleMedium),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 40 : 32, vertical: isTablet ? 20 : 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isTablet ? 32 : 30)),
              elevation: isTablet ? 12 : 8,
            ),
          ),
        ],
      ),
    ),
  );

  void _openChat(Map<String, dynamic> itinerary) {
    Navigator.pushNamed(context, '/ai-chat', arguments: {
      'id': itinerary['_id'].toString(),
      'title': itinerary['title'] ?? 'Your Trip',
    });
  }

  void _openAddTraveler(Map<String, dynamic> itinerary) {
    Navigator.pushNamed(context, '/add-traveler', arguments: {
      'id': itinerary['_id'].toString(),
      'title': itinerary['title'] ?? 'Trip',
    }).then((_) => _loadItineraries());
  }

  void _openNotifications(Map<String, dynamic> itinerary) {
    Navigator.pushNamed(context, '/notifications', arguments: {
      'id': itinerary['_id'].toString(),
      'title': itinerary['title'] ?? 'Trip',
    });
  }

  void _showLogoutDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItinerary(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip'),
        content: const Text('Are you sure you want to delete this trip?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final res = await ApiService.delete(id);
        if (res['status'] == true) {
          _loadItineraries();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip deleted successfully!')));
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
        }
      }
    }
  }

  void _showAnalyticsBottomSheet() {
    if (analytics == null) return;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: colorScheme.surface,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).padding.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics_outlined, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      'Agency Stats',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildBottomStatTile(theme, colorScheme, label: 'Itineraries', value: analytics!['totalItineraries'] ?? 0, icon: Icons.flight_takeoff),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildBottomStatTile(theme, colorScheme, label: 'Travelers', value: analytics!['totalTravelers'] ?? 0, icon: Icons.people),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildBottomStatTile(theme, colorScheme, label: 'WhatsApp', value: analytics!['whatsappSent'] ?? 0, icon: Icons.chat),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildBottomStatTile(theme, colorScheme, label: 'Active Trips', value: (analytics!['activeTrips'] ?? 0) as int, icon: Icons.airplanemode_active),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildBottomStatTile(theme, colorScheme, label: 'AI Queries', value: (analytics!['chatQueries'] ?? 0) as int, icon: Icons.smart_toy_outlined),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline, size: 24, color: colorScheme.primary),
                            const SizedBox(height: 8),
                            Text(
                              (analytics!['successRate'] ?? '0%').toString(),
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Success Rate',
                              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomStatTile(ThemeData theme, ColorScheme colorScheme, {
    required String label,
    required dynamic value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  String _formatDateRange(String? startDate, String? endDate) {
    if (startDate == null && endDate == null) return 'Dates TBD';
    try {
      if (startDate != null) {
        final start = DateTime.parse(startDate);
        if (endDate != null) {
          final end = DateTime.parse(endDate);
          return '${start.day}/${start.month} - ${end.day}/${end.month}';
        }
        return '${start.day}/${start.month}/${start.year}';
      }
      return 'End date only';
    } catch (e) {
      return startDate ?? 'Date error';
    }
  }
}

