import 'package:flutter/material.dart';
import '../api/api_service.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String emailOrPhone;

  const ResetPasswordScreen({
    super.key,
    required this.emailOrPhone,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // ✅ ApiService INTEGRATED resetPassword!
  Future<void> resetPassword() async {
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (password.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enter password and confirm"), backgroundColor: Colors.orange)
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Passwords do not match"), backgroundColor: Colors.red)
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password must be at least 6 characters"), backgroundColor: Colors.orange)
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await ApiService.post('auth/reset-password', {
        'value': widget.emailOrPhone,
        'password': password,
      });

      if (response['status'] == true || response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("✅ Password updated successfully!"),
                backgroundColor: Colors.green
            )
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? "Reset failed"),
              backgroundColor: Colors.red,
            )
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Network error: $e"),
            backgroundColor: Colors.red,
          )
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
    final maxContentWidth = isDesktop ? 520.0 : isTablet ? 480.0 : 400.0;

    return Scaffold(
      body: Container(
        height: screenHeight,
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
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxContentWidth,
                  minHeight: screenHeight * 0.85,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallPhone ? 16.0 : 28.0,
                      vertical: isTablet ? 64.0 : 48.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ✅ HERO HEADER
                        Hero(
                          tag: 'reset_lock',
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primary.withOpacity(0.2),
                                  Colors.white.withOpacity(0.1),
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 30,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.lock_reset_outlined,
                              size: isDesktop ? 110 : isTablet ? 100 : isSmallPhone ? 80 : 92,
                              color: colorScheme.onPrimary.withOpacity(0.95),
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: const Offset(0, 6),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: isTablet ? 32 : 28),

                        Text(
                          'New Password',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: isDesktop ? 42 : isTablet ? 38 : isSmallPhone ? 30 : 34,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: const Offset(0, 3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: isTablet ? 28 : 20),
                          child: Text(
                            'Set a strong password for ${widget.emailOrPhone}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colorScheme.onPrimary.withOpacity(0.9),
                              fontSize: isTablet ? 18 : 16,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(height: isTablet ? 60 : 52),

                        // ✅ PREMIUM GLASS FORM CARD
                        Flexible(
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: maxContentWidth,
                              minHeight: 580,
                            ),
                            padding: EdgeInsets.fromLTRB(
                              isDesktop ? 52 : isTablet ? 44 : 36,
                              isDesktop ? 56 : isTablet ? 48 : 40,
                              isDesktop ? 52 : isTablet ? 44 : 36,
                              isDesktop ? 48 : isTablet ? 40 : 36,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surface.withOpacity(0.97),
                              borderRadius: BorderRadius.circular(isDesktop ? 40 : isTablet ? 36 : 32),
                              border: Border.all(
                                color: colorScheme.primary.withOpacity(0.25),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.2),
                                  blurRadius: isDesktop ? 70 : isTablet ? 60 : 50,
                                  offset: const Offset(0, 25),
                                  spreadRadius: 0,
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: isDesktop ? 45 : 35,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // ✅ PASSWORD FIELDS
                                _buildPasswordField(
                                  controller: _passwordController,
                                  label: 'New Password',
                                  obscureText: _obscurePassword,
                                  onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                                  theme: theme,
                                  colorScheme: colorScheme,
                                  isTablet: isTablet,
                                  isDesktop: isDesktop,
                                  isFirstField: true,
                                ),
                                SizedBox(height: isTablet ? 24 : 20),

                                _buildPasswordField(
                                  controller: _confirmController,
                                  label: 'Confirm Password',
                                  obscureText: _obscureConfirm,
                                  onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                  theme: theme,
                                  colorScheme: colorScheme,
                                  isTablet: isTablet,
                                  isDesktop: isDesktop,
                                  isFirstField: false,
                                ),
                                SizedBox(height: isTablet ? 16 : 12),

                                // ✅ ENHANCED STRENGTH INDICATOR
                                _buildPasswordStrengthIndicator(theme, colorScheme, isTablet, isDesktop),
                                SizedBox(height: isTablet ? 52 : 44),

                                // ✅ DYNAMIC RESET BUTTON
                                _buildResetButton(theme, colorScheme, isTablet, isDesktop),
                                SizedBox(height: isTablet ? 36 : 28),

                                // ✅ BACK BUTTON
                                _buildBackButton(theme, colorScheme, isTablet, isDesktop),
                              ],
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
      ),
    );
  }

  // ✅ FIXED PASSWORD FIELD - TextFormField + floatingLabelBehavior
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleObscure,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required bool isTablet,
    required bool isDesktop,
    required bool isFirstField,
  }) {
    final hasText = controller.text.isNotEmpty;
    final isValidPassword = controller == _passwordController
        ? controller.text.length >= 6
        : controller.text == _passwordController.text && controller.text.length >= 6;

    return Container(
      height: isDesktop ? 84 : isTablet ? 76 : 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            hasText && isValidPassword
                ? colorScheme.primary.withOpacity(0.08)
                : colorScheme.surfaceVariant.withOpacity(0.3),
            colorScheme.surfaceVariant.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(isDesktop ? 30 : isTablet ? 26 : 22),
        border: Border.all(
          color: hasText && isValidPassword
              ? colorScheme.primary.withOpacity(0.6)
              : hasText
              ? colorScheme.error.withOpacity(0.4)
              : colorScheme.outline.withOpacity(0.5),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: hasText && isValidPassword
                ? colorScheme.primary.withOpacity(0.15)
                : Colors.transparent,
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextFormField(  // ✅ TextField → TextFormField
        controller: controller,
        obscureText: obscureText,
        textInputAction: TextInputAction.next,
        style: TextStyle(
          fontSize: isDesktop ? 20 : isTablet ? 18 : 16,
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.auto,  // ✅ ये key change
          labelStyle: TextStyle(
            color: hasText && isValidPassword
                ? colorScheme.primary
                : hasText
                ? colorScheme.error
                : colorScheme.onSurfaceVariant.withOpacity(0.8),
            fontSize: isDesktop ? 18 : isTablet ? 16 : 15,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.all(isDesktop ? 22 : isTablet ? 20 : 18),
            child: Icon(
              isFirstField ? Icons.lock_outlined : Icons.lock_outline,
              color: hasText && isValidPassword
                  ? colorScheme.primary
                  : hasText
                  ? colorScheme.error
                  : colorScheme.onSurfaceVariant,
              size: isDesktop ? 28 : isTablet ? 26 : 24,
            ),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: colorScheme.primary.withOpacity(0.8),
              size: isDesktop ? 26 : 24,
            ),
            onPressed: onToggleObscure,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : isTablet ? 28 : 24,
            vertical: isDesktop ? 28 : isTablet ? 26 : 22,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator(ThemeData theme, ColorScheme colorScheme, bool isTablet, bool isDesktop) {
    final password = _passwordController.text;
    final confirmMatches = _confirmController.text == password;

    String strength = 'Weak';
    Color strengthColor = Colors.red;
    double progress = 0.1;

    if (password.length >= 8 && confirmMatches) {
      strength = 'Strong';
      strengthColor = Colors.green;
      progress = 1.0;
    } else if (password.length >= 6 && confirmMatches) {
      strength = 'Medium';
      strengthColor = Colors.orange;
      progress = 0.75;
    } else if (password.length >= 4) {
      strength = 'Weak';
      strengthColor = Colors.orange;
      progress = 0.4;
    }

    return Column(
      children: [
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.4),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            widthFactor: progress,
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [strengthColor.withOpacity(0.3), strengthColor],
                ),
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: strengthColor.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(isDesktop ? 8 : 6),
              decoration: BoxDecoration(
                color: strengthColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.security,
                color: strengthColor,
                size: isDesktop ? 22 : 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strength,
                    style: TextStyle(
                      color: strengthColor,
                      fontSize: isDesktop ? 18 : isTablet ? 16 : 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    confirmMatches
                        ? '${password.length}/8+ characters'
                        : 'Passwords must match',
                    style: TextStyle(
                      color: confirmMatches
                          ? strengthColor.withOpacity(0.8)
                          : Colors.red.withOpacity(0.8),
                      fontSize: isDesktop ? 14 : 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResetButton(ThemeData theme, ColorScheme colorScheme, bool isTablet, bool isDesktop) {
    final isEnabled = _passwordController.text.isNotEmpty &&
        _confirmController.text.isNotEmpty &&
        _passwordController.text == _confirmController.text &&
        _passwordController.text.length >= 6;

    return Container(
      height: isDesktop ? 88 : isTablet ? 82 : 76,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isEnabled
              ? [colorScheme.primary, colorScheme.primaryContainer, colorScheme.primary]
              : [colorScheme.onSurfaceVariant.withOpacity(0.4), colorScheme.onSurfaceVariant.withOpacity(0.2)],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(isDesktop ? 36 : isTablet ? 32 : 28),
        boxShadow: [
          BoxShadow(
            color: isEnabled
                ? colorScheme.primary.withOpacity(0.5)
                : Colors.transparent,
            blurRadius: isDesktop ? 45 : isTablet ? 40 : 35,
            offset: const Offset(0, 22),
            spreadRadius: isEnabled ? 2 : 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(isDesktop ? 36 : isTablet ? 32 : 28),
        child: InkWell(
          borderRadius: BorderRadius.circular(isDesktop ? 36 : isTablet ? 32 : 28),
          onTap: isEnabled && !isLoading ? resetPassword : null,
          child: Center(
            child: isLoading
                ? CircularProgressIndicator(
              strokeWidth: isDesktop ? 4.5 : 4,
              color: colorScheme.onPrimary,
            )
                : Text(
              'Reset Password',
              style: TextStyle(
                color: isEnabled ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                fontSize: isDesktop ? 26 : isTablet ? 24 : 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(ThemeData theme, ColorScheme colorScheme, bool isTablet, bool isDesktop) {
    return Align(
      alignment: Alignment.center,
      child: TextButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: isDesktop ? 20 : isTablet ? 18 : 16,
          color: colorScheme.primary,
        ),
        label: Text(
          'Back to Login',
          style: TextStyle(
            color: colorScheme.primary,
            fontSize: isDesktop ? 18 : isTablet ? 17 : 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 24 : isTablet ? 20 : 18,
            vertical: isDesktop ? 16 : isTablet ? 14 : 12,
          ),
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(color: colorScheme.primary.withOpacity(0.25), width: 1.5),
          ),
          elevation: 8,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }
}
