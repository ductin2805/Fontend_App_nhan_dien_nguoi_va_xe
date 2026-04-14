import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'dart:io';
import '../utils/pdf_service.dart';
import 'home_menu.dart';
class HistoryDetailScreen extends StatefulWidget {
  final String id;

  const HistoryDetailScreen({super.key, required this.id});

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  Map<String, dynamic>? data;
  bool isLoading = true;

  final String baseUrl = "http://192.168.1.11:8000";

  @override
  void initState() {
    super.initState();
    loadDetail();
  }

  Future<void> loadDetail() async {
    try {
      final res = await ApiService.getHistoryDetail(widget.id);

      setState(() {
        data = res;
        isLoading = false;
      });
    } catch (e) {
      print("ERROR: $e");
      setState(() => isLoading = false);
    }
  }

  String buildImageUrl(String path) {
    path = path.trim();
    if (path.startsWith("/")) {
      path = path.substring(1);
    }
    return "$baseUrl/$path";
  }

  /// 🔥 Không cho null lên UI
  String v(dynamic value) {
    if (value == null) return "Không có";
    if (value.toString().isEmpty) return "Không có";
    return value.toString();
  }

  /// 🔥 Việt hoá type
  String getTypeName(String? type) {
    switch (type) {
      case "video_processing":
        return "Nhận diện video";
      case "image_detection":
        return "Phân tích hình ảnh";
      case "plate_recognition":
        return "Nhận diện biển số";
      case "object_detection":
        return "Nhận diện đối tượng";
      case "face_recognition":
        return "Nhận diện khuôn mặt";
      default:
        return "Không xác định";
    }
  }
  String translateKey(String key) {
    switch (key) {

    /// 🔹 SUMMARY
      case "total_frames":
        return "Tổng số frame";
      case "processed_frames":
        return "Frame đã xử lý";
      case "unique_plates":
        return "Số biển số";
      case "total_detections":
        return "Tổng phát hiện";
      case "processing_time":
        return "Thời gian xử lý";

    /// 🔹 IMAGE
      case "total_vehicles":
        return "Số phương tiện";
      case "plates_detected":
        return "Biển số phát hiện";
      case "plates_found":
        return "Danh sách biển số";

    /// 🔹 OBJECT
      case "detections":
        return "Số đối tượng";
      case "recognize_plates":
        return "Nhận diện biển số";

    /// 🔹 VIDEO PROCESSING
      case "frame_skip":
        return "Bỏ qua frame";
      case "max_frames":
        return "Giới hạn frame";
      case "frames_processed":
        return "Số frame xử lý";

    /// 🔹 FACE
      case "total_faces":
        return "Số khuôn mặt";
      case "is_known":
        return "Đã xác thực";
      case "match_score":
        return "Độ tin cậy";
      case "person_name":
        return "Tên";

    /// 🔹 PERSON INFO
      case "phone":
        return "Số điện thoại";
      case "address":
        return "Địa chỉ";
      case "department":
        return "Phòng ban";
      case "role":
        return "Chức vụ";
      case "age":
        return "Tuổi";
      case "date_of_birth":
        return "Ngày sinh";
      case "cccd":
        return "CCCD";
     //role vehicle
      case "car":
        return "Ô tô";
      case "motorcycle":
        return "Xe máy";
      case "truck":
        return "Xe tải";
      case "bus":
        return "Xe buýt";
      case "person":
        return "Người";
    /// 🔹 DEFAULT
      default:
        return key.replaceAll("_", " ");
    }
  }
  Widget _row(String title, dynamic value) {
    String display;

    if (value == null || value.toString().isEmpty) {
      display = "Không có";
    } else if (value is bool) {
      display = value ? "Có" : "Không";
    } else if (value is double) {
      display = value.toStringAsFixed(2);
    } else {
      display = value.toString();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            display,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, IconData icon, Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (data == null) {
      return const Scaffold(
        body: Center(child: Text("Không có dữ liệu")),
      );
    }

    final summary = data!["summary"] ?? {};
    final full = data!["full_result"] ?? {};

    final videoInfo = full["video_info"] ?? {};
    final processing = full["processing_info"] ?? {};
    final plates = full["plates"] ?? [];
    final vehicles = full["vehicles"] ?? [];
    final detections = full["detections"] ?? [];
    final faces = full["faces"] ?? [];

    final imagePath = data!["representative_image_path"];


    return Scaffold(
      appBar: AppBar(
        title: const Text("Chi tiết lịch sử"),

        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context); //
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeMenu()),
              );
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// 🔹 IMAGE
            if (imagePath != null && imagePath.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(buildImageUrl(imagePath)),
              ),

            const SizedBox(height: 16),

            /// 🔹 THÔNG TIN CHUNG
            _section(
              "THÔNG TIN CHUNG",
              Icons.info,
              Column(
                children: [
                  _row("Loại", getTypeName(data!["type"])),
                  _row("ID", data!["id"]),
                ],
              ),
            ),

            /// 🔹 SUMMARY
            _section(
              "KẾT QUẢ",
              Icons.analytics,
              Column(
                children: summary.entries.map<Widget>((e) {
                  return _row(
                    translateKey(e.key),
                    e.value,
                  );
                }).toList(),
              ),
            ),

            /// 🔹 VIDEO
            if (videoInfo.isNotEmpty)
              _section(
                "VIDEO",
                Icons.video_file,
                Column(
                  children: [
                    _row("FPS", videoInfo["fps"]),
                    _row("Độ dài", "${videoInfo["duration"]} giây"),
                    _row("Kích thước",
                        "${videoInfo["width"]}x${videoInfo["height"]}"),
                  ],
                ),
              ),

            /// 🔹 XỬ LÝ
            if (processing.isNotEmpty)
              _section(
                "XỬ LÝ",
                Icons.settings,
                Column(
                  children: processing.entries.map<Widget>((e) {
                    return _row(translateKey(e.key), e.value);
                  }).toList(),
                ),
              ),

            /// 🔹 BIỂN SỐ
            if (plates.isNotEmpty)
              _section(
                "BIỂN SỐ",
                Icons.confirmation_number,
                Wrap(
                  spacing: 8,
                  children: plates.map<Widget>((p) {
                    return Chip(
                      backgroundColor: Colors.green.shade100,
                      label: Text(v(p["plate"] ?? p)),
                    );
                  }).toList(),
                ),
              ),

            /// 🔹 VEHICLES
            if (vehicles.isNotEmpty)
              _section(
                "PHƯƠNG TIỆN",
                Icons.directions_car,
                Column(
                  children: vehicles.map<Widget>((vcl) {
                    final plate = vcl["plate"];
                    return _row(
                      translateKey(vcl["class_name"]),
                      plate != null ? plate["text"] : "Không có biển",
                    );
                  }).toList(),
                ),
              ),

            /// 🔹 OBJECT
            if (detections.isNotEmpty)
              _section(
                "ĐỐI TƯỢNG",
                Icons.search,
                _row("Số lượng", detections.length),
              ),

            /// 🔹 FACE
            if (faces.isNotEmpty)
              _section(
                "KHUÔN MẶT",
                Icons.face,
                Column(
                  children: faces.map<Widget>((f) {
                    final person = f["person"];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _row("Độ tin cậy",
                            "${(f["match_score"] * 100).toStringAsFixed(1)}%"),

                        if (person != null) ...[
                          _row("Tên", person["name"]),
                          _row("SĐT", person["info"]?["phone"]),
                          _row("Địa chỉ", person["info"]?["address"]),
                          _row("Ngày sinh", person["info"]?["date_of_birth"]),
                          _row("CCCD", person["info"]?["cccd"]),
                          _row("Nơi làm việc", person["info"]?["department"]),
                          _row("Chức vụ", person["info"]?["role"]),
                          _row("Tuổi", person["info"]?["age"]),
                        ] else
                          const Text("Người lạ"),
                      ],

                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 20),

            Row(
              children: [

                /// 🔴 XÓA
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final confirm = await showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Xác nhận"),
                          content: const Text("Bạn có chắc muốn xóa bản ghi này không?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Hủy"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("Xóa"),
                            ),
                          ],
                        ),
                      );

                      if (confirm != true) return;

                      /// 🔥 loading
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );

                      try {
                        await ApiService.deleteHistory([data!["id"]]);

                        Navigator.pop(context); // đóng loading

                        /// 🔥 thông báo
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Đã xóa thành công")),
                        );

                        /// 🔥 quay về màn trước
                        Navigator.pop(context, true);

                      } catch (e) {
                        Navigator.pop(context); // đóng loading

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Lỗi: $e")),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "XÓA BẢN GHI",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                /// 🔵 EXPORT
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await PdfService.exportHistoryPDF(
                          data: data!,
                          getTypeName: getTypeName,
                          translateKey: translateKey,
                          v: v,
                          buildImageUrl: buildImageUrl,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Xuất PDF thành công")),
                        );

                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("$e")),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "XUẤT CSV",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}