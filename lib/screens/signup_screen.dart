import 'package:flutter/material.dart';
import '../api/api_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  // ✅ PHONE पहले से +91 के साथ initialize
  final phoneController = TextEditingController(text: '+91 ');
  final passwordController = TextEditingController();
  bool loading = false;

  // SIGNUP API CALL
  Future<void> signup() async {
    setState(() => loading = true);
    try {
      final name = nameController.text.trim();
      final email = emailController.text.trim().toLowerCase();
      // ✅ हमेशा +91 के साथ guaranteed
      final phone = phoneController.text.trim().replaceAll(' ', '');
      final password = passwordController.text.trim();

      var res = await ApiService.post("auth/signup", {
        "name": name,
        "email": email,
        "phone": phone,  // "+91 7230953540" format में जाएगा
        "password": password,
      });

      setState(() => loading = false);

      if (res['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? "Account created successfully!"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? "Signup failed"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isSmallPhone = screenWidth < 360;

    final maxPageWidth = isTablet ? 900.0 : screenWidth;
    final horizontalPagePadding = isTablet ? 32.0 : 0.0;

    return Scaffold(
      body: Center(
        child: Container(
          width: maxPageWidth,
          padding: EdgeInsets.symmetric(horizontal: horizontalPagePadding),
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
                isSmallPhone ? 16.0 : isTablet ? 64.0 : 32.0;

                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: screenHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          // HEADER
                          Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: isTablet ? 48.0 : 32.0,
                              horizontal: paddingHorizontal,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.card_travel,
                                  size: isTablet
                                      ? 96.0
                                      : isSmallPhone
                                      ? 64.0
                                      : 80.0,
                                  color: colorScheme.onPrimary,
                                ),
                                SizedBox(height: isTablet ? 20.0 : 16.0),
                                Text(
                                  'Create Your Account',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: colorScheme.onPrimary,
                                    fontSize: isTablet
                                        ? 32.0
                                        : isSmallPhone
                                        ? 24.0
                                        : 28.0,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: isTablet ? 32.0 : 16.0),
                                  child: Text(
                                    'Join AI Travels and manage your trips smartly',
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
                          ),

                          // FORM CARD
                          Center(
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth: 500,
                                minHeight: screenHeight * 0.6,
                              ),
                              margin: EdgeInsets.symmetric(
                                  horizontal: paddingHorizontal),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(isTablet ? 32 : 28),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                    colorScheme.shadow.withOpacity(0.3),
                                    blurRadius: 40,
                                    offset: const Offset(0, -10),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  paddingHorizontal,
                                  isTablet ? 48.0 : 32.0,
                                  paddingHorizontal,
                                  isTablet ? 48.0 : 32.0,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Sign up',
                                      style: theme.textTheme.headlineMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: isTablet ? 28 : 24,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Please fill in the details to continue',
                                      style: TextStyle(
                                        color:
                                        colorScheme.onSurfaceVariant,
                                        fontSize: isTablet ? 15 : 13,
                                      ),
                                    ),
                                    SizedBox(height: isTablet ? 36.0 : 24.0),

                                    _buildResponsiveTextField(
                                      controller: nameController,
                                      label: 'Full Name',
                                      icon: Icons.person_outline,
                                      keyboardType: TextInputType.name,
                                      theme: theme,
                                      isTablet: isTablet,
                                    ),
                                    SizedBox(height: isTablet ? 20 : 16),

                                    _buildResponsiveTextField(
                                      controller: emailController,
                                      label: 'Email',
                                      keyboardType:
                                      TextInputType.emailAddress,
                                      icon: Icons.email_outlined,
                                      theme: theme,
                                      isTablet: isTablet,
                                    ),
                                    SizedBox(height: isTablet ? 20 : 16),

                                    // ✅ PHONE FIELD - पहले से +91 के साथ
                                    _buildResponsiveTextField(
                                      controller: phoneController,
                                      label: 'Phone (10 digits)',
                                      hintText: '7230953540',
                                      keyboardType: TextInputType.phone,
                                      icon: Icons.phone_outlined,
                                      theme: theme,
                                      isTablet: isTablet,
                                      onChanged: (value) {
                                        // ✅ Smart +91 handling
                                        if (!value.startsWith('+91')) {
                                          final cleanNumber = value.replaceAll(RegExp(r'[^0-9]'), '');
                                          if (cleanNumber.length <= 10) {
                                            phoneController.value = TextEditingValue(
                                              text: '+91 $cleanNumber',
                                              selection: TextSelection.collapsed(
                                                offset: '+91 '.length + cleanNumber.length,
                                              ),
                                            );
                                          }
                                        } else {
                                          // +91 के बाद सिर्फ 10 digits
                                          final after91 = value.substring('+91 '.length);
                                          final cleanAfter = after91.replaceAll(RegExp(r'[^0-9]'), '');
                                          if (cleanAfter.length > 10) {
                                            phoneController.value = TextEditingValue(
                                              text: '+91 ${cleanAfter.substring(0, 10)}',
                                              selection: TextSelection.collapsed(
                                                offset: '+91 '.length + 10,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                    SizedBox(height: isTablet ? 20 : 16),

                                    _buildResponsiveTextField(
                                      controller: passwordController,
                                      label: 'Password',
                                      icon: Icons.lock_outline,
                                      obscure: true,
                                      keyboardType:
                                      TextInputType.visiblePassword,
                                      theme: theme,
                                      isTablet: isTablet,
                                    ),
                                    SizedBox(height: isTablet ? 36.0 : 24.0),

                                    // BUTTON
                                    Container(
                                      height: isTablet ? 64 : 56,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                        BorderRadius.circular(isTablet ? 24 : 18),
                                        gradient: LinearGradient(
                                          colors: [
                                            colorScheme.primary,
                                            colorScheme.primaryContainer,
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: colorScheme.primary
                                                .withOpacity(0.3),
                                            blurRadius: isTablet ? 25 : 20,
                                            offset: const Offset(0, 12),
                                          ),
                                        ],
                                      ),
                                      child: loading
                                          ? Center(
                                        child: CircularProgressIndicator(
                                          color: colorScheme.onPrimary,
                                          strokeWidth: 3,
                                        ),
                                      )
                                          : Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius:
                                          BorderRadius.circular(isTablet ? 24 : 18),
                                          onTap: signup,
                                          child: Center(
                                            child: Text(
                                              'SIGN UP',
                                              style: TextStyle(
                                                color: colorScheme.onPrimary,
                                                fontSize: isTablet ? 20 : 17,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing:
                                                isTablet ? 1.5 : 1.2,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: isTablet ? 32 : 20),

                                    // LOGIN LINK
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: isTablet ? 32 : 0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Already have an account? ",
                                            style: TextStyle(
                                              color: colorScheme.onSurfaceVariant,
                                              fontSize: isTablet ? 15 : 13.5,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () =>
                                                Navigator.pushReplacementNamed(
                                                  context,
                                                  '/login',
                                                ),
                                            child: Text(
                                              "Login",
                                              style: TextStyle(
                                                color: colorScheme.primary,
                                                fontWeight: FontWeight.w700,
                                                fontSize: isTablet ? 16 : 14,
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
      ),
    );
  }

  // RESPONSIVE TEXT FIELD
  Widget _buildResponsiveTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    IconData? icon,
    TextInputType? keyboardType,
    bool obscure = false,
    ValueChanged<String>? onChanged,
    required ThemeData theme,
    required bool isTablet,
  }) {
    final colorScheme = theme.colorScheme;
    return Container(
      height: isTablet ? 64 : 56,
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.7),
          width: 1.5,
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        onChanged: onChanged,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: isTablet ? 18 : 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          labelStyle: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: isTablet ? 16 : 14,
          ),
          prefixIcon: icon != null
              ? Padding(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            child: Icon(
              icon,
              color: colorScheme.primary.withOpacity(0.8),
              size: isTablet ? 24 : 20,
            ),
          )
              : null,
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
