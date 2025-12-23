import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'reset_password_screen.dart';
import '../models/otp_type.dart';
import '../api/api_service.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String emailOrPhone;
  final OTPType type;

  const OTPVerificationScreen({
    super.key,
    required this.emailOrPhone,
    required this.type,
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

  @override
  void initState() {
    super.initState();
    _startTimer();
    _initAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _otpControllers[0].text = '';
      FocusScope.of(context).requestFocus(FocusNode());
    });
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
      await ApiService.post('auth/send-otp', {
        'type': widget.type == OTPType.email ? 'email' : 'phone',
        'value': widget.emailOrPhone,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔄 New OTP sent!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      _startTimer(); // Restart timer
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
      final response = await ApiService.post('auth/verify-otp', {
        'value': widget.emailOrPhone,
        'otp': otp,
      });

      if (response['status'] == true) {
        _animationController.forward().then((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ResetPasswordScreen(emailOrPhone: widget.emailOrPhone),
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
    _otpControllers[0].text = '';
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
    final maxContentWidth = isDesktop ? 520.0 : isTablet ? 480.0 : 400.0;

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
                  colors: [
                    colorScheme.primary,
                    colorScheme.primaryContainer,
                    colorScheme.inversePrimary.withOpacity(0.8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: maxContentWidth,
                        minHeight: MediaQuery.of(context).size.height * 0.85,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallPhone ? 16.0 : 28.0,
                          vertical: isTablet ? 64.0 : 48.0,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // HERO ICON
                            Hero(
                              tag: 'otp_verified',
                              child: Container(
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      colorScheme.primary.withOpacity(0.25),
                                      Colors.white.withOpacity(0.15),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.primary.withOpacity(0.35),
                                      blurRadius: 35,
                                      offset: const Offset(0, 15),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.verified_outlined,
                                  size: isDesktop ? 120 : 100,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // TITLE
                            Text(
                              'Verify OTP',
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontSize: isDesktop ? 44 : 36,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                'Enter 6-digit code sent to ${widget.type == OTPType.email ? 'Email' : 'SMS'}\n${widget.emailOrPhone}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: colorScheme.onPrimary.withOpacity(0.9),
                                  fontSize: 17,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 56),

                            // OTP GLASS CARD
                            Container(
                              padding: EdgeInsets.all(isDesktop ? 56 : 44),
                              decoration: BoxDecoration(
                                color: colorScheme.surface.withOpacity(0.97),
                                borderRadius: BorderRadius.circular(36),
                                border: Border.all(
                                  color: colorScheme.primary.withOpacity(0.3),
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withOpacity(0.25),
                                    blurRadius: 60,
                                    offset: const Offset(0, 30),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // OTP FIELDS
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: List.generate(6, (index) =>
                                        _buildOTPDigitField(index, theme, colorScheme)),
                                  ),
                                  const SizedBox(height: 24),

                                  // PROGRESS + TIMER
                                  _buildProgressAndTimer(theme, colorScheme),
                                  const SizedBox(height: 48),

                                  // VERIFY BUTTON
                                  _buildVerifyButton(theme, colorScheme),
                                  const SizedBox(height: 32),

                                  // RESEND SECTION
                                  _buildResendSection(theme, colorScheme),
                                ],
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
      child: Container(
        height: 76,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              isActive ? colorScheme.primary.withOpacity(0.15) : Colors.transparent,
              colorScheme.surfaceVariant.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive ? colorScheme.primary : colorScheme.outline.withOpacity(0.4),
            width: isActive ? 3 : 2,
          ),
        ),
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofillHints: const [AutofillHints.oneTimeCode],
          decoration: const InputDecoration(
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
    );
  }

  Widget _buildProgressAndTimer(ThemeData theme, ColorScheme colorScheme) {
    final filledCount = _otpControllers.where((c) => c.text.isNotEmpty).length;
    return Column(
      children: [
        // Progress Bar
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.4),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            widthFactor: filledCount / 6.0,
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.primaryContainer]),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Status Text
        Text(
          filledCount == 6 ? 'Perfect! Ready to verify' : 'Enter ${6 - filledCount} more digits',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: filledCount == 6 ? colorScheme.primary : colorScheme.onSurfaceVariant,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyButton(ThemeData theme, ColorScheme colorScheme) {
    final isComplete = _otpControllers.every((c) => c.text.isNotEmpty);
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isComplete && !isLoading
              ? [colorScheme.primary, colorScheme.primaryContainer]
              : [colorScheme.onSurfaceVariant.withOpacity(0.4), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: isComplete && !isLoading ? colorScheme.primary.withOpacity(0.4) : Colors.transparent,
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(32),
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: isComplete && !isLoading ? verifyOTP : null,
          child: Center(
            child: isLoading
                ? CircularProgressIndicator(strokeWidth: 4, color: colorScheme.onPrimary)
                : Text(
              'Verify OTP',
              style: TextStyle(
                color: isComplete ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResendSection(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _canResend ? "Didn't receive?" : "Resend in ",
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        if (!_canResend) Text('$_seconds', style: TextStyle(fontWeight: FontWeight.bold)),
        if (_canResend)
          TextButton.icon(
            onPressed: _resendOTP,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Resend', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _animationController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
