import 'dart:typed_data';
import 'package:flutter/material.dart';

class DocumentAttachment {
  const DocumentAttachment({
    required this.label,
    this.fileName,
    this.path, // ✅ mobile/desktop only
    this.bytes, // ✅ web
    this.sizeBytes,
  });

  final String label;
  final String? fileName;
  final String? path;
  final Uint8List? bytes;
  final int? sizeBytes;

  bool get hasFile =>
      (bytes != null && bytes!.isNotEmpty) || ((path ?? '').trim().isNotEmpty);

  bool get isAttached => hasFile && (fileName ?? '').trim().isNotEmpty;

  String get sizeLabel {
    final s = sizeBytes;
    if (s == null) return '';
    if (s < 1024) return '${s}B';
    if (s < 1024 * 1024) return '${(s / 1024).toStringAsFixed(0)}KB';
    return '${(s / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  DocumentAttachment copyWith({
    String? fileName,
    String? path,
    Uint8List? bytes,
    int? sizeBytes,
  }) =>
      DocumentAttachment(
        label: label,
        fileName: fileName ?? this.fileName,
        path: path ?? this.path,
        bytes: bytes ?? this.bytes,
        sizeBytes: sizeBytes ?? this.sizeBytes,
      );

  static DocumentAttachment empty(String label) => DocumentAttachment(label: label);
}

class DocumentUploadTile extends StatelessWidget {
  const DocumentUploadTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isRequired,
    required this.attachment,
    required this.onAttachPressed,
    required this.onRemovePressed,
  });

  final String title;
  final String subtitle;
  final bool isRequired;
  final DocumentAttachment attachment;

  final VoidCallback onAttachPressed;
  final VoidCallback onRemovePressed;

  @override
  Widget build(BuildContext context) {
    final ok = attachment.isAttached;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(ok ? Icons.check_circle : Icons.upload_file,
            color: ok ? Colors.green : null),
        title: Row(
          children: [
            Expanded(
              child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
            if (isRequired)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'REQUIRED',
                  style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w900,
                      fontSize: 12),
                ),
              ),
          ],
        ),
        subtitle: Text(
          ok
              ? 'Attached: ${attachment.fileName}${attachment.sizeLabel.isEmpty ? '' : ' • ${attachment.sizeLabel}'}'
              : subtitle,
        ),
        trailing: ok
            ? IconButton(
                tooltip: 'Remove',
                icon: const Icon(Icons.close),
                onPressed: onRemovePressed,
              )
            : TextButton(
                onPressed: onAttachPressed,
                child: const Text('Attach'),
              ),
      ),
    );
  }
}
