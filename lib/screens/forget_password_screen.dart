import 'package:flutter/material.dart';
import 'otp_verification_screen.dart';
import '../api/api_service.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final TextEditingController _inputController =
  TextEditingController(text: '+91 ');
  bool isLoading = false;

  // ---------------- PHONE INPUT CONTROL ----------------
  void _onPhoneChanged(String value) {
    if (!value.startsWith('+91')) {
      final cleanNumber = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanNumber.length <= 10) {
        _inputController.value = TextEditingValue(
          text: '+91 $cleanNumber',
          selection: TextSelection.collapsed(
            offset: '+91 '.length + cleanNumber.length,
          ),
        );
      }
    } else {
      final after91 = value.substring('+91 '.length);
      final cleanAfter = after91.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanAfter.length <= 10) {
        _inputController.value = TextEditingValue(
          text: '+91 $cleanAfter',
          selection: TextSelection.collapsed(
            offset: '+91 '.length + cleanAfter.length,
          ),
        );
      }
    }
  }

  // ---------------- FORMAT DISPLAY ----------------
  String _formatPhoneNumber(String phone) {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length >= 12) {
      final number = clean.substring(2);
      return '+91 ${number.substring(0, 5)} ${number.substring(5)}';
    }
    return phone;
  }

  // ---------------- SEND OTP ----------------
  Future<void> sendOTP() async {
    final phone = _inputController.text.trim();
    final cleanDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');

    String finalNumber = '';

    if (cleanDigits.startsWith('91') && cleanDigits.length == 12) {
      finalNumber = cleanDigits.substring(2);
    } else if (cleanDigits.length == 10) {
      finalNumber = cleanDigits;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter exactly 10 digit mobile number"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final formattedPhone = '+91$finalNumber';

    setState(() => isLoading = true);

    try {
      final response = await ApiService.post(
        'auth/send-otp',
        {
          'type': 'phone',
          'value': formattedPhone,
        },
      );

      if (response['status'] == true || response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ OTP sent successfully"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                OTPVerificationScreen(phoneNumber: formattedPhone),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? "Failed to send OTP"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Network error"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1024;
    final isSmallPhone = screenWidth < 360;

    final maxContentWidth =
    isDesktop ? 450.0 : isTablet ? 400.0 : 350.0;

    return Scaffold(
      body: Container(
        height: screenHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              colorScheme.primaryContainer,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxContentWidth,
                  minHeight: screenHeight * 0.8,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallPhone ? 16 : 24,
                    vertical: isTablet ? 60 : 40,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ICON
                      Container(
                        width: isDesktop
                            ? 120
                            : isTablet
                            ? 100
                            : 90,
                        height: isDesktop
                            ? 120
                            : isTablet
                            ? 100
                            : 90,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade400,
                              Colors.green.shade600,
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.4),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.phone_android,
                          color: Colors.white,
                          size: isDesktop
                              ? 70
                              : isTablet
                              ? 60
                              : 50,
                        ),
                      ),

                      const SizedBox(height: 24),

                      Text(
                        'Send OTP',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: isDesktop
                              ? 36
                              : isTablet
                              ? 32
                              : 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        _formatPhoneNumber(_inputController.text),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 36),

                      // INPUT
                      TextFormField(
                        controller: _inputController,
                        keyboardType: TextInputType.phone,
                        onChanged: _onPhoneChanged,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.phone_android,
                            color: colorScheme.primary,
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceVariant,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : sendOTP,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                              : const Text(
                            'Send OTP',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          '← Back to Login',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }
}
