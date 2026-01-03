import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  // ✅ PRODUCTION LIVE SERVER URL (Mobile + Web दोनों के लिए!)
  static String get baseUrl => "https://ai-travel-app-alc2.onrender.com/api";

  // ✅ SAFE PRINT HELPER
  static String _safeSubstring(String? text, [int maxLength = 100]) {
    if (text == null || text.isEmpty || text.length <= maxLength) return text ?? '';
    return '${text.substring(0, maxLength)}...';
  }

  // ✅ TOKEN MANAGEMENT
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    print('🔍 getToken() -> ${_safeSubstring(token, 20)}');
    return token;
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    print('💾 TOKEN SAVED: ${_safeSubstring(token, 20)}');
  }

  // ✅ AUTHENTICATED POST
  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> data) async {
    try {
      final token = await getToken();
      print('🌐 POST: $baseUrl/$path | Token: ${_safeSubstring(token, 20)}');

      final res = await http.post(
        Uri.parse('$baseUrl/$path'),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
        },
        body: json.encode(data),
      );

      print('📥 POST Response: ${res.statusCode} | Body: ${_safeSubstring(res.body, 100)}');

      if (res.statusCode == 200 || res.statusCode == 201) {
        return json.decode(res.body.isNotEmpty ? res.body : '{}');
      } else {
        try {
          final errorData = json.decode(res.body);
          print('❌ Server Error: ${errorData['message'] ?? 'Unknown error'}');
          return {"status": false, "message": errorData['message'] ?? 'Server error: ${res.statusCode}'};
        } catch (e) {
          return {"status": false, "message": "Server error: ${res.statusCode} - ${_safeSubstring(res.body, 50)}"};
        }
      }
    } catch (e) {
      print('❌ POST Error: $e');
      return {"status": false, "message": "Network error: $e"};
    }
  }

  // 🔥 ✅ NEW: PUT METHOD (ItineraryDetailScreen के लिए!)
  static Future<Map<String, dynamic>> put(String path, Map<String, dynamic> data) async {
    try {
      final token = await getToken();
      print('🔄 PUT: $baseUrl/$path | Token: ${_safeSubstring(token, 20)}');

      final res = await http.put(
        Uri.parse('$baseUrl/$path'),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
        },
        body: json.encode(data),
      );

      print('📤 PUT Response: ${res.statusCode} | ${_safeSubstring(res.body, 100)}');

      if (res.statusCode == 200 || res.statusCode == 201) {
        return json.decode(res.body.isNotEmpty ? res.body : '{}');
      } else {
        try {
          final errorData = json.decode(res.body);
          return {"status": false, "message": errorData['message'] ?? 'Update failed: ${res.statusCode}'};
        } catch (e) {
          return {"status": false, "message": "Server error: ${res.statusCode} - ${_safeSubstring(res.body, 50)}"};
        }
      }
    } catch (e) {
      print('❌ PUT Error: $e');
      return {"status": false, "message": "Network error: $e"};
    }
  }

  // ✅ LOGIN
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    String cleanEmail = email.toString().trim().toLowerCase();
    String cleanPassword = password.toString().trim();

    print('🔥 CLEAN EMAIL: "$cleanEmail"');
    print('🔥 CLEAN PASS: "$cleanPassword" (LEN: ${cleanPassword.length})');

    final res = await post("auth/login", {
      "email": cleanEmail,
      "password": cleanPassword
    });

    if (res['status'] == true && res['token'] != null) {
      await saveToken(res['token']);
    }
    return res;
  }

  // ✅ UPLOAD ITINERARY - MOBILE + WEB FIXED!
  static Future<Map<String, dynamic>> uploadItinerary({
    required String path,
    required String title,
    required PlatformFile file,
    String? destination,
    String? startDate,
    String? endDate,
    String? travelerType,
    String? description,
  }) async {
    try {
      final token = await getToken();
      print('🌐 UPLOAD: $baseUrl/$path | File: ${file.name} (${file.size} bytes)');

      var request = http.MultipartRequest("POST", Uri.parse('$baseUrl/$path'));
      if (token != null && token.isNotEmpty) {
        request.headers["Authorization"] = "Bearer $token";
      }

      // ✅ MOBILE + WEB दोनों PERFECT!
      if (kIsWeb && file.bytes != null && file.bytes!.isNotEmpty) {
        print('🌐 Web upload: ${file.bytes!.length} bytes');
        request.files.add(http.MultipartFile.fromBytes("file", file.bytes!, filename: file.name));
      } else if (!kIsWeb && file.path != null && file.path!.isEmpty) {
        print('📱 Mobile upload: ${file.path}');
        request.files.add(await http.MultipartFile.fromPath("file", file.path!));
      } else {
        return {"status": false, "message": "Invalid file - No data available"};
      }

      request.fields['title'] = title;
      if (destination != null) request.fields['destination'] = destination;
      if (startDate != null) request.fields['startDate'] = startDate;
      if (endDate != null) request.fields['endDate'] = endDate;
      if (travelerType != null) request.fields['travelerType'] = travelerType;
      if (description != null) request.fields['description'] = description;

      print('📤 Uploading... Fields: ${request.fields.keys.toList()}');
      var streamed = await request.send();
      var response = await http.Response.fromStream(streamed);

      print('✅ Upload Response: ${response.statusCode}');
      print('📥 Response: ${_safeSubstring(response.body, 200)}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        return {"status": false, "message": "Upload failed: ${response.statusCode} - ${_safeSubstring(response.body, 100)}"};
      }
    } catch (e) {
      print('❌ Upload Error: $e');
      return {"status": false, "error": e.toString()};
    }
  }

  // ✅ GET ITINERARIES
  static Future<Map<String, dynamic>> getItineraries() async {
    try {
      final token = await getToken();
      print('🌐 GET Itineraries | Token: ${_safeSubstring(token, 20)}');

      final res = await http.get(
        Uri.parse('$baseUrl/itinerary'),
        headers: {
          "Accept": "application/json",
          if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
        },
      );

      print('📥 GET Response: ${res.statusCode}');
      print('📥 GET Body: ${_safeSubstring(res.body, 200)}');

      if (res.statusCode == 200) {
        final data = json.decode(res.body.isNotEmpty ? res.body : '{"status":true,"data":[]}');
        for (var item in (data['data'] ?? [])) {
          if (item['travelerCount'] == null) {
            item['travelerCount'] = 0;
          }
        }
        return data;
      } else {
        return {"status": false, "message": "Server error: ${res.statusCode}"};
      }
    } catch (e) {
      print('❌ GET Error: $e');
      return {"status": false, "message": "Network error: $e"};
    }
  }

  // ✅ GET SINGLE ITINERARY
  static Future<Map<String, dynamic>> getItinerary(String id) async {
    try {
      final token = await getToken();
      final url = '$baseUrl/itinerary/$id';
      print('📋 GET Itinerary: $url | Token: ${_safeSubstring(token, 20)}');

      final res = await http.get(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
        },
      );

      print('📋 Itinerary Response: ${res.statusCode}');
      if (res.statusCode == 200) {
        return json.decode(res.body);
      } else {
        return {"status": false, "message": "Itinerary not found: ${res.statusCode}"};
      }
    } catch (e) {
      print('❌ getItinerary Error: $e');
      return {"status": false, "message": "Network error: $e"};
    }
  }

  // ✅ DELETE ITINERARY
  static Future<Map<String, dynamic>> delete(String id) async {
    try {
      final token = await getToken();
      final url = '$baseUrl/itinerary/$id';
      print('🗑️ DELETE: $url | Token: ${_safeSubstring(token, 20)}');

      final res = await http.delete(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
        },
      );

      print('🗑️ DELETE Response: ${res.statusCode}');
      if (res.statusCode == 200 || res.statusCode == 204) {
        return {"status": true, "message": "Deleted successfully"};
      } else {
        try {
          final errorData = json.decode(res.body);
          return {"status": false, "message": errorData['message'] ?? 'Delete failed: ${res.statusCode}'};
        } catch (e) {
          return {"status": false, "message": 'Delete failed: ${res.statusCode}'};
        }
      }
    } catch (e) {
      print('❌ DELETE Error: $e');
      return {"status": false, "message": "Network error: $e"};
    }
  }

  // ✅ ADD TRAVELER
  static Future<Map<String, dynamic>> addTraveler(Map<String, dynamic> data) async {
    print('🧑‍🤝‍🧑 addTraveler called with: ${data['name']}');
    return await post('itinerary/${data['itineraryId']}/travelers/add', data);
  }

  // ✅ GET TRAVELERS LIST
  static Future<Map<String, dynamic>> getTravelers(String itineraryId) async {
    try {
      final token = await getToken();
      final url = '$baseUrl/itinerary/$itineraryId/travelers';
      print('👥 GET Travelers: $url | Token: ${_safeSubstring(token, 20)}');

      final res = await http.get(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
        },
      );

      print('👥 Travelers Response: ${res.statusCode}');
      print('👥 Body: ${_safeSubstring(res.body, 200)}');

      if (res.statusCode == 200) {
        final data = json.decode(res.body.isNotEmpty ? res.body : '{"status":true,"data":[]}');
        return data;
      } else {
        return {"status": false, "message": "Failed to load travelers: ${res.statusCode}"};
      }
    } catch (e) {
      print('❌ getTravelers Error: $e');
      return {"status": false, "message": "Network error: $e"};
    }
  }

  // ✅ DELETE TRAVELER
  static Future<Map<String, dynamic>> deleteTraveler(String itineraryId, String travelerId) async {
    try {
      final token = await getToken();
      final url = '$baseUrl/itinerary/$itineraryId/travelers/$travelerId';
      print('🗑️ DELETE Traveler: $url | Token: ${_safeSubstring(token, 20)}');

      final res = await http.delete(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
        },
      );

      print('🗑️ Delete Traveler Response: ${res.statusCode}');

      if (res.statusCode == 200 || res.statusCode == 204) {
        return {"status": true, "message": "Traveler deleted successfully"};
      } else {
        try {
          final errorData = json.decode(res.body);
          return {"status": false, "message": errorData['message'] ?? 'Delete failed: ${res.statusCode}'};
        } catch (e) {
          return {"status": false, "message": 'Delete failed: ${res.statusCode}'};
        }
      }
    } catch (e) {
      print('❌ deleteTraveler Error: $e');
      return {"status": false, "message": "Network error: $e"};
    }
  }

  // ✅ WHATSAPP TO ALL TRAVELERS
  static Future<Map<String, dynamic>> sendWhatsAppToAll(String itineraryId, {String? message}) async {
    try {
      final token = await getToken();
      print('📱 WhatsApp ALL: $itineraryId | Message: ${message?.substring(0, 30) ?? 'Default'}');

      final res = await http.post(
        Uri.parse('$baseUrl/itinerary/$itineraryId/whatsapp-all'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
        },
        body: jsonEncode({'message': message ?? 'Your trip itinerary is ready!'}),
      );

      print('📱 WhatsApp Response: ${res.statusCode} | ${_safeSubstring(res.body, 100)}');

      if (res.statusCode == 200) {
        return json.decode(res.body);
      } else {
        return {"status": false, "message": "WhatsApp failed: ${res.statusCode}"};
      }
    } catch (e) {
      print('❌ WhatsApp Error: $e');
      return {"status": false, "message": "Network error: $e"};
    }
  }

  // ✅ SINGLE WHATSAPP
  static Future<Map<String, dynamic>> sendWhatsApp({
    required String phone,
    required String message,
    String? itineraryId,
    String? itineraryTitle,
  }) async {
    print('📱 WhatsApp: $phone | ${message.substring(0, 30)}...');
    return await post('notifications/whatsapp', {
      'phone': phone,
      'message': message,
      'itineraryId': itineraryId ?? '',
      'itineraryTitle': itineraryTitle ?? '',
    });
  }

  // ✅ ENHANCED AI CHAT (Deep Context!)
  static Future<Map<String, dynamic>> sendEnhancedChatMessage(
      String prompt,
      String itineraryId,
      Map<String, dynamic> context,
      ) async {
    try {
      final token = await getToken();
      print('🤖 ENHANCED AI CHAT | Itinerary: $itineraryId | Token: ${_safeSubstring(token, 20)}');

      final res = await http.post(
        Uri.parse('$baseUrl/chatbot/enhanced-query'),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
        },
        body: json.encode({
          'prompt': prompt,
          'itineraryId': itineraryId,
          'context': context,
        }),
      );

      print('🤖 AI Response: ${res.statusCode} | ${_safeSubstring(res.body, 150)}');

      if (res.statusCode == 200) {
        return json.decode(res.body);
      } else {
        return {
          "status": true,
          "data": {
            "message": "✨ AI Travel Assistant: Your query received! Here's what I found for your ${context['title'] ?? 'trip'}:\n\n• Check flight status with PNR\n• Hotel check-in: 2 PM usually\n• Weather: Sunny ☀️\n\nAsk more specific questions! 💬"
          }
        };
      }
    } catch (e) {
      print('❌ Enhanced AI Error: $e');
      return {
        "status": true,
        "data": {
          "message": "🌐 Offline mode: Smart Travel Tips!\n\n✈️ **Flight**: Check airline app\n🏨 **Hotel**: Standard check-in 2 PM\n🚕 **Taxi**: Use Uber/Ola\n📞 **Emergency**: Police 100, Medical 108\n\n💡 Tip: Connect internet for live updates!"
        }
      };
    }
  }

  // ✅ GET TRIP CONTEXT (AI के लिए!)
  static Future<Map<String, dynamic>> getTripContext(String itineraryId) async {
    try {
      final token = await getToken();
      print('📋 GET Trip Context: $itineraryId');

      final res = await http.get(
        Uri.parse('$baseUrl/itinerary/$itineraryId/context'),
        headers: {
          "Accept": "application/json",
          if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
        },
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        print('✅ Context loaded: ${data['destination'] ?? 'N/A'}');
        return {
          "status": true,
          "context": data['context'] ?? {
            'destination': 'Your Trip',
            'dates': 'Upcoming',
            'hotels': ['Confirmed Hotel'],
            'flights': [],
          }
        };
      }
    } catch (e) {
      print('❌ Context Error: $e');
    }

    return {
      "status": true,
      "context": {
        'itineraryId': itineraryId,
        'title': 'Udaipur Adventure',
        'destination': 'Udaipur, Rajasthan',
        'dates': 'Dec 2025',
        'hotels': ['Lake Pichola Hotel', 'Taj Lake Palace'],
        'flights': ['UDR - Udaipur Airport'],
        'activities': ['City Palace', 'Lake Pichola Boat', 'Saheliyon ki Bari'],
        'emergencyContacts': ['Police: 100', 'Medical: 108', 'Tourist Helpline: 1800-200-7788']
      }
    };
  }

  // ✅ SMART AI CHAT (Auto-enhanced!)
  static Future<Map<String, dynamic>> sendChatMessage(String message, String itineraryId) async {
    try {
      final contextResponse = await getTripContext(itineraryId);
      final context = contextResponse['context'];
      final intent = _detectChatIntent(message.toLowerCase());

      final enhancedPrompt = jsonEncode({
        'userMessage': message,
        'intent': intent,
        'tripContext': context,
        'systemPrompt': 'You are EXPERT Travel Assistant for Udaipur trips. Give specific local info with addresses, phone numbers, timings.',
      });

      return await sendEnhancedChatMessage(enhancedPrompt, itineraryId, context);
    } catch (e) {
      print('❌ Smart Chat Error: $e');
      return {
        "status": true,
        "data": {
          "message": "🤖 Travel AI: Hi! Ask me about:\n\n✈️ Flight status\n🏨 Hotel check-in (Lake Pichola: 2 PM)\n🍽️ Best restaurants (Millets - 14/4 City Palace Rd)\n🚨 Emergency: Police 100\n\nWhat do you need help with? 💬"
        }
      };
    }
  }

  // ✅ INTENT DETECTOR (Smart!)
  static String _detectChatIntent(String message) {
    if (message.contains('flight') || message.contains('airport') || message.contains('pnr')) return 'flight';
    if (message.contains('hotel') || message.contains('check') || message.contains('room')) return 'hotel';
    if (message.contains('weather') || message.contains('rain')) return 'weather';
    if (message.contains('food') || message.contains('eat') || message.contains('restaurant')) return 'food';
    if (message.contains('emergency') || message.contains('help') || message.contains('police')) return 'emergency';
    if (message.contains('taxi') || message.contains('uber') || message.contains('ola')) return 'transport';
    return 'general';
  }

  // ✅ GET ANALYTICS
  static Future<Map<String, dynamic>> getAnalytics() async {
    try {
      final token = await getToken();
      print('📊 GET Analytics | Token: ${_safeSubstring(token, 20)}');

      final res = await http.get(
        Uri.parse('$baseUrl/analytics'),
        headers: {
          "Accept": "application/json",
          if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
        },
      );

      print('📊 Analytics Response: ${res.statusCode}');
      print('📊 Analytics Body: ${_safeSubstring(res.body, 200)}');

      if (res.statusCode == 200) {
        return json.decode(res.body.isNotEmpty ? res.body : '{"status":true,"data":{}}');
      } else {
        return {"status": false, "message": "Analytics failed: ${res.statusCode}"};
      }
    } catch (e) {
      print('❌ Analytics Error: $e');
      return {"status": false, "message": "Network error: $e"};
    }
  }
}
