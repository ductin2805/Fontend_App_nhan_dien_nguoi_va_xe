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
  late TextEditingController codeCtrl;
  late TextEditingController departmentCtrl;
  late TextEditingController roleCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController addressCtrl;
  late TextEditingController ageCtrl;
  late TextEditingController dobCtrl;
  late TextEditingController cccdCtrl;
  File? newImage;
  final baseUrl = "http://192.168.1.11:8000";
  bool loading = false;
  String buildImage(String path) {
    if (path.isEmpty) return "";

    if (path.startsWith("/")) {
      return "$baseUrl$path";
    }

    return "$baseUrl/$path";
  }

  @override
  void initState() {
    super.initState();

    final p = widget.person;

    nameCtrl = TextEditingController(text: p.name);
    codeCtrl = TextEditingController(text: p.personCode);
    departmentCtrl = TextEditingController(text: p.info.department);
    roleCtrl = TextEditingController(text: p.info.role);
    phoneCtrl = TextEditingController(text: p.info.phone);
    addressCtrl = TextEditingController(text: p.info.address);
    ageCtrl = TextEditingController(text: p.info.age);
    dobCtrl = TextEditingController(text: p.info.dob);
    cccdCtrl = TextEditingController(text: p.info.cccd);
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

  String? validate() {
    if (nameCtrl.text.isEmpty) return "Tên không được bỏ trống";

    if (phoneCtrl.text.isNotEmpty &&
        !RegExp(r'^\d{10}$').hasMatch(phoneCtrl.text)) {
      return "SĐT phải 10 số";
    }

    if (cccdCtrl.text.isNotEmpty &&
        !RegExp(r'^\d{12}$').hasMatch(cccdCtrl.text)) {
      return "CCCD phải 12 số";
    }

    return null;
  }

  Future<void> update() async {
    setState(() => loading = true);

    try {
      final uri = Uri.parse("$baseUrl/face/person/${widget.person.personId}");

      final request = http.MultipartRequest("PUT", uri);

      /// nếu có ảnh mới
      if (newImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath("file", newImage!.path),
        );
      }

      request.fields.addAll({
        "name": nameCtrl.text,
        "person_code": codeCtrl.text,
        "department": departmentCtrl.text,
        "role": roleCtrl.text,
        "phone": phoneCtrl.text,
        "address": addressCtrl.text,
        "age": ageCtrl.text,
        "date_of_birth": dobCtrl.text,
        "cccd": cccdCtrl.text,
      });
      print({
        "name": nameCtrl.text,
        "person_code": codeCtrl.text,
        "department": departmentCtrl.text,
        "role": roleCtrl.text,
        "phone": phoneCtrl.text,
        "address": addressCtrl.text,
        "age": ageCtrl.text,
        "date_of_birth": dobCtrl.text,
        "cccd": cccdCtrl.text,
      });
      final res = await request.send();
      final body = await res.stream.bytesToString();

      print("STATUS: ${res.statusCode}");
      print("BODY: $body");

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cập nhật thành công")),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception("Update failed");
      }


    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    }

    setState(() => loading = false);
  }
  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        newImage = File(picked.path);
      });
    }
  }

  Widget avatar() {
    final oldImage = widget.person.imagePath;

    return GestureDetector(
      onTap: pickImage,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 55,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: newImage != null
              ? FileImage(newImage!)
              : (oldImage.isNotEmpty
              ? NetworkImage(buildImage(oldImage))
              : null),
          child: (newImage == null && oldImage.isEmpty)
              ? const Icon(Icons.person, size: 40)
              : null,
        ),
      ),
    );
  }
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chỉnh sửa thông tin")),
      backgroundColor: const Color(0xfff5f6fa),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            avatar(),
            const SizedBox(height: 16),
            input("Tên", nameCtrl),
            input("Mã nhân sự", codeCtrl),
            input("Phòng ban", departmentCtrl),
            input("Chức vụ", roleCtrl),
            input("SĐT", phoneCtrl, type: TextInputType.number),
            input("Địa chỉ", addressCtrl),
            input("Tuổi", ageCtrl, type: TextInputType.number),
            input("Ngày sinh (yyyy-MM-dd)", dobCtrl),
            input("CCCD", cccdCtrl, type: TextInputType.number),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : update,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text("LƯU THAY ĐỔI"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}