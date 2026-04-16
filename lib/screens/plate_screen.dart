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
  Set<int> expandedItems = {};
  List vehicles = [];
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
        return Icons.directions_car;
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
        vehicles = [];
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

      Uint8List bytes = base64Decode(data["image"]);
      final decoded = await decodeImageFromList(bytes);

      setState(() {
        resultImage = bytes;
        imageRatio = decoded.width / decoded.height;
        vehicles = data["vehicles"] ?? [];
        totalVehicles = data["total_vehicles"] ?? 0;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ $e")),
      );
    }

    setState(() => isLoading = false);
  }

  String v(dynamic value) {
    if (value == null || value.toString().isEmpty) return "Không có";
    return value.toString();
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
              child: Text("Chưa chọn ảnh", style: TextStyle(color: Colors.white)),
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

          // 📦 RESULT
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

                    if (vehicles.isEmpty)
                      const Text("Không phát hiện"),

                    ...vehicles.asMap().entries.map((entry) {
                      final index = entry.key;
                      final vcl = entry.value;

                      final plate = vcl["plate"];
                      final owner = plate?["owner"];
                      final info = owner?["info"] ?? {};

                      final plateText = plate?["text"] ?? "Không rõ";
                      final confidence = (plate?["confidence"] ?? 0) * 100;
                      final type = vcl["class_name"] ?? "vehicle";

                      final isExpanded = expandedItems.contains(index);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              expandedItems.remove(index);
                            } else {
                              expandedItems.add(index);
                            }
                          });
                        },

                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              // 🔹 HEADER (LUÔN HIỆN)
                              Row(
                                children: [
                                  Icon(getVehicleIcon(type), color: Colors.blue),
                                  const SizedBox(width: 8),

                                  Expanded(
                                    child: Text(
                                      plateText,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  Text(
                                    "${confidence.toStringAsFixed(1)}%",
                                    style: TextStyle(
                                      color: confidence > 60
                                          ? Colors.green
                                          : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(width: 6),

                                  Icon(
                                    isExpanded
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),

                              Text(
                                "👤 ${v(owner?["name"])}",
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),

                              // 🔥 PHẦN MỞ RỘNG
                              AnimatedCrossFade(
                                duration: const Duration(milliseconds: 300),
                                crossFadeState: isExpanded
                                    ? CrossFadeState.showSecond
                                    : CrossFadeState.showFirst,

                                firstChild: const SizedBox(),

                                secondChild: Column(
                                  children: [
                                    const Divider(),

                                    _row("SĐT", info["phone"]),
                                    _row("Địa chỉ", info["address"]),
                                    _row("Ngày sinh", info["date_of_birth"]),
                                    _row("CCCD", info["cccd"]),
                                    _row("Phòng ban", info["department"]),
                                    _row("Chức vụ", info["role"]),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),

          // 🔘 BOTTOM
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
                      child: const Icon(Icons.camera_alt, color: Colors.white),
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
                        vehicles = [];
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

  Widget _row(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            value == null || value.toString().isEmpty
                ? "Không có"
                : value.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
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