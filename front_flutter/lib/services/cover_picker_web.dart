import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../models/upload_file.dart';

Future<UploadFile?> pickCover() async {
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = '.jpg,.jpeg,.png,.webp';
  final result = Completer<UploadFile?>();
  input.addEventListener(
    'change',
    ((web.Event event) async {
      final file = input.files?.item(0);
      if (file == null) {
        result.complete(null);
        return;
      }
      try {
        final buffer = await file.arrayBuffer().toDart;
        result.complete(
          UploadFile(name: file.name, bytes: buffer.toDart.asUint8List()),
        );
      } catch (error, stack) {
        result.completeError(error, stack);
      }
    }).toJS,
  );
  input.addEventListener(
    'cancel',
    ((web.Event event) {
      if (!result.isCompleted) result.complete(null);
    }).toJS,
  );
  input.click();
  return result.future;
}
