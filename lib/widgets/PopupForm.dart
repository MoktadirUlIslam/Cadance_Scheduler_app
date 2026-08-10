// lib/utilites/PopupForm.dart
import 'package:flutter/material.dart';
import 'package:pomodoro/utilites/app_colors.dart';

class UniversalPopupForm extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<FormFieldConfig> fields;
  final String primaryButtonText;
  final String? secondaryButtonText;
  final VoidCallback? onSecondaryButtonPressed;
  final Function(Map<String, dynamic>) onSubmit;
  final Color? accentColor;

  const UniversalPopupForm({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.fields,
    required this.primaryButtonText,
    this.secondaryButtonText,
    this.onSecondaryButtonPressed,
    required this.onSubmit,
    this.accentColor,
  });

  @override
  State<UniversalPopupForm> createState() => _UniversalPopupFormState();
}

class _UniversalPopupFormState extends State<UniversalPopupForm>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {};
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    // Initialize form data and controllers
    for (var field in widget.fields) {
      _formData[field.key] = field.initialValue ?? '';

      // Create controllers for text fields
      if (field.type == FormFieldType.text) {
        _controllers[field.key] = TextEditingController(
          text: field.initialValue?.toString() ?? '',
        );
      }
    }

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    // Dispose all controllers
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleSubmit() async {
    // Dismiss keyboard before submitting
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Update form data from controllers
      for (var entry in _controllers.entries) {
        _formData[entry.key] = entry.value.text;
      }

      setState(() => _isLoading = true);
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        widget.onSubmit(_formData);
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accentColor = widget.accentColor ?? AppColors.primaryLight;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: Colors.black54,
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.darkCard : AppColors.card,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.2),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(24),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                widget.icon ?? Icons.timer,
                                color: accentColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? AppColors.darkInk : AppColors.ink,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Subtitle
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              widget.subtitle!,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDarkMode
                                    ? AppColors.darkInkSoft
                                    : AppColors.inkSoft,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Form fields
                        Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: widget.fields.map((field) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildFormField(field, isDarkMode, accentColor),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Fixed bottom buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Submit button
                      GestureDetector(
                        onTap: _isLoading ? null : _handleSubmit,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [accentColor, accentColor.withOpacity(0.8)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : Text(
                              widget.primaryButtonText,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Secondary button
                      if (widget.secondaryButtonText != null) ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            widget.onSecondaryButtonPressed?.call();
                            Navigator.of(context).pop();
                          },
                          child: Center(
                            child: Text(
                              widget.secondaryButtonText!,
                              style: TextStyle(
                                color: isDarkMode
                                    ? AppColors.darkInkSoft
                                    : AppColors.inkSoft,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(
      FormFieldConfig field, bool isDarkMode, Color accentColor) {
    switch (field.type) {
      case FormFieldType.text:
        return _buildTextField(field, isDarkMode, accentColor);
      case FormFieldType.custom:
        return field.customWidget ?? const SizedBox.shrink();
      case FormFieldType.switch_:
      case FormFieldType.dropdown:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTextField(
      FormFieldConfig field, bool isDarkMode, Color accentColor) {
    // Use controller if it exists, otherwise create one
    final controller = _controllers[field.key] ??
        TextEditingController(text: field.initialValue?.toString() ?? '');

    // If we just created it, add it to the map
    if (!_controllers.containsKey(field.key)) {
      _controllers[field.key] = controller;
    }

    return TextFormField(
      controller: controller,
      keyboardType: field.keyboardType,
      decoration: InputDecoration(
        hintText: field.hint,
        hintStyle: TextStyle(
          color: (isDarkMode ? Colors.white54 : Colors.black38),
          fontSize: 14,
        ),
        prefixIcon: Icon(field.prefixIcon, size: 18, color: accentColor),
        filled: true,
        fillColor: isDarkMode ? AppColors.darkSurface : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
      style: TextStyle(
        color: isDarkMode ? AppColors.darkInk : AppColors.ink,
        fontSize: 14,
      ),
      validator: field.validator,
      onSaved: (value) {
        // Update form data when saved
        _formData[field.key] = controller.text;
      },
    );
  }
}

class FormFieldConfig {
  final String key;
  final FormFieldType type;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final dynamic initialValue;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<Map<String, dynamic>>? options;
  final Widget? customWidget;

  const FormFieldConfig({
    required this.key,
    required this.type,
    this.label,
    this.hint,
    this.prefixIcon,
    this.initialValue,
    this.validator,
    this.keyboardType,
    this.options,
    this.customWidget,
  });
}

enum FormFieldType {
  text,
  switch_,
  dropdown,
  custom,
}