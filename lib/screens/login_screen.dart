import 'package:flutter/material.dart';
import '../api/api_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  bool obscurePassword = true;

  // 🔥 LOGIN FUNCTION
  Future<void> login() async {
    setState(() => loading = true);
    try {
      final cleanEmail = emailController.text.trim().toLowerCase();
      final cleanPassword = passwordController.text.trim();

      print('🔥 LOGIN EMAIL: "$cleanEmail"');
      print('🔥 LOGIN PASS: "$cleanPassword" (LEN: ${cleanPassword.length})');

      final res = await ApiService.login(
        email: cleanEmail,
        password: cleanPassword,
      );

      setState(() => loading = false);

      print('📥 LOGIN RESPONSE: ${res['status']} - ${res['message']}');

      if (res['status'] == true) {
        print('✅ LOGIN SUCCESS - Token Saved! Going to Dashboard');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        print('❌ LOGIN FAILED: ${res['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? "Login failed"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      print('❌ LOGIN ERROR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Network error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    final isTablet = size.width > 600;
    final isSmallPhone = size.width < 360;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              colorScheme.primaryContainer,
              colorScheme.inversePrimary,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final paddingHorizontal =
              isSmallPhone ? 16.0 : isTablet ? 48.0 : 24.0;

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: paddingHorizontal,
                    vertical: 16,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet
                          ? 450
                          : size.width > 480
                          ? 420
                          : double.infinity,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // HEADER
                        Column(
                          children: [
                            Icon(
                              Icons.flight_takeoff,
                              size: isTablet
                                  ? 96.0
                                  : isSmallPhone
                                  ? 64.0
                                  : 80.0,
                              color: colorScheme.onPrimary,
                            ),
                            SizedBox(height: isTablet ? 20.0 : 16.0),
                            Text(
                              'AI Travels',
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontSize: isTablet
                                    ? 34.0
                                    : isSmallPhone
                                    ? 26.0
                                    : 30.0,
                                fontWeight: FontWeight.bold,
                                letterSpacing: isTablet ? 1.0 : 0.5,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 32.0 : 16.0,
                              ),
                              child: Text(
                                'Login to manage your itineraries',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color:
                                  colorScheme.onPrimary.withOpacity(0.9),
                                  fontSize: isTablet ? 16.0 : 14.0,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isTablet ? 36.0 : 24.0),

                        // CARD
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 32.0 : 24.0,
                            vertical: isTablet ? 36.0 : 28.0,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius:
                            BorderRadius.circular(isTablet ? 28 : 24),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.shadow.withOpacity(0.3),
                                blurRadius: isTablet ? 40 : 30,
                                offset: Offset(0, isTablet ? 16 : 12),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                "Login",
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isTablet ? 32 : 26,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Welcome back, please enter your details",
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: isTablet ? 15 : 13,
                                  height: 1.4,
                                ),
                              ),
                              SizedBox(height: isTablet ? 36.0 : 24.0),

                              _buildResponsiveTextField(
                                controller: emailController,
                                label: "Email",
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                theme: theme,
                                isTablet: isTablet,
                              ),
                              SizedBox(height: isTablet ? 20.0 : 16.0),

                              _buildResponsivePasswordField(
                                controller: passwordController,
                                label: "Password",
                                theme: theme,
                                isTablet: isTablet,
                              ),
                              SizedBox(height: isTablet ? 24.0 : 20.0),

                              SizedBox(
                                height: isTablet ? 64 : 56,
                                child: loading
                                    ? Center(
                                  child: CircularProgressIndicator(
                                    color: colorScheme.primary,
                                    strokeWidth: isTablet ? 3 : 2,
                                  ),
                                )
                                    : ElevatedButton(
                                  onPressed: login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    colorScheme.primary,
                                    foregroundColor:
                                    colorScheme.onPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(
                                          isTablet ? 20 : 16),
                                    ),
                                    elevation: isTablet ? 8 : 4,
                                    padding: EdgeInsets.symmetric(
                                      vertical: isTablet ? 16 : 12,
                                    ),
                                  ),
                                  child: Text(
                                    "LOGIN",
                                    style: TextStyle(
                                      fontSize: isTablet ? 20 : 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: isTablet ? 20.0 : 16.0),

                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () =>
                                      Navigator.pushNamed(context, '/forgot'),
                                  child: Text(
                                    "Forgot Password?",
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: isTablet ? 16 : 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: colorScheme.outlineVariant,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0),
                                    child: Text(
                                      "OR",
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: isTablet ? 14 : 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: colorScheme.outlineVariant,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isTablet ? 20.0 : 16.0),

                              Container(
                                padding: EdgeInsets.all(isTablet ? 16 : 12),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(
                                      isTablet ? 16 : 12),
                                  border: Border.all(
                                    color: colorScheme.primary
                                        .withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: TextButton(
                                  onPressed: () => Navigator
                                      .pushReplacementNamed(
                                      context, '/signup'),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    foregroundColor: colorScheme.primary,
                                  ),
                                  child: RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontSize: isTablet ? 16 : 15,
                                        fontWeight: FontWeight.w600,
                                        height: 1.3,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: "Don't have an account? ",
                                          style: TextStyle(
                                            color: colorScheme
                                                .onSurfaceVariant,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        TextSpan(
                                          text: "Sign Up",
                                          style: TextStyle(
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: isTablet ? 17 : 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // TEXT FIELD
  Widget _buildResponsiveTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    required ThemeData theme,
    required bool isTablet,
  }) {
    final colorScheme = theme.colorScheme;
    return Container(
      height: isTablet ? 64 : 56,
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.7)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: isTablet ? 18 : 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          labelStyle: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: isTablet ? 16 : 14,
          ),
          prefixIcon: Icon(
            icon,
            color: colorScheme.primary.withOpacity(0.8),
            size: isTablet ? 24 : 20,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 16 : 12,
            vertical: isTablet ? 18 : 14,
          ),
        ),
      ),
    );
  }

  // PASSWORD FIELD
  Widget _buildResponsivePasswordField({
    required TextEditingController controller,
    required String label,
    required ThemeData theme,
    required bool isTablet,
  }) {
    final colorScheme = theme.colorScheme;
    return Container(
      height: isTablet ? 64 : 56,
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.7)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscurePassword,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: isTablet ? 18 : 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          labelStyle: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: isTablet ? 16 : 14,
          ),
          prefixIcon: Icon(
            Icons.lock_outline,
            color: colorScheme.primary.withOpacity(0.8),
            size: isTablet ? 24 : 20,
          ),
          suffixIcon: GestureDetector(
            onTap: () {
              setState(() {
                obscurePassword = !obscurePassword;
              });
            },
            child: Icon(
              obscurePassword ? Icons.visibility : Icons.visibility_off,
              color: colorScheme.onSurfaceVariant,
              size: isTablet ? 24 : 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 16 : 12,
            vertical: isTablet ? 18 : 14,
          ),
        ),
      ),
    );
  }
}
