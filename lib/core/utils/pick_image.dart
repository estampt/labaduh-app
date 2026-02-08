import 'dart:typed_data';

import 'pick_image_stub.dart'
    if (dart.library.html) 'pick_image_web.dart';

/// Returns image bytes (png/jpg/etc) or null if user cancelled.
Future<Uint8List?> pickImageBytes() => pickImageBytesImpl();
