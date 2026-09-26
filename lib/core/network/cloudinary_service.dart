import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'cloudinary_config.dart';

class CloudinaryService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 45),
    receiveTimeout: const Duration(seconds: 60),
  ));

  /// Computes a Cloudinary SHA-1 signature for signed uploads
  String _generateSignature(Map<String, dynamic> params) {
    final sortedKeys = params.keys.toList()..sort();
    final buffer = StringBuffer();
    for (final key in sortedKeys) {
      final value = params[key];
      if (value != null && value.toString().isNotEmpty) {
        if (buffer.isNotEmpty) buffer.write('&');
        buffer.write('$key=$value');
      }
    }
    buffer.write(CloudinaryConfig.apiSecret);
    return sha1.convert(utf8.encode(buffer.toString())).toString();
  }

  /// Uploads an image file (event poster/banner) to Cloudinary.
  /// Reports upload progress via [onProgress] (0.0 to 1.0).
  Future<String> uploadImage({
    required XFile file,
    Function(double progress)? onProgress,
  }) async {
    if (!CloudinaryConfig.isConfigured) {
      throw Exception(
        'Cloudinary cloud name is not set! Please enter your Cloud Name in settings.',
      );
    }

    try {
      final String fileName = file.name.isNotEmpty
          ? file.name
          : 'event_poster_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final MultipartFile multipartFile;
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        multipartFile = MultipartFile.fromBytes(bytes, filename: fileName);
      } else {
        multipartFile = await MultipartFile.fromFile(file.path, filename: fileName);
      }

      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final folder = CloudinaryConfig.folderPosters;

      final signParams = {
        'folder': folder,
        'timestamp': timestamp,
      };
      final signature = _generateSignature(signParams);

      final formData = FormData.fromMap({
        'file': multipartFile,
        'api_key': CloudinaryConfig.apiKey,
        'timestamp': timestamp,
        'folder': folder,
        'signature': signature,
      });

      final response = await _dio.post(
        CloudinaryConfig.imageUploadUrl,
        data: formData,
        onSendProgress: (int sent, int total) {
          if (total > 0 && onProgress != null) {
            onProgress(sent / total);
          }
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final secureUrl = response.data['secure_url'] as String?;
        if (secureUrl != null && secureUrl.isNotEmpty) {
          return secureUrl;
        }
      }

      throw Exception('Upload completed but secure URL was not returned by Cloudinary.');
    } on DioException catch (e) {
      debugPrint('Cloudinary Image DioException: ${e.response?.data ?? e.message}');
      final msg = e.response?.data?['error']?['message'] ?? e.message ?? 'Network error';
      throw Exception('Cloudinary upload failed: $msg');
    } catch (e) {
      debugPrint('Cloudinary image upload error: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Uploads a rulebook PDF file to Cloudinary.
  /// Reports upload progress via [onProgress] (0.0 to 1.0).
  Future<String> uploadRulebookPdf({
    required PlatformFile file,
    Function(double progress)? onProgress,
  }) async {
    if (!CloudinaryConfig.isConfigured) {
      throw Exception(
        'Cloudinary cloud name is not set! Please enter your Cloud Name in settings.',
      );
    }

    try {
      final String fileName = file.name.isNotEmpty
          ? file.name
          : 'rulebook_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final MultipartFile multipartFile;
      if (kIsWeb || file.path == null) {
        final bytes = await file.readAsBytes();
        multipartFile = MultipartFile.fromBytes(bytes, filename: fileName);
      } else {
        multipartFile = await MultipartFile.fromFile(file.path!, filename: fileName);
      }

      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final folder = CloudinaryConfig.folderRulebooks;

      final signParams = {
        'folder': folder,
        'timestamp': timestamp,
      };
      final signature = _generateSignature(signParams);

      final formData = FormData.fromMap({
        'file': multipartFile,
        'api_key': CloudinaryConfig.apiKey,
        'timestamp': timestamp,
        'folder': folder,
        'signature': signature,
      });

      // We upload to rawUploadUrl so Cloudinary handles PDF files seamlessly
      final response = await _dio.post(
        CloudinaryConfig.rawUploadUrl,
        data: formData,
        onSendProgress: (int sent, int total) {
          if (total > 0 && onProgress != null) {
            onProgress(sent / total);
          }
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final secureUrl = response.data['secure_url'] as String?;
        if (secureUrl != null && secureUrl.isNotEmpty) {
          return secureUrl;
        }
      }

      throw Exception('Upload completed but secure URL was not returned by Cloudinary.');
    } on DioException catch (e) {
      debugPrint('Cloudinary Rulebook DioException: ${e.response?.data ?? e.message}');
      final msg = e.response?.data?['error']?['message'] ?? e.message ?? 'Network error';
      throw Exception('Rulebook PDF upload failed: $msg');
    } catch (e) {
      debugPrint('Cloudinary rulebook upload error: $e');
      throw Exception('Failed to upload rulebook PDF: $e');
    }
  }

  /// Appends Cloudinary auto-optimization parameters if the URL is from Cloudinary
  static String getOptimizedUrl(String originalUrl, {int width = 800}) {
    if (originalUrl.contains('res.cloudinary.com') && !originalUrl.endsWith('.pdf')) {
      return originalUrl.replaceFirst('/upload/', '/upload/f_auto,q_auto,w_$width/');
    }
    return originalUrl;
  }
}
