import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../core/constants/cloudinary_config.dart';

class StorageService {
  Future<String> uploadOrderSlip({
    required String customerId,
    required String orderId,
    required XFile image,
  }) async {
    if (!CloudinaryConfig.isConfigured) {
      throw StateError(
        'กำหนด CLOUDINARY_CLOUD_NAME และ CLOUDINARY_UPLOAD_PRESET ก่อนอัปโหลดสลิป',
      );
    }

    final endpoint = Uri.https(
      'api.cloudinary.com',
      '/v1_1/${CloudinaryConfig.cloudName}/image/upload',
    );
    final request = http.MultipartRequest('POST', endpoint)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..fields['context'] = 'customer_id=$customerId|order_id=$orderId'
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          await image.readAsBytes(),
          filename: _safeFilename(image.name, 0),
        ),
      );

    try {
      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 2),
      );
      final response = await http.Response.fromStream(streamedResponse);
      final payload = _decodeResponse(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = payload['error'];
        final message = error is Map ? error['message']?.toString() : null;
        throw CloudinaryUploadException(
          message ?? 'Cloudinary upload failed (${response.statusCode})',
        );
      }

      final secureUrl = payload['secure_url'];
      if (secureUrl is! String || secureUrl.isEmpty) {
        throw CloudinaryUploadException(
          'Cloudinary response did not include a secure URL',
        );
      }
      return secureUrl;
    } on http.ClientException catch (error) {
      throw CloudinaryUploadException('Cloudinary network error: $error');
    } on TimeoutException {
      throw CloudinaryUploadException('Cloudinary upload timed out');
    }
  }

  Future<List<String>> uploadBookImages({
    required String ownerId,
    required String bookId,
    required List<XFile> images,
  }) async {
    if (images.isEmpty) return const [];
    if (!CloudinaryConfig.isConfigured) {
      throw StateError(
        'กำหนด CLOUDINARY_CLOUD_NAME และ CLOUDINARY_UPLOAD_PRESET ก่อนอัปโหลดรูป',
      );
    }

    final urls = <String>[];
    for (var index = 0; index < images.length; index++) {
      final image = images[index];
      final endpoint = Uri.https(
        'api.cloudinary.com',
        '/v1_1/${CloudinaryConfig.cloudName}/image/upload',
      );
      final request = http.MultipartRequest('POST', endpoint)
        ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
        ..fields['context'] = 'owner_id=$ownerId|book_id=$bookId'
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            await image.readAsBytes(),
            filename: _safeFilename(image.name, index),
          ),
        );

      try {
        final streamedResponse = await request.send().timeout(
          const Duration(minutes: 2),
        );
        final response = await http.Response.fromStream(streamedResponse);
        final payload = _decodeResponse(response.body);
        if (response.statusCode < 200 || response.statusCode >= 300) {
          final error = payload['error'];
          final message = error is Map ? error['message']?.toString() : null;
          throw CloudinaryUploadException(
            message ?? 'Cloudinary upload failed (${response.statusCode})',
          );
        }

        final secureUrl = payload['secure_url'];
        if (secureUrl is! String || secureUrl.isEmpty) {
          throw CloudinaryUploadException(
            'Cloudinary response did not include a secure URL',
          );
        }
        urls.add(secureUrl);
      } on http.ClientException catch (error) {
        throw CloudinaryUploadException('Cloudinary network error: $error');
      } on TimeoutException {
        throw CloudinaryUploadException('Cloudinary upload timed out');
      }
    }
    return urls;
  }

  String _safeFilename(String filename, int index) {
    final basename = filename.split(RegExp(r'[/\\]')).last.trim();
    if (basename.isEmpty) return 'book_image_$index.jpg';
    return basename.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }

  Map<String, dynamic> _decodeResponse(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } on FormatException {
      return const {};
    }
  }
}

class CloudinaryUploadException extends StateError {
  CloudinaryUploadException(super.message);
}
