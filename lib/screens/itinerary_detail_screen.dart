import 'package:flutter/material.dart';
import '../api/api_service.dart';
import 'dart:async';

class ItineraryDetailScreen extends StatefulWidget {
  final Map<String, dynamic> itinerary;

  const ItineraryDetailScreen({
    super.key,
    required this.itinerary,
  });

  @override
  State<ItineraryDetailScreen> createState() => _ItineraryDetailScreenState();
}

class _ItineraryDetailScreenState extends State<ItineraryDetailScreen>
    with TickerProviderStateMixin {
  bool isEditing = false;
  late final TextEditingController _titleController;
  List<dynamic> days = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool isLoading = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.itinerary['title'] ?? '');
    print('🚀 DetailScreen OPEN - ID: ${widget.itinerary['_id']}');
    _loadFreshData();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFreshData();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _titleController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadFreshData() async {
    print('🔄 _loadFreshData START');
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final id = widget.itinerary['_id']?.toString() ?? '';
      print('📋 Loading ID: $id');

      if (id.isNotEmpty) {
        final freshData = await ApiService.getItinerary(id);
        print('📥 API Response status: ${freshData['status']}');
        print('📥 Days in response: ${freshData['data']?['days']?.length ?? 0}');

        if (mounted && freshData['status'] == true) {
          setState(() {
            final data = freshData['data'] ?? freshData;
            _titleController.text = data['title'] ?? widget.itinerary['title'] ?? '';
            days = List.from(data['days'] ?? []);
            print('✅ Days LOADED: ${days.length}');
          });
        }
      }
    } catch (e) {
      print('❌ _loadFreshData ERROR: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
        print('🔄 _loadFreshData COMPLETE');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final data = widget.itinerary;

    return Scaffold(
      backgroundColor: colorScheme.surfaceVariant.withOpacity(0.1),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: isTablet ? 200 : 160,
              floating: false,
              pinned: true,
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              elevation: 0,
              titleSpacing: 0,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                title: SizedBox(
                  height: 56,
                  child: AnimatedPadding(
                    duration: const Duration(milliseconds: 300),
                    padding: EdgeInsets.zero,
                    child: TextFormField(
                      controller: _titleController,
                      enabled: isEditing,
                      maxLines: 1,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
                        fontSize: 20,
                        height: 1.2,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Trip Title',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: colorScheme.onPrimary.withOpacity(0.6),
                          fontSize: 18,
                          height: 1.2,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 12,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.primaryContainer],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              actions: [],
            ),

            SliverToBoxAdapter(
              child: Container(
                margin: EdgeInsets.fromLTRB(
                  isTablet ? 28 : 20,
                  12,
                  isTablet ? 28 : 20,
                  24,
                ),
                padding: EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: isTablet ? 24 : 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        Icons.person_add,
                        'Add Travelers',
                        Colors.green.shade400,
                            () => _navigate('/add-traveler'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _actionButton(
                        Icons.smart_toy,
                        'AI Chat',
                        Colors.blue.shade400,
                            () => _navigate('/ai-chat'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _actionButton(
                        Icons.notifications_active,
                        'Notify',
                        Colors.orange.shade400,
                            () => _navigate('/notifications'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 28 : 20),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDestinationHeader(data, colorScheme, isTablet),
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildInfoCards(data, theme, colorScheme, isTablet),
                      SizedBox(height: isTablet ? 32 : 24),
                      _buildTimeline(theme, colorScheme, isTablet),
                      SizedBox(height: isTablet ? 80 : 60),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: null,
    );
  }

  // 🔥 PERFECT Timeline Title - Dark/Light दोनों में visible
  Widget _buildTimeline(ThemeData theme, ColorScheme colorScheme, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: Text(
                'Itinerary Timeline',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 20 : 18,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Day'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: _showDayDialog,
            ),
          ],
        ),
        SizedBox(height: isTablet ? 24 : 20),
        days.isEmpty
            ? _emptyTimeline(theme, colorScheme, isTablet)
            : Column(
          children: days.asMap().entries
              .map((entry) => _timelineDayCard(
              entry.key, entry.value, theme, colorScheme, isTablet))
              .toList(),
        ),
      ],
    );
  }

  Future<void> _saveToBackend() async {
    try {
      final id = widget.itinerary['_id']?.toString() ?? '';
      print('💾 Saving ID: $id | Days: ${days.length}');
      final response = await ApiService.put('itinerary/$id', {
        'title': _titleController.text.trim(),
        'days': days,
      });
      print('✅ Backend SAVE SUCCESS: ${response['status']}');
      _loadFreshData();
    } catch (e) {
      print('❌ Backend SAVE ERROR: $e');
    }
  }

  Future<void> _saveDay(int? editIndex, Map<String, TextEditingController> controllers) async {
    final newDay = {
      'day': int.tryParse(controllers['day']!.text ?? '') ?? (editIndex ?? days.length) + 1,
      'title': controllers['title']!.text.trim(),
      'time': controllers['time']!.text.trim(),
      'location': controllers['location']!.text.trim(),
      'description': controllers['description']!.text.trim(),
    };

    setState(() {
      if (editIndex != null) {
        days[editIndex] = newDay;
        print('✏️ Day $editIndex UPDATED');
      } else {
        days.add(newDay);
        print('➕ Day ${days.length} ADDED');
      }
    });

    Navigator.pop(context);
    await _saveToBackend();
  }

  Future<void> _refreshData() async {
    await _loadFreshData();
  }

  Widget _buildDestinationHeader(
      Map<String, dynamic> data, ColorScheme colorScheme, bool isTablet) {
    final destination = data['destination'] ?? 'No destination';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [colorScheme.primary, colorScheme.primaryContainer]),
        borderRadius: BorderRadius.circular(isTablet ? 28 : 20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.4),
            blurRadius: isTablet ? 40 : 25,
            offset: Offset(0, isTablet ? 20 : 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            decoration:
            BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(Icons.location_on,
                color: Colors.white, size: isTablet ? 28 : 24),
          ),
          SizedBox(width: isTablet ? 20 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  destination,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 28 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Tap days below to edit timeline',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards(
      Map<String, dynamic> data, ThemeData theme, ColorScheme colorScheme, bool isTablet) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _infoCard('🗓️ Start Date', _formatDate(data['startDate']),
                  Icons.calendar_today, colorScheme, isTablet),
            ),
            SizedBox(width: isTablet ? 16 : 12),
            Expanded(
              child: _infoCard('🗓️ End Date', _formatDate(data['endDate']),
                  Icons.event, colorScheme, isTablet),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 16 : 12),
        Row(
          children: [
            Expanded(
              child: _infoCard('📊 Status', (data['status'] ?? 'DRAFT').toUpperCase(),
                  Icons.flag, colorScheme, isTablet),
            ),
            SizedBox(width: isTablet ? 16 : 12),
            Expanded(
              child: _infoCard('👥 Type', data['travelerType'] ?? 'Solo',
                  Icons.people_outline, colorScheme, isTablet),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 16 : 12),
        _infoCard('👥 Travelers', '${data['travelerCount'] ?? 0}',
            Icons.group, colorScheme, isTablet, isFullWidth: true),
      ],
    );
  }

  Widget _infoCard(String label, String value, IconData icon, ColorScheme colorScheme,
      bool isTablet, {bool isFullWidth = false}) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 12 : 10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colorScheme.primary, size: isTablet ? 22 : 20),
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineDayCard(int index, dynamic dayData, ThemeData theme,
      ColorScheme colorScheme, bool isTablet) {
    final day = dayData['day'] ?? index + 1;
    final title = dayData['title'] ?? 'Untitled Day';
    final time = dayData['time'] ?? '09:00';
    final location = dayData['location'] ?? 'TBD';
    return GestureDetector(
      onTap: () => _showDayDialog(editIndex: index, editData: dayData),
      child: Container(
        margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: isTablet ? 60 : 50,
              height: isTablet ? 60 : 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.primaryContainer],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  'Day $day',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
              ),
            ),
            SizedBox(width: isTablet ? 20 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$time • $location',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dayData['description'] ?? '',
                    style: const TextStyle(height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyTimeline(ThemeData theme, ColorScheme colorScheme, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 48 : 40),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.timeline,
            size: isTablet ? 64 : 56,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No days added yet',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Click "Add Day" to start planning your trip',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.15),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDayDialog({int? editIndex, Map<String, dynamic>? editData}) {
    final controllers = {
      'day': TextEditingController(text: editData?['day']?.toString() ?? ''),
      'title': TextEditingController(text: editData?['title'] ?? ''),
      'time': TextEditingController(text: editData?['time'] ?? '09:00'),
      'location': TextEditingController(text: editData?['location'] ?? ''),
      'description': TextEditingController(text: editData?['description'] ?? ''),
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(editData != null ? 'Edit Day' : 'Add Day'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: controllers.entries
                .map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                controller: entry.value,
                decoration: InputDecoration(
                  labelText: entry.key.toUpperCase(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.edit),
                ),
              ),
            ))
                .toList(),
          ),
        ),
        actions: [
          if (editIndex != null)
            TextButton(
              onPressed: () => _deleteDay(editIndex, controllers),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _saveDay(editIndex, controllers),
            child: Text(editData != null ? 'Update' : 'Add'),
          ),
        ],
      ),
    ).then((_) => controllers.values.forEach((c) => c.dispose()));
  }

  Future<void> _deleteDay(int index, Map<String, TextEditingController> controllers) async {
    final confirmed = await _showConfirmDialog('Delete Day ${days[index]['day']}?');
    if (confirmed) {
      setState(() => days.removeAt(index));
      Navigator.pop(context);
      await _saveToBackend();
    }
  }

  Future<void> _saveChanges() async {
    setState(() => isEditing = false);
    await _saveToBackend();
  }

  void _navigate(String route) {
    Navigator.pushNamed(context, route,
        arguments: {'id': widget.itinerary['_id']?.toString() ?? '', 'title': _titleController.text});
  }

  Future<bool> _showConfirmDialog(String message) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ??
        false;
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
