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
  final plateNumberCtrl = TextEditingController();
  final vehiclePlatesCtrl = TextEditingController();
  
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
      locale: const Locale('vi', 'VN'),
    );

    if (picked != null) {
      setState(() {
        final day = picked.day.toString().padLeft(2, '0');
        final month = picked.month.toString().padLeft(2, '0');
        final year = picked.year;
        dobCtrl.text = "$day/$month/$year";

        // Tự động tính tuổi
        final now = DateTime.now();
        int age = now.year - picked.year;
        if (now.month < picked.month || (now.month == picked.month && now.day < picked.day)) {
          age--;
        }
        ageCtrl.text = age.toString();
      });
    }
  }

  String? validateInputs() {
    final name = nameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    final cccd = cccdCtrl.text.trim();
    final age = ageCtrl.text.trim();
    final dob = dobCtrl.text.trim();

    if (name.isEmpty) return "Tên không được bỏ trống";

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

    /// 📅 Ngày sinh: dd/MM/yyyy
    if (dob.isNotEmpty) {
      try {
        final parts = dob.split('/');
        if (parts.length != 3) {
          return "Ngày sinh không hợp lệ";
        }
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        final date = DateTime(year, month, day);

        if (date.day != day || date.month != month || date.year != year) {
          return "Ngày sinh không hợp lệ";
        }
        if (date.isAfter(DateTime.now())) {
          return "Ngày sinh không hợp lệ";
        }
      } catch (_) {
        return "Ngày sinh phải đúng định dạng dd/MM/yyyy";
      }
    }
    return null; // ✅ hợp lệ
  }

  Future<void> submit() async {
    if (image == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng chọn ảnh khuôn mặt")));
      return;
    }

    final error = validateInputs();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    setState(() => loading = true);
    try {
      final res = await ApiService.registerFace(
        file: image!,
        fields: {
          "name": nameCtrl.text.trim(),
          "department": departmentCtrl.text.trim(),
          "role": roleCtrl.text.trim(),
          "phone": phoneCtrl.text.trim(),
          "address": addressCtrl.text.trim(),
          "age": ageCtrl.text.trim(),
          "date_of_birth": dobCtrl.text.trim(),
          "cccd": cccdCtrl.text.trim(),
          "plate_number": plateNumberCtrl.text.trim(),
          "vehicle_plates": vehiclePlatesCtrl.text.trim(),
        },
      );

      setState(() {
        result = res;
        previewBase64 = res.imageBase64;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đăng ký thành công")));
        
        // Tự động quay lại màn hình danh sách sau 1.5 giây và yêu cầu reload
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) Navigator.pop(context, true);
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      appBar: AppBar(
        title: const Text("ĐĂNG KÝ DANH TÍNH", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// 📸 AVATAR PICKER
            Center(
              child: GestureDetector(
                onTap: pickImage,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))],
                    border: Border.all(color: Colors.blue.shade100, width: 3),
                  ),
                  child: image != null
                      ? ClipOval(child: Image.file(image!, fit: BoxFit.cover))
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_rounded, size: 40, color: Colors.blue.shade200),
                            const SizedBox(height: 4),
                            const Text("Thêm ảnh", style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                          ],
                        ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            /// 👤 THÔNG TIN CÁ NHÂN
            _buildSectionHeader("Thông tin cá nhân"),
            _buildCard([
              _buildInput("Họ và tên *", nameCtrl, icon: Icons.person_outline),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: pickDate,
                      child: AbsorbPointer(
                        child: _buildInput("Ngày sinh", dobCtrl, icon: Icons.calendar_today_outlined, hint: "DD/MM/YYYY"),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _buildInput("Tuổi", ageCtrl, type: TextInputType.number, icon: Icons.cake_outlined)),
                ],
              ),
              _buildInput("Số điện thoại", phoneCtrl, type: TextInputType.phone, icon: Icons.phone_outlined),
              _buildInput("Số CCCD", cccdCtrl, type: TextInputType.number, icon: Icons.badge_outlined),
              _buildInput("Địa chỉ / Nơi ở", addressCtrl, icon: Icons.location_on_outlined),
            ]),

            const SizedBox(height: 20),

            /// 💼 CÔNG VIỆC & PHƯƠNG TIỆN
            _buildSectionHeader("Công việc & Phương tiện"),
            _buildCard([
              _buildInput("Nơi làm việc", departmentCtrl, icon: Icons.business_outlined),
              _buildInput("Chức vụ", roleCtrl, icon: Icons.work_outline),
              _buildInput("Biển số xe chính", plateNumberCtrl, icon: Icons.directions_car_filled_outlined),
              _buildInput("Biển số xe phụ", vehiclePlatesCtrl, icon: Icons.list_alt_outlined, hint: "Ví dụ: 29A-12345, 30B-67890"),
            ]),

            const SizedBox(height: 30),

            /// 🚀 NÚT ĐĂNG KÝ
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: loading ? null : submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 2,
                ),
                child: loading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("XÁC NHẬN ĐĂNG KÝ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1)),
              ),
            ),

            const SizedBox(height: 25),

            /// 📊 KẾT QUẢ TỪ AI
            if (result != null) _buildResultSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey, letterSpacing: 1.2)),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInput(String label, TextEditingController ctrl, {TextInputType? type, IconData? icon, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon, size: 20, color: Colors.blueAccent.withOpacity(0.7)) : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5)),
          filled: true,
          fillColor: const Color(0xfffafafa),
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.blue),
              const SizedBox(width: 10),
              const Text("KẾT QUẢ AI XÁC NHẬN", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 15),
          if (previewBase64 != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(base64Decode(previewBase64!), width: double.infinity, height: 200, fit: BoxFit.cover),
            ),
          const SizedBox(height: 15),
          _resultRow("ID Hệ thống", result!.personId),
          _resultRow("Số mẫu ảnh", result!.samples.toString()),
          _resultRow("BBox", result!.bbox.toString()),
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13)),
        ],
      ),
    );
  }
}
