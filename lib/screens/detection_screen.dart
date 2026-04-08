import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class TrafficScreen extends StatefulWidget {
  const TrafficScreen({super.key});

  @override
  State<TrafficScreen> createState() => _TrafficScreenState();
}

class _TrafficScreenState extends State<TrafficScreen> {
  File? image;
  Uint8List? resultImage;
  bool isLoading = false;
  double? imageRatio;

  int personCount = 0;
  int carCount = 0;
  int motorCount = 0;

  // 📸 chọn ảnh
  Future pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        image = File(picked.path);
        resultImage = null;
        imageRatio = null;

        personCount = 0;
        carCount = 0;
        motorCount = 0;
      });
    }
  }

  // 🚀 gửi AI
  Future sendImage() async {
    if (image == null) return;

    setState(() => isLoading = true);

    try {
      final data = await ApiService.sendImage(image!);

      if (data["error"] != null) {
        throw Exception(data["error"]);
      }

      // 🔥 decode ảnh
      Uint8List bytes = base64Decode(data["image"]);

      final decoded = await decodeImageFromList(bytes);

      // 🔥 đếm object
      int person = 0;
      int car = 0;
      int motor = 0;

      for (var d in data["detections"]) {
        if (d["class"] == 0) person++;
        if (d["class"] == 2) car++;
        if (d["class"] == 3) motor++;
      }

      setState(() {
        resultImage = bytes;
        imageRatio = decoded.width / decoded.height;

        personCount = person;
        carCount = car;
        motorCount = motor;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Lỗi: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  // 🔘 item dưới
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
          Icon(icon, color: Colors.grey[700]),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  // 📦 box UI
  Widget _infoBox(String text) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white),
      ),
    );
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
                child: Image.memory(
                  resultImage!,
                  fit: BoxFit.contain,
                ),
              ),
            )
          else if (image != null)
            Center(
              child: Image.file(image!, fit: BoxFit.contain),
            )
          else
            const Center(
              child: Text(
                "Chưa chọn ảnh",
                style: TextStyle(color: Colors.white),
              ),
            ),

          // 🔙 back
          Positioned(
            top: 30,
            left: 10,
            width: 30,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // 🔝 thống kê trái
          Positioned(
            top: 60,
            left: 20,
            child: _infoBox(
              "🟢 ACTIVE\n👤 $personCount",
            ),
          ),

          // 🔝 thống kê phải
          Positioned(
            top: 60,
            right: 20,
            child: _infoBox(
              "🚗 $carCount\n🏍 $motorCount",
            ),
          ),

          // ⏳ loading
          if (isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),

          // 🔘 bottom bar
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 10),
                ],
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
                    onTap: sendImage,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.blue[900],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 30,
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

                        personCount = 0;
                        carCount = 0;
                        motorCount = 0;
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
}