import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

import '../models/history_item.dart';
class ApiService {

  static const String baseUrl = "http://192.168.1.11:8000";

  /// 🔥 gửi ảnh + chọn endpoint
  static Future<Map<String, dynamic>> sendImage(
      File image, {
        String endpoint = "detect", // mặc định
      }) async {

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/$endpoint'),
    );

    request.files.add(
      await http.MultipartFile.fromPath('file', image.path),
    );

    var response = await request.send();

    // 🔥 check lỗi HTTP
    if (response.statusCode != 200) {
      throw Exception("Server lỗi: ${response.statusCode}");
    }

    var res = await http.Response.fromStream(response);

    // 🔥 check JSON lỗi từ server
    final data = jsonDecode(utf8.decode(res.bodyBytes));

    if (data["error"] != null) {
      throw Exception(data["error"]);
    }

    return data;
  }
  // 1. Khai báo biến dio static để các Service khác có thể gọi ApiService.dio
  static final Dio dio = Dio(
    BaseOptions(
      // 2. Thay đổi địa chỉ IP này cho đúng với server của bạn
      baseUrl: 'http://192.168.1.11:8000',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60), // Tăng thời gian chờ vì xử lý video lâu
      headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );
  // Bạn có thể thêm các interceptor để log lỗi hoặc thêm token nếu cần
  static void init() {
    dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));
  }
  static Future<List<HistoryItem>> getHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    final url = Uri.parse(
        "$baseUrl/history?limit=$limit&offset=$offset");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));

      return (data['history'] as List)
          .map((e) => HistoryItem.fromJson(e))
          .toList();
    } else {
      throw Exception("Failed to load history");
    }
  }
}