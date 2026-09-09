import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'cloudinary_config.dart';

class CloudinaryService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  /// Uploads an image file to Cloudinary using an unsigned upload preset.
  /// Reports upload progress via [onProgress] (0.0 to 1.0).
  Future<String> uploadImage({
    required XFile file,
    Function(double progress)? onProgress,
  }) async {
    if (!CloudinaryConfig.isConfigured) {
      throw Exception(
        'Cloudinary is not configured yet! Please add your Cloud Name and Unsigned Preset in lib/core/network/cloudinary_config.dart, or select a preset / enter an image URL.',
      );
    }

    try {
      final String fileName = file.name.isNotEmpty ? file.name : 'event_poster_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final MultipartFile multipartFile;
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        multipartFile = MultipartFile.fromBytes(bytes, filename: fileName);
      } else {
        multipartFile = await MultipartFile.fromFile(file.path, filename: fileName);
      }

      final formData = FormData.fromMap({
        'file': multipartFile,
        'upload_preset': CloudinaryConfig.uploadPreset,
        'folder': CloudinaryConfig.folder,
      });

      final response = await _dio.post(
        CloudinaryConfig.uploadUrl,
        data: formData,
        onSendProgress: (int sent, int total) {
          if (total > 0 && onProgress != null) {
            final progress = sent / total;
            onProgress(progress);
          }
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final secureUrl = response.data['secure_url'] as String?;
        if (secureUrl != null && secureUrl.isNotEmpty) {
          return secureUrl;
        }
      }

      throw Exception('Upload completed but secure URL was not returned.');
    } on DioException catch (e) {
      debugPrint('Cloudinary DioException: ${e.response?.data ?? e.message}');
      final errorMessage = e.response?.data?['error']?['message'] ?? e.message;
      throw Exception('Cloudinary upload failed: $errorMessage');
    } catch (e) {
      debugPrint('Cloudinary upload error: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Appends Cloudinary auto-optimization parameters if the URL is from Cloudinary
  static String getOptimizedUrl(String originalUrl, {int width = 800}) {
    if (originalUrl.contains('res.cloudinary.com')) {
      return originalUrl.replaceFirst('/upload/', '/upload/f_auto,q_auto,w_$width/');
    }
    return originalUrl;
  }
}
