import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SampleFoodPreset {
  final String id;
  final String name;
  final IconData icon;
  final List<Color> gradient;

  const SampleFoodPreset({
    required this.id,
    required this.name,
    required this.icon,
    required this.gradient,
  });

  static const List<SampleFoodPreset> presets = [
    SampleFoodPreset(
      id: 'preset:rice_curry',
      name: 'Rice & Curry Platter',
      icon: Icons.rice_bowl,
      gradient: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
    ),
    SampleFoodPreset(
      id: 'preset:bakery_box',
      name: 'Fresh Bakery & Bread',
      icon: Icons.bakery_dining,
      gradient: [Color(0xFFE65100), Color(0xFFBF360C)],
    ),
    SampleFoodPreset(
      id: 'preset:veg_thali',
      name: 'Vegetable Thali / Dal Bhat',
      icon: Icons.dinner_dining,
      gradient: [Color(0xFF00897B), Color(0xFF004D40)],
    ),
    SampleFoodPreset(
      id: 'preset:momo_tray',
      name: 'Momo & Noodles Trays',
      icon: Icons.ramen_dining,
      gradient: [Color(0xFFD84315), Color(0xFF870000)],
    ),
    SampleFoodPreset(
      id: 'preset:fruit_salad',
      name: 'Fruit & Salad Platters',
      icon: Icons.eco,
      gradient: [Color(0xFF43A047), Color(0xFF2E7D32)],
    ),
    SampleFoodPreset(
      id: 'preset:banquet_trays',
      name: 'Catering Buffet Trays',
      icon: Icons.restaurant,
      gradient: [Color(0xFF1565C0), Color(0xFF0D47A1)],
    ),
  ];
}

class PhotoUploadArea extends StatelessWidget {
  final String? imagePath;
  final ValueChanged<String> onImageSelected;
  final VoidCallback onImageRemoved;

  const PhotoUploadArea({
    super.key,
    this.imagePath,
    required this.onImageSelected,
    required this.onImageRemoved,
  });

  void _showImageSourceSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Upload Food Photo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryEmerald.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: AppColors.primaryEmerald),
                ),
                title: const Text(
                  'Choose from Gallery / Files',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: const Text(
                  'JPG, PNG, or WEBP from your device',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickLocalImage(context);
                },
              ),
              const Divider(height: 20),
              const Text(
                'Or choose a food category preset:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: SampleFoodPreset.presets.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final preset = SampleFoodPreset.presets[i];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        onImageSelected(preset.id);
                      },
                      child: Container(
                        width: 110,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: preset.gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(preset.icon, color: Colors.white, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              preset.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickLocalImage(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final path = result.files.single.path;
        if (path != null && path.isNotEmpty) {
          onImageSelected(path);
        } else if (result.files.single.name.isNotEmpty) {
          onImageSelected(result.files.single.name);
        }
      }
    } catch (_) {
      // If native file picker fails, fallback to preset options
      if (context.mounted) {
        _showImageSourceSelector(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;

    if (hasImage) {
      final isPreset = imagePath!.startsWith('preset:');
      SampleFoodPreset? preset;
      if (isPreset) {
        preset = SampleFoodPreset.presets.firstWhere(
          (p) => p.id == imagePath,
          orElse: () => SampleFoodPreset.presets.first,
        );
      }

      final isLocalFile = !isPreset && !kIsWeb && File(imagePath!).existsSync();
      final displayName = isPreset
          ? preset!.name
          : imagePath!.split(Platform.pathSeparator).last;

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primaryEmerald.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 64,
                height: 64,
                child: isPreset
                    ? Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: preset!.gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Icon(preset.icon, color: Colors.white, size: 28),
                      )
                    : isLocalFile
                        ? Image.file(
                            File(imagePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: const Color(0xFFE8F5E9),
                              child: const Icon(Icons.image, color: AppColors.primaryEmerald),
                            ),
                          )
                        : Container(
                            color: const Color(0xFFE8F5E9),
                            child: const Icon(Icons.check_circle, color: AppColors.primaryEmerald, size: 28),
                          ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.primaryEmerald, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Photo attached',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showImageSourceSelector(context),
                        child: const Text(
                          'Change photo',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: onImageRemoved,
                        child: const Text(
                          'Remove',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showImageSourceSelector(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Icon(
                Icons.add_a_photo_outlined,
                size: 32,
                color: AppColors.primaryEmerald.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload a photo of the food',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primaryEmerald.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Tap to choose gallery image or food preset',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
