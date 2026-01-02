import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'reset_password_screen.dart';
import '../models/otp_type.dart';
import '../api/api_service.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OTPVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen>
    with TickerProviderStateMixin {
  List<TextEditingController> _otpControllers =
  List.generate(6, (_) => TextEditingController());
  bool isLoading = false;
  int _seconds = 60;
  bool _canResend = false;
  late Timer _timer;
  late AnimationController _animationController;
  late Animation<double> _shakeAnimation;
  late FocusNode _otpFocusNode; // ✅ Added FocusNode

  @override
  void initState() {
    super.initState();
    _otpFocusNode = FocusNode(); // ✅ Initialize
    _startTimer();
    _initAnimations();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  void _startTimer() {
    _canResend = false;
    _seconds = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds > 0) {
        setState(() => _seconds--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  Future<void> _resendOTP() async {
    try {
      print('🔥 RESEND PHONE OTP: ${widget.phoneNumber}');
      await ApiService.post('auth/send-otp', {
        'type': 'phone',
        'value': widget.phoneNumber,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔄 New OTP sent to SMS!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      _startTimer();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to resend: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> verifyOTP() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      _shakeError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter complete 6-digit OTP"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      print('🔥 VERIFY OTP: $otp for ${widget.phoneNumber}');
      final response = await ApiService.post('auth/verify-otp', {
        'value': widget.phoneNumber,
        'otp': otp,
      });

      print('✅ VERIFY RESPONSE: $response');

      if (response['status'] == true) {
        _animationController.forward().then((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ResetPasswordScreen(phoneNumber: widget.phoneNumber),
            ),
          );
        });
      } else {
        _shakeError();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Invalid OTP'),
            backgroundColor: Colors.red,
          ),
        );
        _clearOTP();
      }
    } catch (e) {
      _shakeError();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Network error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _shakeError() {
    _animationController.forward().then((_) => _animationController.reverse());
  }

  void _clearOTP() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
    FocusScope.of(context).requestFocus(FocusNode());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1024;
    final isSmallPhone = screenWidth < 360;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_shakeAnimation.value * 0.5, 0),
            child: Container(
              height: MediaQuery.of(context).size.height,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.primaryContainer],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallPhone ? 16 : 28,
                        vertical: isTablet ? 64 : 48,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // PHONE ICON
                          Container(
                            padding: EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.green.shade400, Colors.green.shade600],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.4),
                                  blurRadius: 35,
                                  offset: Offset(0, 15),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.sms_outlined,
                              size: isDesktop ? 100 : 80,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 32),

                          // TITLE
                          Text(
                            'Verify Phone OTP',
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontSize: isDesktop ? 38 : 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'Enter 6-digit code sent to SMS\n${widget.phoneNumber}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colorScheme.onPrimary.withOpacity(0.9),
                                fontSize: 17,
                                height: 1.4,
                              ),
                            ),
                          ),
                          SizedBox(height: 48),

                          // OTP INPUTS
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(6, (index) =>
                                _buildOTPDigitField(index, theme, colorScheme)),
                          ),
                          SizedBox(height: 32),

                          // PROGRESS
                          _buildProgress(theme, colorScheme),
                          SizedBox(height: 48),

                          // VERIFY BUTTON
                          _buildVerifyButton(theme, colorScheme),
                          SizedBox(height: 32),

                          // RESEND TIMER
                          _buildResendSection(theme, colorScheme),
                          SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOTPDigitField(int index, ThemeData theme, ColorScheme colorScheme) {
    final controller = _otpControllers[index];
    final isFilled = controller.text.isNotEmpty;
    final filledCount = _otpControllers.take(index).where((c) => c.text.isNotEmpty).length;
    final isActive = filledCount == index && controller.text.isEmpty;

    return Expanded(
      child: GestureDetector(
        // ✅ FIXED: Simple FocusNode without invalid parameter
        onTap: () {
          final node = FocusNode();
          FocusScope.of(context).requestFocus(node);
        },
        child: Container(
          height: 80,
          margin: EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                isActive ? Colors.green.shade100 : Colors.transparent,
                colorScheme.surfaceVariant.withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? Colors.green : colorScheme.outline.withOpacity(0.5),
              width: isActive ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isActive ? Colors.green.withOpacity(0.2) : Colors.transparent,
                blurRadius: 15,
                offset: Offset(0, 6),
              )
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isFilled ? Colors.green.shade700 : colorScheme.onSurface,
            ),
            maxLength: 1,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              counterText: '',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) {
              if (value.length == 1) {
                if (index < 5) {
                  FocusScope.of(context).nextFocus();
                } else {
                  verifyOTP();
                }
              } else if (value.isEmpty && index > 0) {
                FocusScope.of(context).previousFocus();
                _otpControllers[index - 1].clear();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProgress(ThemeData theme, ColorScheme colorScheme) {
    final filledCount = _otpControllers.where((c) => c.text.isNotEmpty).length;
    return Column(
      children: [
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.4),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            widthFactor: filledCount / 6.0,
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.green.shade400, Colors.green.shade600]),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        SizedBox(height: 12),
        Text(
          filledCount == 6 ? 'Perfect! Ready to verify' : '${6 - filledCount} digits left',
          style: TextStyle(
            color: filledCount == 6 ? Colors.green.shade700 : colorScheme.onSurfaceVariant,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyButton(ThemeData theme, ColorScheme colorScheme) {
    final isComplete = _otpControllers.every((c) => c.text.isNotEmpty);
    return SizedBox(
      width: double.infinity,
      height: 70,
      child: ElevatedButton(
        onPressed: isComplete && !isLoading ? verifyOTP : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isComplete && !isLoading ? Colors.green.shade600 : Colors.grey.shade400,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: isComplete && !isLoading ? 12 : 0,
          shadowColor: Colors.green.withOpacity(0.4),
        ),
        child: isLoading
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Verifying...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified, size: 24),
            SizedBox(width: 12),
            Text('Verify OTP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildResendSection(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _canResend ? "Didn't receive?" : "Resend OTP in ",
          style: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.8)),
        ),
        if (!_canResend)
          Text('$_seconds s', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
        if (_canResend)
          GestureDetector(
            onTap: _resendOTP,
            child: Text(
              'Resend OTP',
              style: TextStyle(
                color: Colors.green.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _animationController.dispose();
    _otpFocusNode.dispose(); // ✅ Dispose FocusNode
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
