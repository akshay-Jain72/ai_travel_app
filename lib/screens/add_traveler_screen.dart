import 'package:flutter/material.dart';
import 'dart:convert';
import '../api/api_service.dart';

class AddTravelerScreen extends StatefulWidget {
  final String itineraryId;
  final String itineraryTitle;

  const AddTravelerScreen({
    Key? key,
    required this.itineraryId,
    required this.itineraryTitle,
  }) : super(key: key);

  @override
  State<AddTravelerScreen> createState() => _AddTravelerScreenState();
}

class _AddTravelerScreenState extends State<AddTravelerScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _languageController = TextEditingController();

  String? _selectedCountryCode = '+91';
  bool _isPrimary = false;
  bool _isLoading = false;
  bool _isDuplicatePhone = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _animationController =
        AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  void _checkDuplicatePhone() {
    setState(() => _isDuplicatePhone = false);
  }

  Future<void> _addTraveler() async {
    if (_formKey.currentState!.validate()) {
      final travelerName = _nameController.text.trim(); // 👈 Store name locally

      setState(() => _isLoading = true);
      try {
        final response = await ApiService.addTraveler({
          'itineraryId': widget.itineraryId,
          'name': travelerName,
          'phone': '$_selectedCountryCode${_phoneController.text.trim()}',
          'email': _emailController.text.trim().isNotEmpty
              ? _emailController.text.trim()
              : null,
          'language': _languageController.text.trim().isNotEmpty
              ? _languageController.text.trim()
              : 'en',
          'isPrimary': _isPrimary,
        });

        if (response['status'] == true) {
          // 👈 Await dialog result first
          final result = await _showSuccessDialog(travelerName);

          if (result == 'done') {
            _clearForm();
            if (mounted) Navigator.pop(context);
          } else if (result == 'add_more') {
            _clearForm(); // Stay on same screen for more additions
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('❌ ${response['message'] ?? 'Failed'}')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _phoneController.clear();
    _emailController.clear();
    _languageController.clear();
    setState(() {
      _isPrimary = false;
      _selectedCountryCode = '+91';
      _isDuplicatePhone = false;
    });
  }

  Future<String?> _showSuccessDialog(String travelerName) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          content: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primaryContainer, colorScheme.surface],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 80, color: colorScheme.primary),
                const SizedBox(height: 20),
                Text(
                  '✅ Traveler Added Successfully!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '"$travelerName" added to ${widget.itineraryTitle}',
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, 'done'),
                      icon: Icon(Icons.arrow_back, color: colorScheme.onPrimary),
                      label: Text(
                        'Done',
                        style: TextStyle(color: colorScheme.onPrimary),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, 'add_more'),
                      icon: Icon(Icons.add, color: colorScheme.onPrimary),
                      label: Text(
                        'Add More',
                        style: TextStyle(color: colorScheme.onPrimary),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isSmallPhone = screenWidth < 360;

    final maxPageWidth = isTablet ? 900.0 : screenWidth;

    return Scaffold(
      body: Center(
        child: Container(
          width: maxPageWidth,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.primaryContainer.withOpacity(0.3),
                colorScheme.surface,
                colorScheme.surfaceVariant.withOpacity(0.2),
              ],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final padding = isSmallPhone ? 20.0 : isTablet ? 40.0 : 28.0;
                  return SingleChildScrollView(
                    padding: EdgeInsets.all(padding),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isTablet ? 500 : double.infinity,
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 40),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Add New Traveler',
                                          style: TextStyle(
                                            fontSize: isTablet ? 32 : 28,
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          widget.itineraryTitle,
                                          style: TextStyle(
                                            fontSize: isTablet ? 20 : 18,
                                            color: colorScheme.primaryContainer,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Form(
                              key: _formKey,
                              child: _buildResponsiveGlassmorphismCard(
                                theme: theme,
                                isTablet: isTablet,
                                child: _buildResponsiveFormFields(
                                  theme: theme,
                                  isTablet: isTablet,
                                ),
                              ),
                            ),
                            SizedBox(height: isTablet ? 48.0 : 40.0),
                            _buildResponsiveSubmitButton(
                              theme: theme,
                              isTablet: isTablet,
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
      ),
    );
  }

  Widget _buildResponsiveGlassmorphismCard({
    required ThemeData theme,
    required bool isTablet,
    required Widget child,
  }) {
    final colorScheme = theme.colorScheme;
    return Container(
      padding: EdgeInsets.all(isTablet ? 36 : 28),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(isTablet ? 36 : 32),
        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.15),
            blurRadius: isTablet ? 50 : 40,
            offset: Offset(0, isTablet ? 25 : 20),
          )
        ],
      ),
      child: child,
    );
  }

  Widget _buildResponsiveFormFields({
    required ThemeData theme,
    required bool isTablet,
  }) {
    return Column(
      children: [
        _buildResponsiveInputField(
          label: '👤 Full Name *',
          controller: _nameController,
          icon: Icons.person,
          theme: theme,
          isTablet: isTablet,
        ),
        SizedBox(height: isTablet ? 24 : 20),
        Row(
          children: [
            _buildResponsiveCountryCodeDropdown(theme: theme, isTablet: isTablet),
            SizedBox(width: isTablet ? 20 : 16),
            Expanded(
              child: _buildResponsiveInputField(
                label: '📱 Phone *',
                controller: _phoneController,
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                theme: theme,
                isTablet: isTablet,
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 24 : 20),
        _buildResponsiveInputField(
          label: '✉️ Email (Optional)',
          controller: _emailController,
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          theme: theme,
          isTablet: isTablet,
        ),
        SizedBox(height: isTablet ? 24 : 20),
        _buildResponsiveInputField(
          label: '🌐 Language (Optional)',
          controller: _languageController,
          icon: Icons.language,
          theme: theme,
          isTablet: isTablet,
        ),
        SizedBox(height: isTablet ? 28 : 24),
        _buildResponsivePrimaryContactRow(theme: theme, isTablet: isTablet),
      ],
    );
  }

  Widget _buildResponsiveInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    required ThemeData theme,
    required bool isTablet,
  }) {
    final colorScheme = theme.colorScheme;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: label.contains('Phone') ? (_) => _checkDuplicatePhone() : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Padding(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          child: Icon(icon, color: colorScheme.primary.withOpacity(0.8)),
        ),
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 28 : 24,
          vertical: isTablet ? 24 : 20,
        ),
      ),
      validator: label.contains('*')
          ? (value) =>
      value?.trim().isEmpty ?? true ? '$label is required' : null
          : null,
      style: TextStyle(fontSize: isTablet ? 18 : 16),
    );
  }

  Widget _buildResponsiveCountryCodeDropdown({
    required ThemeData theme,
    required bool isTablet,
  }) {
    final colorScheme = theme.colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: isTablet ? 12 : 8,
          )
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCountryCode,
          items: [
            '+91 🇮🇳',
            '+1 🇺🇸',
            '+44 🇬🇧',
            '+971 🇦🇪',
          ].map(
                (code) => DropdownMenuItem(
              value: code.split(' ')[0],
              child: Text(
                code,
                style: TextStyle(fontSize: isTablet ? 16 : 14),
              ),
            ),
          ).toList(),
          onChanged: (value) => setState(() => _selectedCountryCode = value),
          icon: Icon(Icons.arrow_drop_down,
              color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _buildResponsivePrimaryContactRow({
    required ThemeData theme,
    required bool isTablet,
  }) {
    final colorScheme = theme.colorScheme;
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.star,
                color: colorScheme.primary, size: isTablet ? 28 : 24),
          ),
          SizedBox(width: isTablet ? 20 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Primary Contact',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Receives all trip updates',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: isTablet ? 15 : 14,
                  ),
                ),
              ],
            ),
          ),
          Checkbox(
            value: _isPrimary,
            onChanged: (value) => setState(() => _isPrimary = value!),
            activeColor: colorScheme.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveSubmitButton({
    required ThemeData theme,
    required bool isTablet,
  }) {
    final colorScheme = theme.colorScheme;
    return GestureDetector(
      onTap: _isLoading ? null : _addTraveler,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: isTablet ? 80 : 70,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isLoading
                ? [colorScheme.onSurfaceVariant, colorScheme.surfaceVariant]
                : [colorScheme.primary, colorScheme.primaryContainer],
          ),
          borderRadius: BorderRadius.circular(isTablet ? 48 : 40),
          boxShadow: [
            BoxShadow(
              color: _isLoading
                  ? colorScheme.onSurfaceVariant.withOpacity(0.3)
                  : colorScheme.primary.withOpacity(0.4),
              blurRadius: isTablet ? 40 : 30,
              offset: Offset(0, isTablet ? 20 : 15),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading) ...[
              SizedBox(
                width: isTablet ? 28 : 24,
                height: isTablet ? 28 : 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                  AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                ),
              ),
              SizedBox(width: isTablet ? 20 : 16),
            ],
            Text(
              _isLoading ? 'Adding...' : '✨ Add Traveler',
              style: TextStyle(
                fontSize: isTablet ? 22 : 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _languageController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
