import 'package:flutter/material.dart';
import 'package:everroute/core/theme/app_theme.dart';
import 'package:everroute/ui/widgets/app_buttons.dart';
import 'package:image_picker/image_picker.dart';

/// Called after the user chooses **Camera** or **Gallery** from the picker sheet.
typedef ProfileImagePickCallback = Future<void> Function(ImageSource source);

/// Circular image + edit/upload affordance, driven by [imageUrlController].
///
/// Tapping the main preview opens the **gallery** directly. Tapping the accent
/// FAB (edit/upload) opens a bottom sheet to choose **Camera** or **Gallery**,
/// then invokes [onPickImage].
///
/// Used for profile photos, staff photos, and funeral-home logos.
class ProfileImagePicker extends StatelessWidget {
  const ProfileImagePicker({
    super.key,
    required this.imageUrlController,
    required this.uploading,
    required this.disabled,
    required this.onPickImage,
    this.emptyIcon = Icons.person_outline_rounded,
  });

  final TextEditingController imageUrlController;
  final bool uploading;
  final bool disabled;
  final ProfileImagePickCallback onPickImage;

  /// Shown when [imageUrlController] has no URL.
  final IconData emptyIcon;

  Future<void> _openSourceSheet(BuildContext context) async {
    if (disabled || uploading) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _ImageSourceChoiceSheet(),
    );
    if (source != null && context.mounted) {
      await onPickImage(source);
    }
  }

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
                onTap: disabled || uploading
                    ? null
                    : () async {
                        await onPickImage(ImageSource.gallery);
                      },
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
                        : Icon(
                            emptyIcon,
                            size: 32,
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
                    onTap: disabled || uploading
                        ? null
                        : () => _openSourceSheet(context),
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

/// Branded sheet: Camera vs Gallery, then Cancel.
class _ImageSourceChoiceSheet extends StatelessWidget {
  const _ImageSourceChoiceSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add photo',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Take a new picture or choose one from your gallery.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          AppPrimaryButton(
            label: 'Camera',
            icon: Icons.photo_camera_rounded,
            onPressed: () => Navigator.of(context).pop(ImageSource.camera),
          ),
          const SizedBox(height: 10),
          AppPrimaryButton(
            label: 'Gallery',
            icon: Icons.photo_library_rounded,
            onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
          const SizedBox(height: 10),
          AppAccentButton(
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
