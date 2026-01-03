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

    // 🔥 INSTANT LOAD - No delay! तुरंत days show
    print('🚀 DetailScreen OPEN - ID: ${widget.itinerary['_id']}');
    _loadFreshData();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();
  }

  // 🔥 BACK आने पर भी तुरंत refresh
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFreshData();
  }

  // 🔥 dispose में timer cancel
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
              flexibleSpace: FlexibleSpaceBar(
                title: AnimatedPadding(
                  duration: Duration(milliseconds: 300),
                  padding: EdgeInsets.zero,
                  child: TextFormField(
                    controller: _titleController,
                    enabled: isEditing,
                    maxLines: 1,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Trip Title',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: colorScheme.onPrimary.withOpacity(0.6)),
                      contentPadding: EdgeInsets.zero,
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
              actions: [
                IconButton(
                  icon: AnimatedIcon(
                    icon: AnimatedIcons.menu_close,
                    progress: _animationController,
                    color: isEditing ? Colors.green : null,
                  ),
                  onPressed: isEditing ? _saveChanges : () => setState(() => isEditing = true),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  onSelected: (value) => _handlePopupAction(value, data),
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share_outlined), SizedBox(width: 12), Text('Share Trip')])),
                    PopupMenuItem(value: 'duplicate', child: Row(children: [Icon(Icons.content_copy), SizedBox(width: 12), Text('Duplicate')])),
                    PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: Colors.red), SizedBox(width: 12), Text('Delete', style: TextStyle(color: Colors.red))])),
                  ],
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 28 : 20),
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDestinationHeader(data, colorScheme, isTablet),
                      SizedBox(height: isTablet ? 32 : 24),
                      _buildInfoCards(data, theme, colorScheme, isTablet),
                      SizedBox(height: isTablet ? 32 : 24),
                      _buildTimeline(theme, colorScheme, isTablet),
                      SizedBox(height: isTablet ? 100 : 80),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildActionBar(theme, colorScheme, isTablet),
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
      _loadFreshData(); // 🔥 Auto refresh after save
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

  // 🔥 CLEAN TITLE - सिर्फ "Itinerary Timeline"
  Widget _buildTimeline(ThemeData theme, ColorScheme colorScheme, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '📅 Itinerary Timeline', // 🔥 FIXED - No days count
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isTablet ? 24 : 20,
              ),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.add, size: 20),
              label: Text('Add Day'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              .map((entry) => _timelineDayCard(entry.key, entry.value, theme, colorScheme, isTablet))
              .toList(),
        ),
      ],
    );
  }

  // बाकी सभी methods same रहेंगे...
  Widget _buildDestinationHeader(Map<String, dynamic> data, ColorScheme colorScheme, bool isTablet) {
    final destination = data['destination'] ?? 'No destination';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.primaryContainer]),
        borderRadius: BorderRadius.circular(isTablet ? 28 : 20),
        boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.4), blurRadius: isTablet ? 40 : 25, offset: Offset(0, isTablet ? 20 : 12))],
      ),
      child: Row(children: [
        Container(padding: EdgeInsets.all(isTablet ? 16 : 12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: Icon(Icons.location_on, color: Colors.white, size: isTablet ? 28 : 24)),
        SizedBox(width: isTablet ? 20 : 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(destination, style: TextStyle(color: Colors.white, fontSize: isTablet ? 28 : 24, fontWeight: FontWeight.bold)),
          Text('Tap days below to edit timeline', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: isTablet ? 16 : 14)),
        ])),
      ]),
    );
  }

  Widget _buildInfoCards(Map<String, dynamic> data, ThemeData theme, ColorScheme colorScheme, bool isTablet) {
    return Column(children: [
      Row(children: [Expanded(child: _infoCard('🗓️ Start Date', _formatDate(data['startDate']), Icons.calendar_today, colorScheme, isTablet)), SizedBox(width: isTablet ? 16 : 12), Expanded(child: _infoCard('🗓️ End Date', _formatDate(data['endDate']), Icons.event, colorScheme, isTablet))]),
      SizedBox(height: isTablet ? 16 : 12),
      Row(children: [Expanded(child: _infoCard('📊 Status', (data['status'] ?? 'DRAFT').toUpperCase(), Icons.flag, colorScheme, isTablet)), SizedBox(width: isTablet ? 16 : 12), Expanded(child: _infoCard('👥 Type', data['travelerType'] ?? 'Solo', Icons.people_outline, colorScheme, isTablet))]),
      SizedBox(height: isTablet ? 16 : 12),
      _infoCard('👥 Travelers', '${data['travelerCount'] ?? 0}', Icons.group, colorScheme, isTablet, isFullWidth: true),
    ]);
  }

  Widget _infoCard(String label, String value, IconData icon, ColorScheme colorScheme, bool isTablet, {bool isFullWidth = false}) {
    return Container(width: isFullWidth ? double.infinity : null, padding: EdgeInsets.all(isTablet ? 24 : 20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(isTablet ? 20 : 16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: Offset(0, 8))]), child: Row(children: [Container(padding: EdgeInsets.all(isTablet ? 12 : 10), decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: colorScheme.primary, size: isTablet ? 22 : 20)), SizedBox(width: isTablet ? 16 : 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize: isTablet ? 14 : 13, color: Colors.grey.shade600)), SizedBox(height: 4), Text(value, style: TextStyle(fontSize: isTablet ? 18 : 16, fontWeight: FontWeight.bold))]))]));
  }

  Widget _timelineDayCard(int index, dynamic dayData, ThemeData theme, ColorScheme colorScheme, bool isTablet) {
    final day = dayData['day'] ?? index + 1;
    final title = dayData['title'] ?? 'Untitled Day';
    final time = dayData['time'] ?? '09:00';
    final location = dayData['location'] ?? 'TBD';
    return GestureDetector(onTap: () => _showDayDialog(editIndex: index, editData: dayData), child: Container(margin: EdgeInsets.only(bottom: isTablet ? 20 : 16), padding: EdgeInsets.all(isTablet ? 24 : 20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(isTablet ? 24 : 20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: Offset(0, 8))]), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: isTablet ? 60 : 50, height: isTablet ? 60 : 50, decoration: BoxDecoration(gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.primaryContainer]), borderRadius: BorderRadius.circular(16)), child: Center(child: Text('Day $day', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isTablet ? 16 : 14)))), SizedBox(width: isTablet ? 20 : 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)), SizedBox(height: 4), Text('$time • $location', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600)), SizedBox(height: 8), Text(dayData['description'] ?? '', style: TextStyle(height: 1.4))]))])));
  }

  Widget _emptyTimeline(ThemeData theme, ColorScheme colorScheme, bool isTablet) {
    return Container(width: double.infinity, padding: EdgeInsets.all(isTablet ? 48 : 40), decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(isTablet ? 24 : 20), border: Border.all(color: Colors.grey.shade200)), child: Column(children: [Icon(Icons.timeline, size: isTablet ? 64 : 56, color: Colors.grey.shade400), SizedBox(height: 16), Text('No days added yet', style: theme.textTheme.titleLarge?.copyWith(color: Colors.grey.shade600)), SizedBox(height: 8), Text('Click "Add Day" to start planning your trip', style: TextStyle(color: Colors.grey.shade500))]));
  }

  Widget _buildActionBar(ThemeData theme, ColorScheme colorScheme, bool isTablet) {
    return Container(padding: EdgeInsets.all(isTablet ? 20 : 16), decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: Offset(0, -5))]), child: Row(children: [Expanded(child: _actionButton(Icons.person_add, 'Add Travelers', Colors.green.shade400, () => _navigate('/add-traveler'))), SizedBox(width: 12), Expanded(child: _actionButton(Icons.smart_toy, 'AI Chat', Colors.blue.shade400, () => _navigate('/ai-chat'))), SizedBox(width: 12), Expanded(child: _actionButton(Icons.notifications_active, 'Notify', Colors.orange.shade400, () => _navigate('/notifications')))]));
  }

  Widget _actionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20), decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(0.2), color.withOpacity(0.1)]), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 24), SizedBox(width: 8), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold))])));
  }

  void _showDayDialog({int? editIndex, Map<String, dynamic>? editData}) {
    final controllers = {
      'day': TextEditingController(text: editData?['day']?.toString() ?? ''),
      'title': TextEditingController(text: editData?['title'] ?? ''),
      'time': TextEditingController(text: editData?['time'] ?? '09:00'),
      'location': TextEditingController(text: editData?['location'] ?? ''),
      'description': TextEditingController(text: editData?['description'] ?? ''),
    };

    showDialog(context: context, builder: (context) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), title: Text(editData != null ? 'Edit Day' : 'Add Day'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: controllers.entries.map((entry) => Padding(padding: EdgeInsets.only(bottom: 16), child: TextFormField(controller: entry.value, decoration: InputDecoration(labelText: entry.key.toUpperCase(), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: Icon(Icons.edit))))).toList())), actions: [if (editIndex != null) TextButton(onPressed: () => _deleteDay(editIndex, controllers), child: Text('Delete', style: TextStyle(color: Colors.red))), TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')), ElevatedButton(onPressed: () => _saveDay(editIndex, controllers), child: Text(editData != null ? 'Update' : 'Add'))])).then((_) => controllers.values.forEach((c) => c.dispose()));
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
    Navigator.pushNamed(context, route, arguments: {'id': widget.itinerary['_id']?.toString() ?? '', 'title': _titleController.text});
  }

  Future<bool> _showConfirmDialog(String message) async {
    return await showDialog(context: context, builder: (context) => AlertDialog(title: Text('Confirm'), content: Text(message), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')), TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete'))])) ?? false;
  }

  void _handlePopupAction(String action, Map<String, dynamic> data) {
    switch (action) {
      case 'delete':
        _showConfirmDialog('Delete "${data['title']}"?').then((confirmed) {
          if (confirmed) Navigator.pop(context);
        });
        break;
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
