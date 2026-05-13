import 'package:flutter/material.dart';
import 'package:everroute/core/theme/app_theme.dart';

/// Circular avatar + edit/upload affordance, driven by [imageUrlController].
///
/// Used on My Profile and Add Staff flows. [onUploadImage] runs when the user
/// taps the avatar or the accent FAB (e.g. pick from gallery then upload).
class ProfileImagePicker extends StatelessWidget {
  const ProfileImagePicker({
    super.key,
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
                  width: 80,
                  height: 80,
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
                      width: 28,
                      height: 28,
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
