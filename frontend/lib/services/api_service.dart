import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 120),
      receiveTimeout: const Duration(seconds: 120),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (options.data is! FormData) {
          options.headers['Content-Type'] = 'application/json';
        } else {
          options.headers.remove('Content-Type');
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 403 || error.response?.statusCode == 401) {
          // token 失效，清除本地登录态
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(AppConstants.tokenKey);
        }
        handler.next(error);
      },
    ));
  }

  // ==================== Auth ====================

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await _dio.post('/api/auth/login', data: {
      'username': username,
      'password': password,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(String username, String password,
      {String? nickname, String? email}) async {
    final response = await _dio.post('/api/auth/register', data: {
      'username': username,
      'password': password,
      'nickname': nickname,
      'email': email,
    });
    return response.data as Map<String, dynamic>;
  }

  // ==================== User ====================

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get('/api/user/profile');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getUserStats() async {
    final response = await _dio.get('/api/user/stats');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, String> updates) async {
    final response = await _dio.put('/api/user/profile', data: updates);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadAvatar(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post('/api/user/avatar', data: formData);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> changePassword(
      String oldPassword, String newPassword) async {
    final response = await _dio.post('/api/user/change-password', data: {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });
    return response.data as Map<String, dynamic>;
  }

  // ==================== Video Projects ====================

  Future<Map<String, dynamic>> getProjects({int? status}) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    final response = await _dio.get('/api/video/projects', queryParameters: params);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getProject(int id) async {
    final response = await _dio.get('/api/video/projects/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createProject(String title, String description) async {
    final response = await _dio.post('/api/video/projects', data: {
      'title': title,
      'description': description,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProject(int id, Map<String, dynamic> updates) async {
    final response = await _dio.put('/api/video/projects/$id', data: updates);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteProject(int id) async {
    await _dio.delete('/api/video/projects/$id');
  }

  // ==================== Video Processing ====================

  Future<Map<String, dynamic>> uploadVideo(String filePath, {int? projectId}) async {
    final map = <String, dynamic>{
      'file': await MultipartFile.fromFile(filePath),
    };
    if (projectId != null) {
      map['projectId'] = projectId.toString();
    }
    final formData = FormData.fromMap(map);
    final response = await _dio.post('/api/video/upload', data: formData);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> trimVideo(
      String inputPath, double startTime, double endTime) async {
    final response = await _dio.post('/api/video/trim', data: {
      'inputPath': inputPath,
      'startTime': startTime,
      'endTime': endTime,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> concatVideos(List<String> inputPaths) async {
    final response = await _dio.post('/api/video/concat', data: {
      'inputPaths': inputPaths,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addMusic(
      String videoPath, String audioPath, double volume) async {
    final response = await _dio.post('/api/video/add-music', data: {
      'videoPath': videoPath,
      'audioPath': audioPath,
      'volume': volume,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addTransition(
      List<String> inputPaths, String transitionType) async {
    final response = await _dio.post('/api/video/transition', data: {
      'inputPaths': inputPaths,
      'transitionType': transitionType,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> separateVoice(String videoPath) async {
    final response = await _dio.post('/api/video/separate-voice', data: {
      'videoPath': videoPath,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> changeRatio(String videoPath, String ratio) async {
    final response = await _dio.post('/api/video/change-ratio', data: {
      'videoPath': videoPath,
      'ratio': ratio,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> exportVideo(int projectId, String format) async {
    final response = await _dio.post('/api/video/export', data: {
      'projectId': projectId,
      'format': format,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> analyzeClarity(
      String videoPath, {int sampleCount = 10}) async {
    final response = await _dio.post('/api/video/analyze-clarity', data: {
      'videoPath': videoPath,
      'sampleCount': sampleCount,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> recognizeScene(String videoPath) async {
    final response = await _dio.post('/api/video/recognize-scene', data: {
      'videoPath': videoPath,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> generateSubtitle(String videoPath) async {
    final response = await _dio.post('/api/video/subtitle', data: {
      'videoPath': videoPath,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> burnSubtitle(
      String videoPath, String subtitleText) async {
    final response = await _dio.post('/api/video/burn-subtitle', data: {
      'videoPath': videoPath,
      'subtitleText': subtitleText,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> smartClip(String videoPath,
      {int sampleCount = 10, double threshold = 60}) async {
    final response = await _dio.post('/api/video/smart-clip', data: {
      'videoPath': videoPath,
      'sampleCount': sampleCount,
      'threshold': threshold,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> applyFilter(
      String videoPath, String filterType) async {
    final response = await _dio.post('/api/video/apply-filter', data: {
      'videoPath': videoPath,
      'filterType': filterType,
    });
    return response.data as Map<String, dynamic>;
  }

  // ==================== Music ====================

  Future<Map<String, dynamic>> getAllMusic() async {
    final response = await _dio.get('/api/music');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMusicByCategory(String category) async {
    final response = await _dio.get('/api/music/category/$category');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadMusic({
    required String filePath,
    required String title,
    String artist = '',
    String category = 'dynamic',
    String mood = 'happy',
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
      'title': title,
      'artist': artist,
      'category': category,
      'mood': mood,
    });
    final response = await _dio.post('/api/music/upload', data: formData);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> recommendMusic({
    String? sceneType,
    double? videoDuration,
    String? mood,
  }) async {
    final response = await _dio.post('/api/music/recommend', data: {
      'sceneType': sceneType,
      'videoDuration': videoDuration,
      'mood': mood,
    });
    return response.data as Map<String, dynamic>;
  }

  // ==================== Templates ====================

  Future<Map<String, dynamic>> getAllTemplates() async {
    final response = await _dio.get('/api/templates');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getTemplatesByCategory(String category) async {
    final response = await _dio.get('/api/templates/category/$category');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> useTemplate(int id) async {
    final response = await _dio.post('/api/templates/$id/use');
    return response.data as Map<String, dynamic>;
  }

  /// 将后端返回的本地路径转为可访问的媒体 URL（模拟器访问本机）
  static String mediaUrlFromServerPath(String serverPath) {
    if (serverPath.isEmpty) return '';
    var p = serverPath.replaceAll('\\', '/');
    if (p.startsWith('./')) p = p.substring(1);
    if (!p.startsWith('/')) p = '/$p';
    return '${AppConstants.baseUrl}$p';
  }
}
