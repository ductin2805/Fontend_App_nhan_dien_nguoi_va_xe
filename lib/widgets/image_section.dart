import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class ImageSection extends StatelessWidget {
  final File? image;
  final Uint8List? resultImage;

  const ImageSection({
    super.key,
    this.image,
    this.resultImage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (image != null) ...[
          const Text("📸 Ảnh gốc"),
          const SizedBox(height: 10),
          Image.file(image!, height: 200),
        ],
        const SizedBox(height: 20),
        if (resultImage != null) ...[
          const Text("🧠 Kết quả AI"),
          const SizedBox(height: 10),
          Image.memory(resultImage!, height: 300),
        ],
      ],
    );
  }
}