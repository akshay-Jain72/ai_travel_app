import 'package:flutter/material.dart';
import '../api/api_service.dart';

class AIChatScreen extends StatefulWidget {
  final String itineraryId;
  final String itineraryTitle;

  const AIChatScreen({
    Key? key,
    required this.itineraryId,
    required this.itineraryTitle,
  }) : super(key: key);

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> messages = [];
  bool _isLoading = false;
  late AnimationController _typingController;
  late Animation<double> _typingAnimation;

  Map<String, dynamic> tripContext = {
    'itineraryId': '',
    'title': '',
    'destination': 'Udaipur',
    'dates': 'Dec 2025',
    'hotels': ['Lake Pichola Hotel'],
    'flights': [],
    'activities': [],
    'emergencyContacts': [],
  };

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _typingAnimation = CurvedAnimation(
      parent: _typingController,
      curve: Curves.easeInOut,
    );

    tripContext['itineraryId'] = widget.itineraryId;
    tripContext['title'] = widget.itineraryTitle;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addSmartWelcomeMessages();
    });
  }

  void _addSmartWelcomeMessages() {
    messages.addAll([
      ChatMessage(
        text: '✈️ Welcome to your ${widget.itineraryTitle} Travel Assistant!',
        isUser: false,
        timestamp: DateTime.now(),
        type: MessageType.welcome,
      ),
      ChatMessage(
        text: 'I know your complete trip details:\n\n'
            '📍 **Destination**: Udaipur\n'
            '📅 **Dates**: Dec 2025\n'
            '🏨 **Hotel**: Lake Pichola Hotel\n\n'
            'Ask me anything! 💬\n\n'
            '• Flight status\n'
            '• Hotel check-in\n'
            '• Today weather\n'
            '• Restaurants\n'
            '• Emergency numbers',
        isUser: false,
        timestamp: DateTime.now(),
        type: MessageType.info,
      ),
    ]);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendAdvancedMessage() async {
    if (_messageController.text.trim().isEmpty || _isLoading) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    final messageType = _detectMessageIntent(userMessage.toLowerCase());

    setState(() {
      messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
        type: MessageType.user,
        intent: messageType,
      ));
      _isLoading = true;
    });

    _scrollToBottom();
    _typingController.repeat();

    try {
      final response = await ApiService.sendChatMessage(userMessage, widget.itineraryId);

      _typingController.stop();
      _typingController.reset();

      String aiResponse = response['status'] == true
          ? response['data']['message'] ?? 'Great question!'
          : 'Sorry, let me check that for you...';

      aiResponse = _enhanceResponse(aiResponse, messageType);

      setState(() {
        _isLoading = false;
        messages.add(ChatMessage(
          text: aiResponse,
          isUser: false,
          timestamp: DateTime.now(),
          type: MessageType.ai,
          intent: messageType,
        ));
      });
    } catch (e) {
      _typingController.stop();
      _typingController.reset();
      setState(() {
        _isLoading = false;
        messages.add(ChatMessage(
          text: '🌐 Offline mode active!\n\n'
              '✈️ Flight: Check airline app\n'
              '🏨 Hotel: Check-in 2 PM\n'
              '🚨 Police: 100 | Medical: 108\n\n'
              '💡 Connect internet for live AI!',
          isUser: false,
          timestamp: DateTime.now(),
          type: MessageType.error,
        ));
      });
    }

    _scrollToBottom();
  }

  String _detectMessageIntent(String message) {
    if (message.contains('flight') || message.contains('airport')) return 'flight';
    if (message.contains('hotel') || message.contains('check')) return 'hotel';
    if (message.contains('weather')) return 'weather';
    if (message.contains('food') || message.contains('restaurant')) return 'food';
    if (message.contains('emergency') || message.contains('police')) return 'emergency';
    return 'general';
  }

  String _enhanceResponse(String response, String intent) {
    switch (intent) {
      case 'flight':
        return '✈️ $response\n\n📞 Udaipur Airport: 0294-2451515';
      case 'hotel':
        return '🏨 $response\n\n🛎️ Check-in: 2 PM | Check-out: 11 AM';
      case 'emergency':
        return '🚨 EMERGENCY\n\n📱 **Numbers:**\n• Police: 100\n• Medical: 108\n• Fire: 101';
      case 'weather':
        return '🌤️ $response\n\n☔ Udaipur: Mostly sunny!';
      case 'food':
        return '🍽️ $response\n\n⭐ Millets on 14/4 City Palace Rd';
      default:
        return response;
    }
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 4,
              margin: EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Quick Travel Actions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildQuickActionButton('Flight Status', Icons.flight, 'Flight status?'),
                  _buildQuickActionButton('Weather', Icons.wb_sunny, 'Today weather'),
                  _buildQuickActionButton('Hotel Info', Icons.hotel, 'Hotel check-in time'),
                  _buildQuickActionButton('Restaurants', Icons.restaurant, 'Nearby restaurants'),
                  _buildQuickActionButton('Emergency', Icons.local_hospital, 'Emergency numbers'),
                  _buildQuickActionButton('Itinerary', Icons.map, 'Show my itinerary'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(String text, IconData icon, String query) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _messageController.text = query;
        _sendAdvancedMessage();
      },
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.primary),
            SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: colorScheme.surfaceVariant.withOpacity(0.05),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 14 : 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.primaryContainer]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.4), blurRadius: 20, offset: Offset(0, 8))],
              ),
              child: Icon(Icons.travel_explore, color: colorScheme.onPrimary, size: isTablet ? 30 : 26),
            ),
            SizedBox(width: isTablet ? 18 : 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🤖 Smart Travel AI', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: colorScheme.onPrimary)),
                  Text(widget.itineraryTitle, style: TextStyle(fontSize: isTablet ? 15 : 13, color: colorScheme.onPrimary.withOpacity(0.85), fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: colorScheme.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: colorScheme.onPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4.0),
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary.withOpacity(0.6), Colors.transparent],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(  // ✅ Navigation buttons के ऊपर input field
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(isTablet ? 28 : 20, isTablet ? 24 : 20, isTablet ? 28 : 20, 20),
                itemCount: messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == messages.length) return _buildTypingIndicator(theme, isTablet);
                  return _buildMessageBubble(messages[index], theme, isTablet);
                },
              ),
            ),
            _buildInputArea(theme, isTablet),
          ],
        ),
      ),
      floatingActionButton: Container(
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 80,  // ✅ FAB को ऊपर shift किया
          right: 16,
        ),
        child: FloatingActionButton.extended(
          onPressed: _showQuickActions,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 8,
          icon: Icon(Icons.flash_on_rounded),
          label: Text(
            'Quick Actions',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildMessageBubble(ChatMessage message, ThemeData theme, bool isTablet) {
    final colorScheme = theme.colorScheme;
    final isUserMsg = message.isUser;

    return Align(
      alignment: isUserMsg ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUserMsg) ...[
              Container(
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [colorScheme.primary.withOpacity(0.2), Colors.transparent]),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getMessageIcon(message.intent), color: colorScheme.primary, size: 24),
              ),
            ],
            Flexible(
              child: Container(
                padding: EdgeInsets.all(20),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isUserMsg
                        ? [colorScheme.primary, colorScheme.primaryContainer]
                        : [colorScheme.surfaceVariant.withOpacity(0.6), colorScheme.surface],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: Offset(0, 8))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(message.text, style: TextStyle(color: isUserMsg ? colorScheme.onPrimary : colorScheme.onSurface, fontSize: 17, height: 1.45, fontWeight: isUserMsg ? FontWeight.w600 : FontWeight.w500)),
                    SizedBox(height: 6),
                    Text(_formatTime(message.timestamp), style: TextStyle(fontSize: 13, color: isUserMsg ? colorScheme.onPrimary.withOpacity(0.7) : colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMessageIcon(String intent) {
    switch (intent) {
      case 'flight': return Icons.flight;
      case 'hotel': return Icons.hotel;
      case 'weather': return Icons.wb_sunny;
      case 'food': return Icons.restaurant;
      case 'emergency': return Icons.local_hospital;
      default: return Icons.travel_explore;
    }
  }

  Widget _buildTypingIndicator(ThemeData theme, bool isTablet) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [theme.colorScheme.surfaceVariant.withOpacity(0.6), theme.colorScheme.surface]),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: Offset(0, 6))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...List.generate(3, (i) => Container(
              width: 10, height: 10,
              margin: EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: (_typingAnimation.value > (i + 1) / 3.0) ? theme.colorScheme.primary : theme.colorScheme.primary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            )),
            SizedBox(width: 12),
            Text('AI Travel Assistant is thinking...', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 15, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme, bool isTablet) {
    final colorScheme = theme.colorScheme;
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colorScheme.surface, colorScheme.surfaceVariant.withOpacity(0.5)]),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: Offset(0, -8))],
      ),
      child: SafeArea(  // ✅ Input field को navigation buttons के ऊपर
        top: false,
        bottom: true,
        child: Row(
          children: [
            SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: colorScheme.outline.withOpacity(0.3), width: 1.5),
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                ),
                child: TextFormField(
                  controller: _messageController,
                  maxLines: null,
                  style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Ask about flights, hotels, weather...',
                    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    prefixIcon: Icon(Icons.travel_explore, color: colorScheme.primary.withOpacity(0.8)),
                  ),
                  onFieldSubmitted: (_) => _sendAdvancedMessage(),
                ),
              ),
            ),
            SizedBox(width: 12),
            GestureDetector(
              onTap: _sendAdvancedMessage,
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.primaryContainer]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.5), blurRadius: 20, offset: Offset(0, 12))],
                ),
                child: Icon(Icons.send_rounded, color: colorScheme.onPrimary, size: 26),
              ),
            ),
            SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingController.dispose();
    super.dispose();
  }
}

// Data Models
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final MessageType type;
  final String intent;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.type,
    this.intent = 'general',
  });
}

enum MessageType { user, ai, welcome, info, error }
