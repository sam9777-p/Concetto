import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class PdfCacheService {
  // In-memory RAM cache for instant zero-latency retrieval
  static final Map<String, Uint8List> _memoryCache = {};
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 40),
      followRedirects: true,
      maxRedirects: 5,
    ),
  );

  /// Checks if the PDF is already stored in RAM
  static Uint8List? getFromMemory(String url) {
    final key = url.trim();
    return _memoryCache[key];
  }

  /// Hashes URL to a safe filesystem filename
  static String _getCacheFilename(String url) {
    final hash = sha1.convert(utf8.encode(url.trim())).toString();
    return 'rulebook_$hash.pdf';
  }

  /// Gets the local cache file directory
  static Future<Directory> _getCacheDirectory() async {
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory('${tempDir.path}/concetto_pdf_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// Retrieves cached PDF File from disk if it exists
  static Future<File?> getCachedFile(String url) async {
    if (url.trim().isEmpty) return null;
    try {
      final dir = await _getCacheDirectory();
      final file = File('${dir.path}/${_getCacheFilename(url)}');
      if (await file.exists() && await file.length() > 0) {
        return file;
      }
    } catch (e) {
      debugPrint('PdfCacheService getCachedFile error: $e');
    }
    return null;
  }

  /// Retrieves PDF bytes from Memory first, then Disk, then Cloud Network.
  /// Once downloaded, it caches to both disk and memory so subsequent opens never reload.
  static Future<Uint8List?> getOrFetchPdf(
    String url, {
    void Function(double progress)? onProgress,
  }) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return null;

    // 1. In-Memory RAM Check (Fastest: 0ms)
    if (_memoryCache.containsKey(cleanUrl)) {
      debugPrint('PdfCacheService: Served from in-memory RAM cache for $cleanUrl');
      onProgress?.call(1.0);
      return _memoryCache[cleanUrl];
    }

    // 2. Local Disk Cache Check
    try {
      final diskFile = await getCachedFile(cleanUrl);
      if (diskFile != null) {
        final bytes = await diskFile.readAsBytes();
        if (bytes.isNotEmpty) {
          _memoryCache[cleanUrl] = bytes;
          debugPrint('PdfCacheService: Served from local disk cache (${bytes.length} bytes)');
          onProgress?.call(1.0);
          return bytes;
        }
      }
    } catch (e) {
      debugPrint('PdfCacheService disk read notice: $e');
    }

    // 3. Network Fetch from Cloud
    try {
      debugPrint('PdfCacheService: Downloading PDF from cloud: $cleanUrl');
      final response = await _dio.get<List<int>>(
        cleanUrl,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Accept': 'application/pdf,application/octet-stream,*/*',
          },
        ),
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            final progress = (received / total).clamp(0.0, 1.0);
            onProgress(progress);
          }
        },
      );

      if (response.data != null && response.data!.isNotEmpty) {
        final bytes = Uint8List.fromList(response.data!);

        // Save to in-memory RAM cache
        _memoryCache[cleanUrl] = bytes;

        // Save to persistent disk cache asynchronously
        try {
          final dir = await _getCacheDirectory();
          final file = File('${dir.path}/${_getCacheFilename(cleanUrl)}');
          await file.writeAsBytes(bytes, flush: true);
          debugPrint('PdfCacheService: Saved ${bytes.length} bytes to local disk cache: ${file.path}');
        } catch (e) {
          debugPrint('PdfCacheService disk save notice: $e');
        }

        onProgress?.call(1.0);
        return bytes;
      }
    } catch (e) {
      debugPrint('PdfCacheService network download notice: $e');
    }

    return null;
  }
}
