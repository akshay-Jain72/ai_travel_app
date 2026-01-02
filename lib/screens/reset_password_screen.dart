import 'package:flutter/material.dart';
import '../api/api_service.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String phoneNumber;

  const ResetPasswordScreen({
    super.key,
    required this.phoneNumber,
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

  Future<void> resetPassword() async {
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (password.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enter both passwords"), backgroundColor: Colors.orange)
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Passwords don't match"), backgroundColor: Colors.red)
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password must be 6+ characters"), backgroundColor: Colors.orange)
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      print('🔥 RESET PHONE: ${widget.phoneNumber}');
      final response = await ApiService.post('auth/reset-password', {
        'value': widget.phoneNumber,
        'password': password,
      });

      print('✅ RESET RESPONSE: $response');

      if (response['status'] == true || response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Password reset successful!"),
              backgroundColor: Colors.green,
            )
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? "Reset failed"), backgroundColor: Colors.red)
        );
      }
    } catch (e) {
      print('❌ RESET ERROR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Network error"), backgroundColor: Colors.red)
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
    final isTablet = screenWidth > 600;
    final isSmallPhone = screenWidth < 360;

    return Scaffold(
      body: Container(
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
                padding: EdgeInsets.symmetric(horizontal: isSmallPhone ? 16 : 28, vertical: isTablet ? 60 : 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 🔒 LOCK ICON
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.green.shade400, Colors.green.shade600]),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.4),
                            blurRadius: 35,
                            offset: Offset(0, 18),
                          )
                        ],
                      ),
                      child: Icon(Icons.lock_reset, color: Colors.white, size: 65),
                    ),
                    SizedBox(height: 32),

                    // TITLE
                    Text(
                      'Reset Password',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: isTablet ? 36 : 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Set new password for ${widget.phoneNumber}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colorScheme.onPrimary.withOpacity(0.9),
                          fontSize: 17,
                        ),
                      ),
                    ),
                    SizedBox(height: 48),

                    // PASSWORD FIELDS
                    _buildPasswordField(
                      controller: _passwordController,
                      label: 'New Password',
                      obscureText: _obscurePassword,
                      onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icons.lock_outline,
                      isNew: true,
                    ),
                    SizedBox(height: 20),
                    _buildPasswordField(
                      controller: _confirmController,
                      label: 'Confirm Password',
                      obscureText: _obscureConfirm,
                      onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      icon: Icons.lock_outline_rounded,
                      isNew: false,
                    ),
                    SizedBox(height: 24),

                    // STRENGTH BAR
                    _buildStrengthIndicator(),
                    SizedBox(height: 48),

                    // RESET BUTTON
                    _buildResetButton(),
                    SizedBox(height: 28),

                    // BACK
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back_ios, size: 18, color: colorScheme.primary),
                      label: Text(
                        'Back to Login',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
    required IconData icon,
    required bool isNew,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasText = controller.text.isNotEmpty;
    final isValid = controller.text.length >= 6 &&
        (_confirmController.text == controller.text || controller == _passwordController);

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isValid ? Colors.green : colorScheme.outline.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isValid ? Colors.green.withOpacity(0.2) : Colors.transparent,
            blurRadius: 15,
            offset: Offset(0, 8),
          )
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: isValid ? Colors.green : null),
          suffixIcon: IconButton(
            icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 18),
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _buildStrengthIndicator() {
    final password = _passwordController.text;
    final matches = _confirmController.text == password;
    final strength = password.length >= 8 && matches ? 1.0 :
    password.length >= 6 && matches ? 0.7 : password.isNotEmpty ? 0.3 : 0.0;

    return Column(
      children: [
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            widthFactor: strength,
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.green.shade400, Colors.green.shade700]),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          matches ? 'Strong Password' : 'Passwords must match',
          style: TextStyle(
            color: matches ? Colors.green.shade700 : Colors.red,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildResetButton() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEnabled = _passwordController.text.isNotEmpty &&
        _confirmController.text.isNotEmpty &&
        _passwordController.text == _confirmController.text &&
        _passwordController.text.length >= 6;

    return SizedBox(
      width: double.infinity,
      height: 70,
      child: ElevatedButton(
        onPressed: isEnabled && !isLoading ? resetPassword : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? Colors.green.shade600 : Colors.grey,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          elevation: isEnabled ? 12 : 0,
        ),
        child: isLoading
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 12),
            Text('Resetting...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_reset),
            SizedBox(width: 12),
            Text('Reset Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
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
