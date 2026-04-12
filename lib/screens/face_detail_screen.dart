import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/face_recognition_response.dart';
import 'package:image/image.dart' as img;

class FaceDetailScreen extends StatelessWidget {
  final FaceData face;
  final Uint8List imageBytes;

  const FaceDetailScreen({
    super.key,
    required this.face,
    required this.imageBytes,
  });
  Uint8List cropFace() {
    final decoded = img.decodeImage(imageBytes)!;

    final box = face.bbox;
    final x = box[0];
    final y = box[1];
    final w = box[2] - box[0];
    final h = box[3] - box[1];

    final cropped = img.copyCrop(decoded, x: x, y: y, width: w, height: h);

    return Uint8List.fromList(img.encodeJpg(cropped));
  }

  @override
  Widget build(BuildContext context) {
    final person = face.person;
    final score = face.matchScore * 100;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Thông tin chi tiết"),
        centerTitle: true,
      ),
      body: person == null
          ? const Center(child: Text("Không có dữ liệu"))
          : SingleChildScrollView(
        child: Column(
          children: [

            const SizedBox(height: 20),

            // 🧑 Avatar + trạng thái
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: MemoryImage(cropFace()),
                ),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.check, color: Colors.white),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              person.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              "IDENTIFIED",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // 📦 INFO CARD
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    color: Colors.black12,
                  )
                ],
              ),
              child: Column(
                children: [

                  _infoRow(Icons.badge, "ID", person.personCode),
                  _infoRow(Icons.work, "Phòng", person.info.department),
                  _infoRow(Icons.person, "Chức vụ", person.info.role),
                  _infoRow(Icons.phone, "SĐT", person.info.phone),
                  _infoRow(Icons.home, "Địa chỉ", person.info.address),
                  _infoRow(Icons.cake, "Ngày sinh", person.info.dateOfBirth),
                  _infoRow(Icons.credit_card, "CCCD", person.info.cccd),
                  _infoRow(Icons.numbers, "Tuổi", person.info.age),

                ],
              ),
            ),

            const SizedBox(height: 20),

            // 📊 CONFIDENCE
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    "CONFIDENCE",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "${score.toStringAsFixed(1)}%",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: score > 70 ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 10),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}