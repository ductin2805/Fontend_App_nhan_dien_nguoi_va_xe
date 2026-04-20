import 'package:ai_traffic_app/screens/person_edit_screen.dart';
import 'package:flutter/material.dart';
import '../models/person_model.dart';
import '../services/api_service.dart';

class PersonDetailScreen extends StatefulWidget {
  final Person person;

  const PersonDetailScreen({super.key, required this.person});

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  late Person currentPerson;

  @override
  void initState() {
    super.initState();
    currentPerson = widget.person;
  }

  @override
  Widget build(BuildContext context) {
    final info = currentPerson.info;

    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      appBar: AppBar(
        title: const Text("CHI TIẾT THÀNH VIÊN"),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note, size: 28),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PersonEditScreen(person: currentPerson),
                ),
              );

              if (result == true) {
                // Quay lại danh sách để refresh dữ liệu mới nhất
                if (mounted) Navigator.pop(context, true);
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- AVATAR SECTION ---
            Center(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.blue.shade50,
                  backgroundImage: currentPerson.imagePath.isNotEmpty
                      ? NetworkImage(ApiService.buildUrl(currentPerson.imagePath))
                      : null,
                  child: currentPerson.imagePath.isEmpty
                      ? Text(
                          currentPerson.name.isNotEmpty ? currentPerson.name[0] : "?",
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(currentPerson.name,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B262C))),
            Text(info.role.toUpperCase(),
                style: const TextStyle(fontSize: 12, color: Colors.grey, letterSpacing: 2, fontWeight: FontWeight.w500)),
            const SizedBox(height: 30),

            // --- INFO SECTIONS ---
            _buildSection(
              title: "THÔNG TIN CÁ NHÂN",
              icon: Icons.person_outline,
              children: [
                _buildDetailRow("Tuổi", info.age, Icons.cake_outlined),
                _buildDetailRow("Ngày sinh", info.dob, Icons.calendar_month_outlined),
                _buildDetailRow("Số CCCD", info.cccd, Icons.credit_card_outlined),
              ],
            ),

            _buildSection(
              title: "CÔNG TÁC & LIÊN HỆ",
              icon: Icons.work_outline,
              children: [
                _buildDetailRow("Phòng ban", info.department, Icons.business_outlined),
                _buildDetailRow("Số điện thoại", info.phone, Icons.phone_android_outlined),
                _buildDetailRow("Địa chỉ", info.address, Icons.location_on_outlined),
              ],
            ),

            _buildSection(
              title: "THÔNG TIN PHƯƠNG TIỆN",
              icon: Icons.directions_car_outlined,
              children: [
                _buildDetailRow("Biển số chính", info.plateNumber, Icons.pin_outlined),
                _buildDetailRow("Biển số phụ", info.vehiclePlates, Icons.more_horiz_outlined),
              ],
            ),

            const SizedBox(height: 20),

            // --- DELETE ACTION ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: OutlinedButton.icon(
                onPressed: _onDelete,
                icon: const Icon(Icons.delete_outline, size: 20),
                label: const Text("XÓA THÀNH VIÊN"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red, width: 1.2),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
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
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F4C75), letterSpacing: 1)),
            ],
          ),
          const Divider(height: 25, thickness: 0.5),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value.isEmpty ? "Chưa cập nhật" : value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("⚠️ Xác nhận xóa"),
        content: Text("Dữ liệu về ${currentPerson.name} sẽ bị xóa vĩnh viễn khỏi hệ thống. Bạn có chắc chắn không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("HỦY")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("XÓA NGAY", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deletePerson(currentPerson.personId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa thành công")));
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
    }
  }
}
