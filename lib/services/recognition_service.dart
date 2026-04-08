import 'package:dio/dio.dart';
import '../models/recognition_response.dart';
import '../services/api_service.dart';

class RecognitionService {
  // Đổi ApiProvider.apiClient thành ApiService.dio (hoặc ApiService.apiClient tùy theo khai báo trong file api_service.dart)
  final api = ApiService.dio;

  Future<RecognitionResponse> recognizeVideo(String filePath) async {
    try {
      // Tạo FormData để gửi file (tương đương -F trong Curl)
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(
          filePath,
          filename: filePath
              .split('/')
              .last,
        ),
      });

      // Gửi request POST với query parameters
      final response = await api.post(
        '/recognize-video',
        data: formData,
        queryParameters: {
          'frame_skip': 10,
          'max_frames': 20,
        },
        options: Options(
          contentType: 'multipart/form-data',
          // Nên thêm timeout vì xử lý video thường mất thời gian
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      // Dio thường tự động parse JSON thành Map, nên truyền thẳng vào fromJson
      return RecognitionResponse.fromJson(response.data);
    } catch (e) {
      print("Error in RecognitionService: $e");
      rethrow;
    }
  }
}