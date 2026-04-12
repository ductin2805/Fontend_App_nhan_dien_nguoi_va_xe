import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/face_recognition_response.dart';
import 'face_detail_screen.dart';

class FaceRecognitionScreen extends StatefulWidget {
  const FaceRecognitionScreen({super.key});

  @override
  State<FaceRecognitionScreen> createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  File? image;
  Uint8List? resultImage;
  double? imageRatio;
  bool isLoading = false;

  List<FaceData> faces = [];
  int totalFaces = 0;

  // 📸 chọn ảnh
  Future pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        image = File(picked.path);
        resultImage = null;
        imageRatio = null;
        faces = [];
        totalFaces = 0;
      });
    }
  }

  // 🚀 nhận diện khuôn mặt
  Future detectFace() async {
    if (image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Chưa chọn ảnh")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final data = await ApiService.sendImage(
        image!,
        endpoint: "face/recognize",
      );

      final response = FaceRecognitionResponse.fromJson(data);

      Uint8List bytes = base64Decode(response.annotatedImage);
      final decoded = await decodeImageFromList(bytes);

      setState(() {
        resultImage = bytes;
        imageRatio = decoded.width / decoded.height;
        faces = response.faces;
        totalFaces = response.totalFaces;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ $e")),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [

          // 📸 ẢNH
          if (resultImage != null && imageRatio != null)
            Center(
              child: AspectRatio(
                aspectRatio: imageRatio!,
                child: Image.memory(resultImage!, fit: BoxFit.contain),
              ),
            )
          else if (image != null)
            Center(child: Image.file(image!, fit: BoxFit.contain))
          else
            const Center(
              child: Text(
                "Chưa chọn ảnh",
                style: TextStyle(color: Colors.white),
              ),
            ),

          // 🔙 BACK
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // ⏳ LOADING
          if (isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),

          // 📦 CARD KẾT QUẢ
          if (resultImage != null)
            Positioned(
              bottom: 120,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      "👤Số khuôn mặt được nhận diện: $totalFaces",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 10),

                    if (faces.isEmpty)
                      const Text("Không phát hiện khuôn mặt"),

                    ...faces.map((face) {
                      final isKnown = face.isKnown;
                      final score = face.matchScore * 100;
                      final person = face.person;

                      return GestureDetector(
                        onTap: () {
                          if (isKnown && person != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FaceDetailScreen(
                                  face: face,
                                  imageBytes: resultImage!,
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Row(
                                children: [
                                  Icon(
                                    isKnown ? Icons.verified : Icons.person,
                                    color: isKnown ? Colors.green : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),

                                  Expanded(
                                    child: Text(
                                      isKnown && person != null
                                          ? person.name
                                          : "Người lạ",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  Text(
                                    "${score.toStringAsFixed(1)}%",
                                    style: TextStyle(
                                      color: score > 70
                                          ? Colors.green
                                          : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              if (isKnown && person != null) ...[
                                const SizedBox(height: 6),
                                Text("Số điện thoại : ${person.info.phone}"),
                                Text("Ngày Sinh: ${person.info.dateOfBirth}"),
                                Text("CCCD: ${person.info.cccd}"),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

          // 🔘 BOTTOM BAR
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [

                  _tabItem(
                    icon: Icons.image,
                    label: "Chọn ảnh",
                    onTap: pickImage,
                  ),

                  GestureDetector(
                    onTap: detectFace,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.blue[900],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  _tabItem(
                    icon: Icons.refresh,
                    label: "Reset",
                    onTap: () {
                      setState(() {
                        image = null;
                        resultImage = null;
                        imageRatio = null;
                        faces = [];
                        totalFaces = 0;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}