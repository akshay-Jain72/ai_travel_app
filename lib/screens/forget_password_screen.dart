import 'package:flutter/material.dart';
import '../models/otp_type.dart';
import 'otp_verification_screen.dart';
import '../api/api_service.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final TextEditingController _inputController = TextEditingController();
  OTPType? _selectedType;
  bool isLoading = false;

  Future<void> sendOTP() async {
    final OTPType? type = _selectedType;

    if (type == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Select Email or Phone"), backgroundColor: Colors.orange)
      );
      return;
    }
    if (_inputController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enter Email/Phone"), backgroundColor: Colors.orange)
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await ApiService.post('auth/send-otp', {
        'type': type == OTPType.email ? 'email' : 'phone',
        'value': _inputController.text.trim(),
      });

      if (response['status'] == true || response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ OTP sent successfully!"), backgroundColor: Colors.green)
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OTPVerificationScreen(
              emailOrPhone: _inputController.text.trim(),
              type: type,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? "Failed"), backgroundColor: Colors.red)
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Network error: $e"), backgroundColor: Colors.red)
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1024;
    final isSmallPhone = screenWidth < 360;
    final maxContentWidth = isDesktop ? 500.0 : isTablet ? 450.0 : 380.0;

    return Scaffold(
      body: Container(
        height: screenHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.primary, colorScheme.primaryContainer, colorScheme.inversePrimary],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth, minHeight: screenHeight * 0.8),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: isSmallPhone ? 16.0 : 24.0, vertical: isTablet ? 60.0 : 40.0),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Hero(tag: 'reset_lock', child: Icon(Icons.lock_reset, size: isDesktop ? 100 : isTablet ? 92 : isSmallPhone ? 72 : 84, color: colorScheme.onPrimary.withOpacity(0.95), shadows: [Shadow(color: Colors.black26, offset: const Offset(0, 4), blurRadius: 12)])),
                      SizedBox(height: isTablet ? 28 : 24),
                      Text('Reset Password', textAlign: TextAlign.center, style: TextStyle(color: colorScheme.onPrimary, fontSize: isDesktop ? 40 : isTablet ? 36 : isSmallPhone ? 28 : 32, fontWeight: FontWeight.w800, height: 1.2, shadows: [Shadow(color: Colors.black26, offset: const Offset(0, 2), blurRadius: 4)])),
                      SizedBox(height: 12),
                      Padding(padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16), child: Text('Enter your email or phone to receive OTP for password reset', textAlign: TextAlign.center, style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.9), fontSize: isTablet ? 18 : 16, height: 1.4, fontWeight: FontWeight.w500))),
                      SizedBox(height: isTablet ? 56 : 48),
                      Flexible(child: Container(constraints: BoxConstraints(maxWidth: maxContentWidth, minHeight: 520), padding: EdgeInsets.fromLTRB(isDesktop ? 48 : isTablet ? 40 : 32, isDesktop ? 52 : isTablet ? 44 : 36, isDesktop ? 48 : isTablet ? 40 : 32, isDesktop ? 44 : isTablet ? 36 : 32), decoration: BoxDecoration(color: colorScheme.surface.withOpacity(0.95), borderRadius: BorderRadius.circular(isDesktop ? 36 : isTablet ? 32 : 28), border: Border.all(color: colorScheme.primary.withOpacity(0.2), width: 1.5), boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.15), blurRadius: isDesktop ? 60 : isTablet ? 50 : 40, offset: const Offset(0, 20)), BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: isDesktop ? 40 : 30, offset: const Offset(0, 10))]), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Text('Choose Verification Method', textAlign: TextAlign.center, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: colorScheme.primary, height: 1.1)),
                        SizedBox(height: isTablet ? 36 : 28),
                        _buildResponsiveRadioTile(title: 'Email Verification', subtitle: 'Secure OTP sent to your email', icon: Icons.email_outlined, value: OTPType.email, groupValue: _selectedType, theme: theme, isTablet: isTablet, isDesktop: isDesktop),
                        SizedBox(height: isTablet ? 20 : 16),
                        _buildResponsiveRadioTile(title: 'Phone Verification', subtitle: 'Instant SMS OTP to your mobile', icon: Icons.phone_android_outlined, value: OTPType.phone, groupValue: _selectedType, theme: theme, isTablet: isTablet, isDesktop: isDesktop),
                        SizedBox(height: isTablet ? 40 : 32),
                        _buildResponsiveInputField(theme, colorScheme, isTablet, isDesktop, isSmallPhone),
                        SizedBox(height: isTablet ? 48 : 40),
                        _buildSendButton(theme, colorScheme, isTablet, isDesktop),
                        SizedBox(height: isTablet ? 32 : 24),
                        _buildBackButton(theme, colorScheme, isTablet),
                      ]))),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ FIXED INPUT FIELD - TextFormField + floatingLabelBehavior
  Widget _buildResponsiveInputField(ThemeData theme, ColorScheme colorScheme, bool isTablet, bool isDesktop, bool isSmallPhone) {
    return Container(
      height: isDesktop ? 76 : isTablet ? 70 : 64,
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(isDesktop ? 28 : isTablet ? 24 : 20),
        border: Border.all(
          color: colorScheme.outline.withOpacity((_selectedType != null) ? 0.8 : 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: TextFormField(
        controller: _inputController,
        keyboardType: _selectedType == OTPType.phone
            ? TextInputType.phone
            : TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: isDesktop ? 20 : isTablet ? 18 : 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: _selectedType == OTPType.phone
              ? "Enter Phone Number (+91...)"
              : "Enter Email Address",
          floatingLabelBehavior: FloatingLabelBehavior.auto,  // ✅ ये key change
          labelStyle: TextStyle(
            color: colorScheme.onSurfaceVariant.withOpacity(0.8),
            fontSize: isDesktop ? 17 : isTablet ? 16 : 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.all(isDesktop ? 20 : isTablet ? 18 : 16),
            child: Icon(
              _selectedType == OTPType.phone
                  ? Icons.phone_android_outlined
                  : Icons.email_outlined,
              color: colorScheme.primary.withOpacity(0.9),
              size: isDesktop ? 28 : isTablet ? 24 : 22,
            ),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 28 : isTablet ? 24 : 20,
            vertical: isDesktop ? 26 : isTablet ? 24 : 20,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildSendButton(ThemeData theme, ColorScheme colorScheme, bool isTablet, bool isDesktop) {
    return Container(
      height: isDesktop ? 80 : isTablet ? 74 : 68,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primaryContainer.withOpacity(0.9), colorScheme.primary],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(isDesktop ? 32 : isTablet ? 28 : 24),
        boxShadow: [
          BoxShadow(
              color: colorScheme.primary.withOpacity(0.4),
              blurRadius: isDesktop ? 35 : isTablet ? 30 : 25,
              offset: const Offset(0, 18),
              spreadRadius: 1
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(isDesktop ? 32 : isTablet ? 28 : 24),
        child: InkWell(
          borderRadius: BorderRadius.circular(isDesktop ? 32 : isTablet ? 28 : 24),
          onTap: isLoading ? null : sendOTP,
          child: Center(
            child: isLoading
                ? CircularProgressIndicator(strokeWidth: isDesktop ? 4 : 3, color: colorScheme.onPrimary)
                : Text(
              'Send OTP Code',
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: isDesktop ? 24 : isTablet ? 22 : 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(ThemeData theme, ColorScheme colorScheme, bool isTablet) {
    return Align(
      alignment: Alignment.center,
      child: TextButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back_ios_new_rounded, size: isTablet ? 18 : 16, color: colorScheme.primary),
        label: Text(
          'Back to Login',
          style: TextStyle(
            color: colorScheme.primary,
            fontSize: isTablet ? 17 : 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16, vertical: isTablet ? 12 : 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
                side: BorderSide(color: colorScheme.primary.withOpacity(0.2))
            )
        ),
      ),
    );
  }

  Widget _buildResponsiveRadioTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required OTPType value,
    required OTPType? groupValue,
    required ThemeData theme,
    required bool isTablet,
    required bool isDesktop
  }) {
    final colorScheme = theme.colorScheme;
    final isSelected = groupValue == value;
    return Container(
      padding: EdgeInsets.all(isDesktop ? 28 : isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primary.withOpacity(0.08)
            : colorScheme.surfaceVariant.withOpacity(0.25),
        borderRadius: BorderRadius.circular(isDesktop ? 28 : isTablet ? 24 : 20),
        border: Border.all(
          color: isSelected
              ? colorScheme.primary.withOpacity(0.6)
              : colorScheme.outline.withOpacity(0.4),
          width: isSelected ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? colorScheme.primary.withOpacity(0.15)
                : Colors.transparent,
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(isDesktop ? 28 : isTablet ? 24 : 20),
          onTap: () {
            setState(() {
              _selectedType = value;
              _inputController.clear();
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isDesktop ? 18 : isTablet ? 16 : 14),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(colors: [
                      colorScheme.primary.withOpacity(0.2),
                      colorScheme.primary.withOpacity(0.1)
                    ])
                        : null,
                    color: isSelected ? null : colorScheme.surfaceVariant,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outline.withOpacity(0.4),
                      width: isSelected ? 3 : 1.5,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    size: isDesktop ? 28 : isTablet ? 26 : 22,
                  ),
                ),
                SizedBox(width: isDesktop ? 24 : isTablet ? 20 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                          fontSize: isDesktop ? 20 : isTablet ? 18 : 17,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isSelected
                              ? colorScheme.primary.withOpacity(0.85)
                              : colorScheme.onSurfaceVariant,
                          fontSize: isDesktop ? 16 : isTablet ? 15 : 14,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: isDesktop ? 1.3 : isTablet ? 1.2 : 1.1,
                  child: Radio<OTPType>(
                    value: value,
                    groupValue: groupValue,
                    onChanged: null,
                    activeColor: colorScheme.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )
              ],
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
