class AppConstants {
  static const String appName = '智能剪辑';
  static const String baseUrl = 'http://10.0.2.2:8080';
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String usernameKey = 'username';
  static const String nicknameKey = 'nickname';

  static const List<String> sceneTypes = ['nature', 'portrait', 'dynamic'];
  static const List<String> moods = ['happy', 'sad', 'exciting', 'relaxing'];
  static const List<String> templateCategories = ['festival', 'vlog', 'tutorial'];
  static const List<String> aspectRatios = ['16:9', '9:16'];
  static const List<String> exportFormats = ['mp4', 'avi'];

  static const Map<String, String> sceneTypeNames = {
    'nature': '风景',
    'portrait': '人物',
    'dynamic': '动态',
  };

  static const Map<String, String> moodNames = {
    'happy': '欢快',
    'sad': '抒情',
    'exciting': '激昂',
    'relaxing': '舒缓',
  };

  static const Map<String, String> categoryNames = {
    'festival': '节日',
    'vlog': 'Vlog',
    'tutorial': '教程',
  };
}
