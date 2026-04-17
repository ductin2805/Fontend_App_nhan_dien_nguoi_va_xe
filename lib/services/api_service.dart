import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

import '../models/face_register_response.dart';
import '../models/history_item.dart';
import '../models/person_model.dart';
import '../models/person_update_response.dart';
class ApiService {

    static const String baseUrl = "http://192.168.1.11:8000";
    static String buildUrl(String path) {
      if (path.isEmpty) return "";

      if (path.startsWith("/")) {
        return "${dio.options.baseUrl}$path";
      }

      return "${dio.options.baseUrl}/$path";
    }
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
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
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
  static Future<Map<String, dynamic>> getHistoryDetail(String id) async {
    final url = Uri.parse("$baseUrl/history/$id");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception("Failed to load history detail");
    }
  }
  static Future<void> deleteHistory(List<String> ids) async {
    final url = Uri.parse("$baseUrl/history/entries");

    final response = await http.delete(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "ids": ids,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Xóa thất bại");
    }
  }
  static Future<Map<String, dynamic>> getRaw(Uri uri) async {
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      return json.decode(res.body);
    } else {
      throw Exception("API lỗi: ${res.statusCode}");
    }
  }
  static Future<void> deleteAllHistory() async {
    final uri = Uri.parse("$baseUrl/history/all");

    final res = await http.delete(uri);

    if (res.statusCode != 200) {
      throw Exception("Xóa toàn bộ thất bại");
    }
  }
  static Future<List<Person>> getPersons() async {
    final uri = Uri.parse("$baseUrl/face/persons");

    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      final list = data["persons"] as List;
      return list.map((e) => Person.fromJson(e)).toList();
    } else {
      throw Exception("Lỗi load persons");
    }
  }
  static Future<FaceRegisterResponse> registerFace({
    required File file,
    required Map<String, String> fields,
  }) async {
    final uri = Uri.parse("$baseUrl/face/register");

    final request = http.MultipartRequest("POST", uri);

    request.files.add(
      await http.MultipartFile.fromPath("file", file.path),
    );

    request.fields.addAll(fields);

    final res = await request.send();
    final body = await res.stream.bytesToString();

    final data = jsonDecode(body);

    return FaceRegisterResponse.fromJson(data);
  }
  static Future<void> deletePerson(String personId) async {
    final uri = Uri.parse("$baseUrl/face/person/$personId");

    final res = await http.delete(uri);

    if (res.statusCode != 200) {
      throw Exception("Xóa người thất bại");
    }
  }
  static Future<PersonUpdateResponse> updatePerson({
    required String personId,
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse("$baseUrl/face/person/$personId");

    final res = await http.put(
      uri,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      return PersonUpdateResponse.fromJson(data);
    } else {
      throw Exception("Cập nhật thất bại");
    }
  }
}