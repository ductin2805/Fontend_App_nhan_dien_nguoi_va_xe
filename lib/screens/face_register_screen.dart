import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/face_register_response.dart';

class FaceRegisterScreen extends StatefulWidget {
  const FaceRegisterScreen({super.key});

  @override
  State<FaceRegisterScreen> createState() => _FaceRegisterScreenState();
}

class _FaceRegisterScreenState extends State<FaceRegisterScreen> {
  File? image;

  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final cccdCtrl = TextEditingController();
  final departmentCtrl = TextEditingController();
  final roleCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final ageCtrl = TextEditingController();
  final dobCtrl = TextEditingController();

  FaceRegisterResponse? result;
  String? previewBase64;

  bool loading = false;

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => image = File(picked.path));
    }
  }
  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      final day = picked.day.toString().padLeft(2, '0');
      final month = picked.month.toString().padLeft(2, '0');
      final year = picked.year;

      dobCtrl.text = "$day/$month/$year"; // 👈 format dd/MM/yyyy
    }
  }
  Future<void> submit() async {
    final error = validateInputs();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }
    if (image == null || nameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Thiếu dữ liệu")),
      );
      return;
    }
    setState(() => loading = true);

    try {
      final res = await ApiService.registerFace(
        file: image!,
        fields: {
          "name": nameCtrl.text,
          "department": departmentCtrl.text,
          "role": roleCtrl.text,
          "phone": phoneCtrl.text,
          "address": addressCtrl.text,
          "age": ageCtrl.text,
          "date_of_birth": dobCtrl.text,
          "cccd": cccdCtrl.text,
        },
      );

      setState(() {
        result = res;
        previewBase64 = res.imageBase64;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đăng ký thành công")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    }

    setState(() => loading = false);
  }

  Widget input(String hint, TextEditingController ctrl,
      {TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
  String? validateInputs() {
    final phone = phoneCtrl.text.trim();
    final cccd = cccdCtrl.text.trim();
    final age = ageCtrl.text.trim();
    final dob = dobCtrl.text.trim();

    /// 📱 SĐT: 10 số
    if (phone.isNotEmpty && !RegExp(r'^\d{10}$').hasMatch(phone)) {
      return "SĐT phải đúng 10 số";
    }

    /// 🆔 CCCD: 12 số
    if (cccd.isNotEmpty && !RegExp(r'^\d{12}$').hasMatch(cccd)) {
      return "CCCD phải đúng 12 số";
    }

    /// 🎂 Tuổi: số > 0
    if (age.isNotEmpty) {
      final a = int.tryParse(age);
      if (a == null || a <= 0 || a > 120) {
        return "Tuổi không hợp lệ";
      }
    }

    /// 📅 Ngày sinh: yyyy-MM-dd
    if (dob.isNotEmpty) {
      try {
        final date = DateTime.parse(dob);
        if (date.isAfter(DateTime.now())) {
          return "Ngày sinh không hợp lệ";
        }
      } catch (_) {
        return "Ngày sinh phải đúng định dạng yyyy-MM-dd";
      }
    }

    return null; // ✅ hợp lệ
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng ký khuôn mặt")),
      backgroundColor: const Color(0xfff5f6fa),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// IMAGE
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: image != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(image!, fit: BoxFit.cover),
                )
                    : const Icon(Icons.add_a_photo, size: 40),
              ),
            ),

            const SizedBox(height: 16),

            /// FORM
            input("Tên", nameCtrl),
            input("Nơi làm việc", departmentCtrl),
            input("Chức vụ", roleCtrl),
            input("SĐT", phoneCtrl, type: TextInputType.number),
            input("Địa chỉ", addressCtrl),
            input("Tuổi", ageCtrl, type: TextInputType.number),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: dobCtrl,
                readOnly: true, // 👈 không cho nhập tay
                onTap: pickDate,
                decoration: InputDecoration(
                  hintText: "Ngày sinh (dd/MM/yyyy)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
              ),
            ),
            input("CCCD", cccdCtrl, type: TextInputType.number),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: loading ? null : submit,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Đăng ký"),
            ),

            const SizedBox(height: 20),

            /// RESULT
            if (result != null) ...[
              const Text("Kết quả AI"),
              const SizedBox(height: 10),

              if (previewBase64 != null)
                Image.memory(base64Decode(previewBase64!)),

              const SizedBox(height: 10),

              Text("ID: ${result!.personId}"),
              Text("Samples: ${result!.samples}"),
              Text("Model: ${result!.backend}"),
              Text("BBox: ${result!.bbox}"),
            ]
          ],
        ),
      ),
    );
  }
}