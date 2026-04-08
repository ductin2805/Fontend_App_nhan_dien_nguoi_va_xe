import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class PlateScreen extends StatefulWidget {
  const PlateScreen({super.key});

  @override
  State<PlateScreen> createState() => _PlateScreenState();
}

class _PlateScreenState extends State<PlateScreen> {
  File? image;
  Uint8List? resultImage;
  double? imageRatio;
  bool isLoading = false;

  List plates = [];
  int totalVehicles = 0;

  IconData getVehicleIcon(String type) {
    switch (type.toLowerCase()) {
      case "car":
        return Icons.directions_car;

      case "truck":
        return Icons.local_shipping;

      case "motorcycle":
      case "motorbike":
      case "moto":
        return Icons.two_wheeler;

      case "bus":
        return Icons.directions_bus;

      default:
        return Icons.directions_car; // fallback
    }
  }
  // 📸 chọn ảnh
  Future pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        image = File(picked.path);
        resultImage = null;
        imageRatio = null;
        plates = [];
        totalVehicles = 0;
      });
    }
  }

  // 🚀 detect biển số
  Future detectPlate() async {
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
        endpoint: "detect-plates",
      );

      if (data["error"] != null) {
        throw Exception(data["error"]);
      }

      Uint8List bytes = base64Decode(data["image"]);
      final decoded = await decodeImageFromList(bytes);

      // 🔥 LẤY DATA ĐÚNG
      List vehicles = data["vehicles"] ?? [];

      List detectedPlates = vehicles
          .where((v) => v["plate"]?["detected"] == true)
          .map((v) => {
        "text": v["plate"]["text"],
        "confidence": v["plate"]["confidence"],
        "type": v["class_name"],
      })
          .toList();

      setState(() {
        resultImage = bytes;
        imageRatio = decoded.width / decoded.height;
        plates = detectedPlates;
        totalVehicles = data["total_vehicles"] ?? 0;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ $e")),
      );
    }

    setState(() => isLoading = false);
  }

  // 🔧 làm sạch biển số
  String cleanPlate(String text) {
    return text.replaceAll(RegExp(r'[^A-Z0-9.]'), '');
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
                      "🚗 Tổng xe: $totalVehicles",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 10),

                    if (plates.isEmpty)
                      const Text("Không phát hiện biển số"),

                    ...plates.map((p) {
                      final text = cleanPlate(p["text"] ?? "");
                      final conf = ((p["confidence"] ?? 0) * 100);
                      final type = p["type"] ?? "vehicle";

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [

                            Icon(
                              getVehicleIcon(type),
                              color: Colors.blue,
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Text(
                                text.isEmpty ? "Không rõ" : text,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            Text(
                              "${conf.toStringAsFixed(1)}%",
                              style: TextStyle(
                                color: conf > 50
                                    ? Colors.green
                                    : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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
                    onTap: detectPlate,
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
                        plates = [];
                        totalVehicles = 0;
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