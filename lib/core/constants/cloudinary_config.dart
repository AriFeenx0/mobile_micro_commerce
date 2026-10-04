abstract final class CloudinaryConfig {
  static const cloudName = String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
  static const uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
  );

  static bool get isConfigured =>
      cloudName.isNotEmpty && uploadPreset.isNotEmpty;
}