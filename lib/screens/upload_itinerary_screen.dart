import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../api/api_service.dart';

class UploadItineraryScreen extends StatefulWidget {
  @override
  _UploadItineraryScreenState createState() => _UploadItineraryScreenState();
}

class _UploadItineraryScreenState extends State<UploadItineraryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _destinationController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _descriptionController = TextEditingController();

  PlatformFile? _selectedFile;
  bool _isUploading = false;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedTravelerType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isSmallPhone = screenWidth < 360;

    return Scaffold(
      // ✅ ADAPTIVE BACKGROUND
      backgroundColor: colorScheme.surfaceVariant,
      appBar: AppBar(
        title: Text(
          'New Itinerary',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
          ),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: colorScheme.onPrimary),
            onPressed: () => _showInfoDialog(context, theme),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isTablet ? 28 : 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildResponsiveInputCard(
                label: 'Trip Title *',
                child: TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Paris Family Vacation 2025',
                    border: InputBorder.none,
                    filled: true,
                    fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                    contentPadding: EdgeInsets.all(isTablet ? 24 : 20),
                  ),
                  validator: (value) => value?.trim().isEmpty ?? true ? 'Title required' : null,
                  style: theme.textTheme.titleMedium,
                ),
                theme: theme,
                colorScheme: colorScheme,
                isTablet: isTablet,
              ),
              SizedBox(height: isTablet ? 24 : 20),

              _buildResponsiveInputCard(
                label: 'Destination *',
                child: TextFormField(
                  controller: _destinationController,
                  decoration: InputDecoration(
                    hintText: 'Paris, France',
                    prefixIcon: Icon(Icons.location_on, color: colorScheme.primary),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                    contentPadding: EdgeInsets.all(isTablet ? 24 : 20),
                  ),
                  validator: (value) => value?.trim().isEmpty ?? true ? 'Destination required' : null,
                ),
                theme: theme,
                colorScheme: colorScheme,
                isTablet: isTablet,
              ),
              SizedBox(height: isTablet ? 24 : 20),

              _buildDateRangeCard(theme, colorScheme, isTablet),
              SizedBox(height: isTablet ? 24 : 20),

              _buildResponsiveInputCard(
                label: 'Traveler Type',
                child: DropdownButtonFormField<String>(
                  value: _selectedTravelerType,
                  decoration: InputDecoration(
                    hintText: 'Solo / Family / Business',
                    prefixIcon: Icon(Icons.people_outline, color: colorScheme.primary),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                    contentPadding: EdgeInsets.all(isTablet ? 24 : 20),
                  ),
                  items: ['Solo', 'Family', 'Couple', 'Business', 'Group']
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedTravelerType = value),
                  style: theme.textTheme.bodyLarge,
                ),
                theme: theme,
                colorScheme: colorScheme,
                isTablet: isTablet,
              ),
              SizedBox(height: isTablet ? 24 : 20),

              _buildResponsiveInputCard(
                label: 'Description',
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Add notes about your trip...',
                    border: InputBorder.none,
                    filled: true,
                    fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                    contentPadding: EdgeInsets.all(isTablet ? 24 : 20),
                    alignLabelWithHint: true,
                  ),
                ),
                theme: theme,
                colorScheme: colorScheme,
                isTablet: isTablet,
              ),
              SizedBox(height: isTablet ? 32 : 24),

              _buildResponsiveFileUploadCard(theme, colorScheme, isTablet),
              SizedBox(height: isTablet ? 40 : 32),

              _buildResponsiveUploadButton(theme, colorScheme, isTablet),
              SizedBox(height: isTablet ? 24 : 20),

              _buildResponsiveInfoCard(theme, colorScheme, isTablet),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveInputCard({
    required String label,
    required Widget child,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required bool isTablet,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(isTablet ? 28 : 20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.15),
            blurRadius: isTablet ? 30 : 20,
            offset: Offset(0, isTablet ? 10 : 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isTablet ? 28 : 24,
          isTablet ? 28 : 24,
          isTablet ? 28 : 24,
          isTablet ? 20 : 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            SizedBox(height: isTablet ? 16 : 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeCard(ThemeData theme, ColorScheme colorScheme, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(isTablet ? 28 : 20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.15),
            blurRadius: isTablet ? 30 : 20,
            offset: Offset(0, isTablet ? 10 : 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 28 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Travel Dates *',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            SizedBox(height: isTablet ? 16 : 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectStartDate(context),
                    child: Container(
                      height: isTablet ? 68 : 60,
                      padding: EdgeInsets.all(isTablet ? 20 : 16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                        border: Border.all(
                          color: _startDate != null ? colorScheme.primary : colorScheme.outline,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: colorScheme.primary),
                          SizedBox(width: 12),
                          Text(
                            _startDateController.text.isEmpty ? 'Start Date' : _startDateController.text,
                            style: TextStyle(
                              color: _startDate != null ? colorScheme.primary : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isTablet ? 16 : 12),
                Text('-', style: TextStyle(fontSize: isTablet ? 24 : 20, fontWeight: FontWeight.bold, color: colorScheme.primary)),
                SizedBox(width: isTablet ? 16 : 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectEndDate(context),
                    child: Container(
                      height: isTablet ? 68 : 60,
                      padding: EdgeInsets.all(isTablet ? 20 : 16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                        border: Border.all(
                          color: _endDate != null ? colorScheme.primary : colorScheme.outline,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: colorScheme.primary),
                          SizedBox(width: 12),
                          Text(
                            _endDateController.text.isEmpty ? 'End Date' : _endDateController.text,
                            style: TextStyle(
                              color: _endDate != null ? colorScheme.primary : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveFileUploadCard(ThemeData theme, ColorScheme colorScheme, bool isTablet) {
    return GestureDetector(
      onTap: _isUploading ? null : _pickFile,
      child: Container(
        height: isTablet ? 200 : 180,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(isTablet ? 28 : 20),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.15),
              blurRadius: isTablet ? 30 : 20,
              offset: Offset(0, isTablet ? 10 : 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedFile == null ? Icons.upload_file_outlined : Icons.check_circle,
              size: isTablet ? 80 : 64,
              color: _selectedFile == null ? colorScheme.primary.withOpacity(0.5) : colorScheme.primary,
            ),
            SizedBox(height: isTablet ? 20 : 16),
            Text(
              _selectedFile == null ? 'Choose Itinerary File' : '✅ ${_selectedFile!.name}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (_selectedFile != null) ...[
              SizedBox(height: 8),
              Text(
                '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
            SizedBox(height: isTablet ? 16 : 12),
            Text(
              'PDF, CSV, JSON (Max 10MB)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.primary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveUploadButton(ThemeData theme, ColorScheme colorScheme, bool isTablet) {
    final isFormValid = _formKey.currentState?.validate() == true &&
        _titleController.text.isNotEmpty &&
        _destinationController.text.isNotEmpty &&
        _startDate != null &&
        _endDate != null;

    return Container(
      height: isTablet ? 72 : 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isFormValid && _selectedFile != null && !_isUploading
              ? [colorScheme.primary, colorScheme.primaryContainer]
              : [colorScheme.onSurfaceVariant.withOpacity(0.3), colorScheme.onSurfaceVariant.withOpacity(0.2)],
        ),
        borderRadius: BorderRadius.circular(isTablet ? 32 : 24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(isFormValid && _selectedFile != null ? 0.4 : 0.1),
            blurRadius: isTablet ? 35 : 25,
            offset: Offset(0, isTablet ? 16 : 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(isTablet ? 32 : 24),
          onTap: isFormValid && _selectedFile != null && !_isUploading
              ? () async {
            if (_formKey.currentState!.validate()) {
              await _uploadItinerary();
            }
          }
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isUploading)
                SizedBox(
                  width: isTablet ? 28 : 24,
                  height: isTablet ? 28 : 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(colorScheme.onPrimary),
                  ),
                )
              else
                Icon(Icons.cloud_upload, size: isTablet ? 28 : 24, color: colorScheme.onPrimary),
              SizedBox(width: isTablet ? 16 : 12),
              Text(
                _isUploading ? 'Uploading...' : 'Upload Itinerary',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveInfoCard(ThemeData theme, ColorScheme colorScheme, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(isTablet ? 24 : 16),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline,
            color: colorScheme.primary,
            size: isTablet ? 28 : 24,
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: Text(
              'Supports PDF, CSV, JSON files up to 10MB. AI will analyze your file.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('📄 File Formats', style: theme.textTheme.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ PDF, CSV, JSON supported'),
            SizedBox(height: 8),
            Text('📏 Max 10MB file size'),
            SizedBox(height: 8),
            Text('🤖 AI auto-analysis'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it!'),
          ),
        ],
      ),
    );
  }

  // ALL ORIGINAL METHODS SAME - _pickFile, _selectStartDate, _selectEndDate, _uploadItinerary, _resetForm
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'csv', 'json'],
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.size > 10 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('File too large! Max 10MB'), backgroundColor: Colors.red));
          return;
        }
        setState(() => _selectedFile = file);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ ${file.name} selected'), backgroundColor: Colors.green));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2027),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _startDateController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime(2027),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
        _endDateController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _uploadItinerary() async {
    setState(() => _isUploading = true);
    try {
      final response = await ApiService.uploadItinerary(
        path: "itinerary/upload",
        title: _titleController.text.trim(),
        destination: _destinationController.text.trim(),
        startDate: _startDate?.toIso8601String(),
        endDate: _endDate?.toIso8601String(),
        travelerType: _selectedTravelerType,
        description: _descriptionController.text.trim(),
        file: _selectedFile!,
      );

      if (response['status'] == true) {
        _resetForm();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Itinerary created successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ ${response['message'] ?? 'Upload failed'}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Network error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _resetForm() {
    _titleController.clear();
    _destinationController.clear();
    _startDateController.clear();
    _endDateController.clear();
    _descriptionController.clear();
    _selectedFile = null;
    _startDate = null;
    _endDate = null;
    _selectedTravelerType = null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _destinationController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
