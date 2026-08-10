// lib/screens/Profile/dialogs/edit_profile_dialog.dart

import 'package:flutter/material.dart';
import '../../../core/data_provider.dart';
import '../../../models/profile_model.dart';
import '../../../utilites/app_colors.dart';
import '../../../widgets/PopupForm.dart';

class EditProfileDialog extends StatefulWidget {
  final DataProvider dataProvider;

  const EditProfileDialog({super.key, required this.dataProvider});

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  String? gender;
  String? occupation;

  @override
  void initState() {
    super.initState();
    final profile = widget.dataProvider.profile;

    // Set initial values
    gender = (profile.gender != 'Not set' && profile.gender != null)
        ? profile.gender
        : null;
    occupation = (profile.occupation != 'Not set' && profile.occupation != null)
        ? profile.occupation
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.dataProvider.profile;
    final username = widget.dataProvider.username ?? '';

    // Configure form fields
    final fields = [
      FormFieldConfig(
        key: 'name',
        type: FormFieldType.text,
        hint: 'Enter your name',
        prefixIcon: Icons.person_outline,
        initialValue: username,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your name';
          }
          return null;
        },
        keyboardType: TextInputType.text,
      ),
      FormFieldConfig(
        key: 'mobile',
        type: FormFieldType.text,
        hint: 'Enter mobile number',
        prefixIcon: Icons.phone_outlined,
        initialValue: profile.mobile != 'Not set' ? profile.mobile : '',
        keyboardType: TextInputType.phone,
      ),
      FormFieldConfig(
        key: 'age',
        type: FormFieldType.text,
        hint: 'Enter your age',
        prefixIcon: Icons.cake_outlined,
        initialValue: profile.age?.toString() ?? '',
        validator: (value) {
          if (value != null && value.isNotEmpty) {
            if (int.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            final age = int.parse(value);
            if (age < 1 || age > 120) {
              return 'Please enter a valid age (1-120)';
            }
          }
          return null;
        },
        keyboardType: TextInputType.number,
      ),
      // Custom field for Gender dropdown
      FormFieldConfig(
        key: 'gender',
        type: FormFieldType.custom,
        customWidget: _buildCustomDropdown(
          label: 'Gender',
          items: ['Male', 'Female', 'Rather not say'],
          selected: gender,
          onChanged: (value) => setState(() => gender = value),
          isDarkMode: Theme.of(context).brightness == Brightness.dark,
        ),
      ),
      // Custom field for Occupation dropdown
      FormFieldConfig(
        key: 'occupation',
        type: FormFieldType.custom,
        customWidget: _buildCustomDropdown(
          label: 'Occupation',
          items: ['Student', 'Employee', 'Others'],
          selected: occupation,
          onChanged: (value) => setState(() => occupation = value),
          isDarkMode: Theme.of(context).brightness == Brightness.dark,
        ),
      ),
      FormFieldConfig(
        key: 'address',
        type: FormFieldType.text,
        hint: 'Enter your address',
        prefixIcon: Icons.home_outlined,
        initialValue: profile.address != 'Not set' ? profile.address : '',
        keyboardType: TextInputType.text,
      ),
    ];

    return UniversalPopupForm(
      title: 'Edit Profile',
      subtitle: 'Update your personal information',
      icon: Icons.edit_outlined,
      fields: fields,
      primaryButtonText: 'Save Changes',
      secondaryButtonText: 'Cancel',
      accentColor: AppColors.primaryLight,
      onSubmit: (data) async {
        await _saveProfile(data);
      },
      onSecondaryButtonPressed: () {
        // Just close the dialog
      },
    );
  }

  Widget _buildCustomDropdown({
    required String label,
    required List<String> items,
    required String? selected,
    required Function(String?) onChanged,
    required bool isDarkMode,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: selected,
        dropdownColor: isDarkMode ? AppColors.darkCard : AppColors.card,
        style: TextStyle(
          color: isDarkMode ? AppColors.darkInk : AppColors.ink,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'Select $label',
          hintStyle: TextStyle(
            color: isDarkMode ? Colors.white54 : Colors.black38,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            label == 'Gender' ? Icons.person_outline : Icons.work_outline,
            size: 18,
            color: AppColors.primaryLight,
          ),
          filled: true,
          fillColor: isDarkMode ? AppColors.darkSurface : Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _saveProfile(Map<String, dynamic> data) async {
    // Parse age
    int? age;
    if (data['age'] != null && data['age'].toString().isNotEmpty) {
      age = int.tryParse(data['age'].toString());
    }

    // Create updated profile
    final updatedProfile = ProfileModel(
      mobile: data['mobile']?.toString().isEmpty ?? true ? 'Not set' : data['mobile'].toString(),
      age: age,
      gender: gender ?? 'Not set',
      occupation: occupation ?? 'Not set',
      address: data['address']?.toString().isEmpty ?? true ? 'Not set' : data['address'].toString(),
    );

    try {
      // Update profile using DataProvider
      final success = await widget.dataProvider.updateProfile(updatedProfile);

      if (success && mounted) {
        // Update username if changed
        final name = data['name']?.toString() ?? '';
        if (name.isNotEmpty && name != widget.dataProvider.username) {
          await widget.dataProvider.updateUsername(name);
        }

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully! 🎉'),
            backgroundColor: AppColors.successLight,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                widget.dataProvider.profileError ?? 'Failed to update profile'
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
}