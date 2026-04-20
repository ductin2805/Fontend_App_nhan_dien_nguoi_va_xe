import 'package:flutter/material.dart';
import '../models/person_model.dart';
import '../services/api_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class PersonEditScreen extends StatefulWidget {
  final Person person;

  const PersonEditScreen({super.key, required this.person});

  @override
  State<PersonEditScreen> createState() => _PersonEditScreenState();
}

class _PersonEditScreenState extends State<PersonEditScreen> {
  late TextEditingController nameCtrl;
  late TextEditingController departmentCtrl;
  late TextEditingController roleCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController addressCtrl;
  late TextEditingController ageCtrl;
  late TextEditingController dobCtrl;
  late TextEditingController cccdCtrl;
  late TextEditingController plateNumberCtrl;
  late TextEditingController vehiclePlatesCtrl;
  
  File? newImage;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.person;
    nameCtrl = TextEditingController(text: p.name);
    departmentCtrl = TextEditingController(text: p.info.department);
    roleCtrl = TextEditingController(text: p.info.role);
    phoneCtrl = TextEditingController(text: p.info.phone);
    addressCtrl = TextEditingController(text: p.info.address);
    ageCtrl = TextEditingController(text: p.info.age);
    dobCtrl = TextEditingController(text: p.info.dob);
    cccdCtrl = TextEditingController(text: p.info.cccd);
    plateNumberCtrl = TextEditingController(text: p.info.plateNumber);
    vehiclePlatesCtrl = TextEditingController(text: p.info.vehiclePlates);
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('vi', 'VN'),
    );

    if (picked != null) {
      final day = picked.day.toString().padLeft(2, '0');
      final month = picked.month.toString().padLeft(2, '0');
      final year = picked.year;
      setState(() {
        dobCtrl.text = "$day/$month/$year";
        // Tự động tính tuổi
        ageCtrl.text = (DateTime.now().year - picked.year).toString();
      });
    }
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        newImage = File(picked.path);
      });
    }
  }

  String? validate() {
    if (nameCtrl.text.trim().isEmpty) return "Tên không được bỏ trống";
    if (phoneCtrl.text.isNotEmpty && !RegExp(r'^\d{10}$').hasMatch(phoneCtrl.text)) return "SĐT phải đúng 10 số";
    if (cccdCtrl.text.isNotEmpty && !RegExp(r'^\d{12}$').hasMatch(cccdCtrl.text)) return "CCCD phải đúng 12 số";
    return null;
  }

  Future<void> update() async {
    final error = validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    setState(() => loading = true);
    try {
      final uri = Uri.parse(ApiService.buildUrl("/face/person/${widget.person.personId}"));
      final request = http.MultipartRequest("PUT", uri);

      if (newImage != null) {
        request.files.add(await http.MultipartFile.fromPath("file", newImage!.path));
      }

      request.fields.addAll({
        "name": nameCtrl.text,
        "department": departmentCtrl.text,
        "role": roleCtrl.text,
        "phone": phoneCtrl.text,
        "address": addressCtrl.text,
        "age": ageCtrl.text,
        "date_of_birth": dobCtrl.text,
        "cccd": cccdCtrl.text,
        "plate_number": plateNumberCtrl.text,
        "vehicle_plates": vehiclePlatesCtrl.text,
      });

      final res = await request.send();
      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cập nhật thành công")));
          Navigator.pop(context, true);
        }
      } else {
        throw Exception("Lỗi server: ${res.statusCode}");
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
        title: const Text("CHỈNH SỬA THÀNH VIÊN"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildAvatarSection(),
            const SizedBox(height: 25),
            
            _buildSection(
              title: "THÔNG TIN CÁ NHÂN",
              icon: Icons.person_outline,
              children: [
                _buildField("Họ và tên", nameCtrl, Icons.badge_outlined),
                Row(
                  children: [
                    Expanded(child: _buildField("Tuổi", ageCtrl, Icons.cake_outlined, type: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField(
                        "Ngày sinh", 
                        dobCtrl, 
                        Icons.calendar_month_outlined, 
                        readOnly: true, 
                        onTap: pickDate
                      )
                    ),
                  ],
                ),
                _buildField("Số CCCD", cccdCtrl, Icons.credit_card_outlined, type: TextInputType.number),
              ],
            ),

            const SizedBox(height: 16),
            _buildSection(
              title: "CÔNG TÁC & LIÊN HỆ",
              icon: Icons.work_outline,
              children: [
                _buildField("Phòng ban", departmentCtrl, Icons.business_outlined),
                _buildField("Chức vụ", roleCtrl, Icons.assignment_ind_outlined),
                _buildField("Số điện thoại", phoneCtrl, Icons.phone_android_outlined, type: TextInputType.number),
                _buildField("Địa chỉ liên hệ", addressCtrl, Icons.location_on_outlined),
              ],
            ),

            const SizedBox(height: 16),
            _buildSection(
              title: "THÔNG TIN PHƯƠNG TIỆN",
              icon: Icons.directions_car_outlined,
              children: [
                _buildField("Biển số chính", plateNumberCtrl, Icons.pin_outlined),
                _buildField("Biển số phụ (nếu có)", vehiclePlatesCtrl, Icons.more_horiz_outlined),
              ],
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: loading ? null : update,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F4C75),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: loading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("LƯU THAY ĐỔI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    final oldImage = widget.person.imagePath;
    return Center(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.blue.shade50,
              backgroundImage: newImage != null
                  ? FileImage(newImage!)
                  : (oldImage.isNotEmpty ? NetworkImage(ApiService.buildUrl(oldImage)) : null),
              child: (newImage == null && oldImage.isEmpty)
                  ? const Icon(Icons.person, size: 50, color: Colors.blueAccent)
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: pickImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF0F4C75)),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F4C75), letterSpacing: 1)),
            ],
          ),
          const Divider(height: 25, thickness: 0.5),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField(String hint, TextEditingController ctrl, IconData icon, {TextInputType? type, bool readOnly = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        readOnly: readOnly,
        onTap: onTap,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 20, color: Colors.grey),
          hintText: hint,
          labelText: hint,
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
          filled: true,
          fillColor: const Color(0xFFF8F9FD),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}
