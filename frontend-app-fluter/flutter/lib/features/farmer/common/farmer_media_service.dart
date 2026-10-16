import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class FarmerAttachment {
  const FarmerAttachment(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
}

class FarmerMediaService {
  Future<FarmerAttachment?> photo({bool camera = true}) async {
    final picked = await ImagePicker().pickImage(
      source: camera && !kIsWeb ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return FarmerAttachment(picked.name, await picked.readAsBytes());
  }

  /// Image formats accepted by `/area/create-land` (`images`).
  static const landImageExtensions = {'jpg', 'jpeg', 'png', 'webp'};

  /// Picks an existing land photo from the gallery (works on the iOS
  /// simulator, which has no camera). Resizing makes iOS re-encode HEIC
  /// photos to JPEG.
  Future<FarmerAttachment?> uploadImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null) return null;
    final name = picked.name;
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    if (!landImageExtensions.contains(ext)) {
      throw StateError('Foto harus berformat JPG, PNG, atau WEBP.');
    }
    final bytes = await picked.readAsBytes();
    if (bytes.isEmpty) throw StateError('Foto kosong. Pilih foto lain.');
    if (bytes.length > 10 * 1024 * 1024) {
      throw StateError('Ukuran foto maksimal 10 MB.');
    }
    return FarmerAttachment(name, bytes);
  }

  Future<FarmerAttachment?> document() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );
    if (result.isEmpty) return null;
    final file = result.single;
    if ((await file.length() ?? 0) > 10 * 1024 * 1024) {
      throw StateError('Ukuran dokumen maksimal 10 MB.');
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
      throw StateError('Dokumen kosong atau melebihi 10 MB.');
    }
    return FarmerAttachment(file.name, bytes);
  }

  /// PDF-only picker for the land certificate (SPPT), uploaded to
  /// `/area/upload-area-document/{area_id}`.
  Future<FarmerAttachment?> pdfDocument() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result.isEmpty) return null;
    final file = result.single;
    if (!file.name.toLowerCase().endsWith('.pdf')) {
      throw StateError('Dokumen harus berformat PDF.');
    }
    if ((await file.length() ?? 0) > 10 * 1024 * 1024) {
      throw StateError('Ukuran dokumen maksimal 10 MB.');
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
      throw StateError('Dokumen kosong atau melebihi 10 MB.');
    }
    if (!isPdf(bytes)) {
      throw StateError('Dokumen harus berformat PDF.');
    }
    return FarmerAttachment(file.name, bytes);
  }

  /// True when [bytes] start with the `%PDF` signature.
  static bool isPdf(Uint8List bytes) =>
      bytes.length >= 4 &&
      bytes[0] == 0x25 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x44 &&
      bytes[3] == 0x46;
}
