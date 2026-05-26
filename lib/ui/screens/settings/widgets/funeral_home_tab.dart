import 'package:flutter/material.dart';
import 'package:everroute/core/theme/app_theme.dart';
import 'package:everroute/ui/widgets/profile_image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

class FuneralHomeTab extends StatelessWidget {
  const FuneralHomeTab({
    super.key,
    required this.formKey,
    required this.directorImageUrlController,
    required this.directorNameController,
    required this.directorPhoneController,
    required this.directorEmailController,
    required this.nameController,
    required this.phoneController,
    required this.addressController,
    required this.logoUrlController,
    required this.defaultMessageController,
    required this.saving,
    required this.directorImageUploading,
    required this.logoUploading,
    required this.homeEditable,
    required this.onSave,
    required this.onPickDirectorImage,
    required this.onPickLogo,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController directorImageUrlController;
  final TextEditingController directorNameController;
  final TextEditingController directorPhoneController;
  final TextEditingController directorEmailController;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController logoUrlController;
  final TextEditingController defaultMessageController;
  final bool saving;
  final bool directorImageUploading;
  final bool logoUploading;
  final bool homeEditable;
  final VoidCallback onSave;
  final ProfileImagePickCallback onPickDirectorImage;
  final ProfileImagePickCallback onPickLogo;

  @override
  Widget build(BuildContext context) {
    final fieldsDisabled = saving || directorImageUploading || logoUploading;

    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SectionHeading('Funeral Director Information'),
                const SizedBox(height: 12),
                ProfileImagePicker(
                  imageUrlController: directorImageUrlController,
                  uploading: directorImageUploading,
                  disabled: !homeEditable || fieldsDisabled,
                  onPickImage: onPickDirectorImage,
                ),
                const SizedBox(height: 20),
                _SettingsField(
                  label: 'Director Name',
                  controller: directorNameController,
                  hint: 'eg. John Smith',
                  icon: Icons.person_outline_rounded,
                  enabled: homeEditable && !fieldsDisabled,
                  validator: homeEditable
                      ? (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null
                      : null,
                ),
                const SizedBox(height: 16),
                _SettingsField(
                  label: 'Phone',
                  controller: directorPhoneController,
                  hint: '555-1234',
                  icon: Icons.phone_outlined,
                  enabled: homeEditable && !fieldsDisabled,
                  keyboardType: TextInputType.phone,
                  validator: homeEditable
                      ? (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null
                      : null,
                ),
                const SizedBox(height: 16),
                _SettingsField(
                  label: 'Email',
                  controller: directorEmailController,
                  hint: 'eg. john@example.com',
                  icon: Icons.mail_outline_rounded,
                  enabled: homeEditable && !fieldsDisabled,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),
                const _SectionHeading('Family Message (OPTIONAL)'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: defaultMessageController,
                  enabled: homeEditable && !fieldsDisabled,
                  maxLines: 3,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Write here ...',
                    hintStyle: GoogleFonts.poppins(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 24),
                const _SectionHeading('Funeral Home Information'),
                const SizedBox(height: 12),
                ProfileImagePicker(
                  imageUrlController: logoUrlController,
                  uploading: logoUploading,
                  disabled: !homeEditable || fieldsDisabled,
                  onPickImage: onPickLogo,
                  emptyIcon: Icons.home_work_outlined,
                ),
                const SizedBox(height: 20),
                _SettingsField(
                  label: 'Funeral Family Home Name',
                  controller: nameController,
                  hint: "eg. Emma's House",
                  icon: Icons.home_work_outlined,
                  enabled: homeEditable && !fieldsDisabled,
                  validator: homeEditable
                      ? (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null
                      : null,
                ),
                const SizedBox(height: 16),
                _SettingsField(
                  label: 'Phone',
                  controller: phoneController,
                  hint: '555-1234',
                  icon: Icons.phone_outlined,
                  enabled: homeEditable && !fieldsDisabled,
                  keyboardType: TextInputType.phone,
                  validator: homeEditable
                      ? (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null
                      : null,
                ),
                const SizedBox(height: 16),
                _SettingsField(
                  label: 'Address',
                  controller: addressController,
                  hint: 'eg. 123 Oak Street',
                  icon: Icons.location_on_outlined,
                  enabled: homeEditable && !fieldsDisabled,
                  validator: homeEditable
                      ? (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: (fieldsDisabled || !homeEditable) ? null : onSave,
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save'),
            ),
          ),
          if (!homeEditable) ...[
            const SizedBox(height: 8),
            Text(
              'Admin role is required to edit funeral home information.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _SettingsField extends StatelessWidget {
  const _SettingsField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    this.enabled = true,
    this.keyboardType,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool enabled;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          style: GoogleFonts.poppins(fontSize: 14),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: Icon(icon, color: AppColors.accent, size: 18),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    );
  }
}
