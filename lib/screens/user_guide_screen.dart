import 'package:flutter/material.dart';

class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      appBar: AppBar(
        title: const Text("HƯỚNG DẪN SỬ DỤNG"),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader("Chào mừng bạn đến với AI Traffic Vision", 
                "Hệ thống giám sát giao thông thông minh ứng dụng trí tuệ nhân tạo. Dưới đây là hướng dẫn chi tiết các chức năng:"),
            const SizedBox(height: 20),
            
            _guideItem(
              icon: Icons.video_collection_rounded,
              color: const Color(0xFF4facfe),
              title: "VIDEO FILE (Phân tích Video)",
              content: "• Chọn video từ thư viện điện thoại.\n"
                  "• Cấu hình Skip Frame để tăng tốc độ phân tích.\n"
                  "• Cấu hình Max Frame để giới hạn số khung hình xử lý.\n"
                  "• Bật 'Biển chuẩn' để chỉ xem các khung hình chứa biển số đúng định dạng.\n"
                  "• Nhấn vào các frame hình nhỏ bên dưới để tua nhanh đến thời điểm đó.",
            ),
            
            _guideItem(
              icon: Icons.videocam_rounded,
              color: const Color(0xFFff0844),
              title: "LIVE CAMERA (Giám sát trực tiếp)",
              content: "• Kết nối với Camera IP hoặc Camera điện thoại để giám sát thời gian thực.\n"
                  "• Hệ thống tự động khoanh vùng phương tiện và nhận diện biển số.\n"
                  "• Tự động đối soát danh tính nếu biển số đã có trong cơ sở dữ liệu.\n"
                  "• Hỗ trợ Zoom và điều chỉnh thông số AI trực tiếp.",
            ),
            
            _guideItem(
              icon: Icons.commute_rounded,
              color: const Color(0xFF43e97b),
              title: "GIAO THÔNG (Thống kê)",
              content: "• Theo dõi lưu lượng phương tiện đang hoạt động.\n"
                  "• Phân loại phương tiện: Xe máy, Ô tô, Xe tải...\n"
                  "• Báo cáo biểu đồ về mật độ giao thông theo khung giờ.",
            ),
            
            _guideItem(
              icon: Icons.vignette_rounded,
              color: const Color(0xFFfa709a),
              title: "BIỂN SỐ (Quản lý)",
              content: "• Tra cứu lịch sử các biển số đã được nhận diện.\n"
                  "• Tìm kiếm chủ sở hữu dựa trên cơ sở dữ liệu.\n"
                  "• Xuất báo cáo danh sách biển số ra định dạng PDF.",
            ),
            
            _guideItem(
              icon: Icons.face_rounded,
              color: const Color(0xFFf6d365),
              title: "KHUÔN MẶT (Danh tính)",
              content: "• Đăng ký thành viên mới bằng cách chụp ảnh khuôn mặt.\n"
                  "• Quản lý thông tin chi tiết: Tên, CCCD, Biển số xe đi kèm.\n"
                  "• Nhận diện người quen/người lạ trong luồng giám sát Live.",
            ),

            _guideItem(
              icon: Icons.psychology,
              color: Colors.deepPurple,
              title: "TRỢ LÝ AI (Chatbot)",
              content: "• Nhấn vào nút biểu tượng bộ não ở góc màn hình chính.\n"
                  "• Hỏi đáp về luật giao thông, thông tin biển số hoặc hướng dẫn kỹ thuật.\n"
                  "• Trợ lý sẽ phản hồi dựa trên dữ liệu thời gian thực của ứng dụng.",
            ),
            
            const SizedBox(height: 30),
            const Center(
              child: Text("Phiên bản Pro 2.5.0 • Powered by AI Vision Team", 
                style: TextStyle(color: Colors.grey, fontSize: 11)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F4C75))),
        const SizedBox(height: 8),
        Text(sub, style: const TextStyle(fontSize: 13, color: Colors.black54)),
      ],
    );
  }

  Widget _guideItem({required IconData icon, required Color color, required String title, required String content}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 70, right: 16, bottom: 16),
            child: Text(content, style: const TextStyle(color: Colors.black87, height: 1.5, fontSize: 13)),
          )
        ],
      ),
    );
  }
}
