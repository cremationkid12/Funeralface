import 'package:flutter/material.dart';
import 'package:everroute/core/theme/app_theme.dart';
import 'package:everroute/ui/widgets/app_buttons.dart';
import 'package:google_fonts/google_fonts.dart';

class MyProfileTab extends StatelessWidget {
  const MyProfileTab({
    super.key,
    required this.formKey,
    required this.imageUrlController,
    required this.nameController,
    required this.phoneController,
    required this.emailController,
    required this.bioController,
    required this.role,
    required this.saving,
    required this.imageUploading,
    required this.onUploadImage,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController imageUrlController;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController bioController;
  final String role;
  final bool saving;
  final bool imageUploading;
  final VoidCallback onUploadImage;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final roleLabel = role == 'admin' ? 'Admin' : 'User';
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
                _ProfileImagePicker(
                  imageUrlController: imageUrlController,
                  uploading: imageUploading,
                  disabled: saving || imageUploading,
                  onUploadImage: onUploadImage,
                ),
                const SizedBox(height: 20),
                _SettingsField(
                  label: 'My Name',
                  controller: nameController,
                  hint: 'eg. John Smith',
                  icon: Icons.person_outline_rounded,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _SettingsField(
                  label: 'Phone',
                  controller: phoneController,
                  hint: '555-1234',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _SettingsField(
                  label: 'Email',
                  controller: emailController,
                  hint: 'eg. john@example.com',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _FieldLabel('Bio'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: bioController,
                  maxLines: 2,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Write a short bio ...',
                    hintStyle: GoogleFonts.poppins(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 16),
                _FieldLabel('Role'),
                const SizedBox(height: 6),
                Container(
                  height: 50,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    roleLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppPrimaryButton(label: 'Save', busy: saving, onPressed: onSave),
        ],
      ),
    );
  }
}

class _ProfileImagePicker extends StatelessWidget {
  const _ProfileImagePicker({
    required this.imageUrlController,
    required this.uploading,
    required this.disabled,
    required this.onUploadImage,
  });

  final TextEditingController imageUrlController;
  final bool uploading;
  final bool disabled;
  final VoidCallback onUploadImage;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: imageUrlController,
      builder: (context, value, _) {
        final url = value.text.trim();
        final hasImage = url.isNotEmpty;
        return Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: disabled ? null : onUploadImage,
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                    color: AppColors.background,
                  ),
                  child: ClipOval(
                    child: hasImage
                        ? Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image_outlined,
                              size: 28,
                              color: AppColors.textSecondary,
                            ),
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              );
                            },
                          )
                        : const Icon(
                            Icons.person_outline_rounded,
                            size: 34,
                            color: AppColors.textSecondary,
                          ),
                  ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: disabled ? null : onUploadImage,
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: uploading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                hasImage
                                    ? Icons.edit_rounded
                                    : Icons.upload_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SettingsField extends StatelessWidget {
  const _SettingsField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
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
