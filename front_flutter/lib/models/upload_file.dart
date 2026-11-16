import 'dart:typed_data';

class UploadFile {
  const UploadFile({required this.name, required this.bytes});
  final String name;
  final Uint8List bytes;
}
