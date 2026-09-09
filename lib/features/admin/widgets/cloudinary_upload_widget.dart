import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/cloudinary_config.dart';
import '../../../core/network/cloudinary_service.dart';
import '../../../core/theme/app_theme.dart';

class CloudinaryUploadWidget extends StatefulWidget {
  final String currentImageUrl;
  final ValueChanged<String> onImageUrlChanged;

  const CloudinaryUploadWidget({
    super.key,
    required this.currentImageUrl,
    required this.onImageUrlChanged,
  });

  @override
  State<CloudinaryUploadWidget> createState() => _CloudinaryUploadWidgetState();
}

class _CloudinaryUploadWidgetState extends State<CloudinaryUploadWidget> {
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final TextEditingController _urlController = TextEditingController();

  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _uploadError;
  bool _showCustomUrlField = false;

  @override
  void initState() {
    super.initState();
    _urlController.text = widget.currentImageUrl;
  }

  @override
  void didUpdateWidget(covariant CloudinaryUploadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentImageUrl != widget.currentImageUrl) {
      _urlController.text = widget.currentImageUrl;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    setState(() {
      _uploadError = null;
    });

    if (!CloudinaryConfig.isConfigured) {
      _showCloudinaryConfigPrompt();
      return;
    }

    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (file == null) return;

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      final String uploadedUrl = await _cloudinaryService.uploadImage(
        file: file,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      setState(() {
        _isUploading = false;
      });

      widget.onImageUrlChanged(uploadedUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Poster uploaded successfully to Cloudinary!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.scaffoldBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppTheme.neonOrange, width: 0.8),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SELECT POSTER SOURCE',
                  style: GoogleFonts.orbitron(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, color: AppTheme.neonOrange),
                  title: Text(
                    'Photo Gallery',
                    style: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  subtitle: Text(
                    'Upload image from device storage to Cloudinary',
                    style: GoogleFonts.rajdhani(color: AppTheme.metallicMuted),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  tileColor: AppTheme.cardSurface,
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickAndUpload(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.cyberAmber),
                  title: Text(
                    'Camera',
                    style: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  subtitle: Text(
                    'Take a new photo with device camera',
                    style: GoogleFonts.rajdhani(color: AppTheme.metallicMuted),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  tileColor: AppTheme.cardSurface,
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickAndUpload(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCloudinaryConfigPrompt() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.scaffoldBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.cyberAmber, width: 1),
          ),
          title: Row(
            children: [
              const Icon(Icons.cloud_upload_outlined, color: AppTheme.cyberAmber),
              const SizedBox(width: 10),
              Text(
                'Cloudinary Setup',
                style: GoogleFonts.orbitron(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cloudinary credentials are not configured yet.\n\nYou can:\n1. Paste a direct image URL or choose a preset right now.\n2. Or enter your Cloud Name and Unsigned Preset in lib/core/network/cloudinary_config.dart whenever ready!',
                style: GoogleFonts.rajdhani(fontSize: 14, color: AppTheme.metallicSilver, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'GOT IT',
                style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, color: AppTheme.neonOrange),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPresetPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppTheme.scaffoldBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.neonOrange, width: 1),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxHeight: 520, maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'POSTER PRESETS',
                      style: GoogleFonts.orbitron(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: Colors.white54),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: CloudinaryConfig.posterPresets.length,
                    itemBuilder: (context, index) {
                      final preset = CloudinaryConfig.posterPresets[index];
                      final isSelected = widget.currentImageUrl == preset['url'];

                      return InkWell(
                        onTap: () {
                          widget.onImageUrlChanged(preset['url']!);
                          Navigator.of(context).pop();
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppTheme.neonOrange : Colors.white24,
                              width: isSelected ? 2 : 0.8,
                            ),
                            image: DecorationImage(
                              image: NetworkImage(preset['url']!),
                              fit: BoxFit.cover,
                            ),
                          ),
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(9)),
                            ),
                            child: Text(
                              preset['title']!,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.rajdhani(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
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
    final hasImage = widget.currentImageUrl.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live Preview Canvas
        Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            color: const Color(0xFF130604),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasImage ? AppTheme.neonOrange.withValues(alpha: 0.6) : Colors.white24,
              width: 1.2,
            ),
            boxShadow: hasImage ? AppTheme.neonGlow(opacity: 0.15, blur: 12) : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasImage)
                  Image.network(
                    widget.currentImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.broken_image_outlined, color: Colors.white38, size: 36),
                          const SizedBox(height: 6),
                          Text(
                            'Unable to load preview image',
                            style: GoogleFonts.rajdhani(color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_photo_alternate_outlined, color: AppTheme.neonOrange, size: 40),
                        const SizedBox(height: 8),
                        Text(
                          'No Event Poster Selected',
                          style: GoogleFonts.rajdhani(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.metallicSilver,
                          ),
                        ),
                        Text(
                          'Upload via Cloudinary, choose a preset, or enter URL',
                          style: GoogleFonts.rajdhani(fontSize: 12, color: AppTheme.metallicMuted),
                        ),
                      ],
                    ),
                  ),

                // Uploading overlay
                if (_isUploading)
                  Container(
                    color: Colors.black.withValues(alpha: 0.8),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              color: AppTheme.neonOrange,
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Uploading to Cloudinary: ${(_uploadProgress * 100).toInt()}%',
                            style: GoogleFonts.rajdhani(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: LinearProgressIndicator(
                              value: _uploadProgress,
                              color: AppTheme.neonOrange,
                              backgroundColor: Colors.white12,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        if (_uploadError != null) ...[
          const SizedBox(height: 8),
          Text(
            _uploadError!,
            style: GoogleFonts.rajdhani(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],

        const SizedBox(height: 12),

        // Action Buttons Row
        Row(
          children: [
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                label: const Text('UPLOAD (CLOUDINARY)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonOrange,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.8),
                ),
                onPressed: _isUploading ? null : _showImageSourcePicker,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.collections_outlined, size: 16),
                label: const Text('PRESETS'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.8),
                ),
                onPressed: _showPresetPicker,
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Custom URL',
              icon: Icon(
                _showCustomUrlField ? Icons.link_off : Icons.link,
                color: _showCustomUrlField ? AppTheme.cyberAmber : AppTheme.metallicMuted,
                size: 22,
              ),
              onPressed: () => setState(() => _showCustomUrlField = !_showCustomUrlField),
            ),
          ],
        ),

        // Custom URL input toggle
        if (_showCustomUrlField) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _urlController,
            style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF140705),
              hintText: 'https://example.com/poster.jpg',
              hintStyle: GoogleFonts.rajdhani(color: Colors.white30, fontSize: 13),
              prefixIcon: const Icon(Icons.image, color: AppTheme.metallicMuted, size: 18),
              suffixIcon: IconButton(
                icon: const Icon(Icons.check, color: AppTheme.neonEmerald, size: 20),
                onPressed: () {
                  widget.onImageUrlChanged(_urlController.text.trim());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Poster URL updated!')),
                  );
                },
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.neonOrange),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onSubmitted: (val) => widget.onImageUrlChanged(val.trim()),
          ),
        ],
      ],
    );
  }
}
