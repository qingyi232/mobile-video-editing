import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  bool _isLoggedIn = false;
  String? _token;
  int? _userId;
  String? _username;
  String? _nickname;
  String? _avatar;
  bool _isLoading = false;

  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  int? get userId => _userId;
  String? get username => _username;
  String? get nickname => _nickname;
  String? get avatar => _avatar;
  bool get isLoading => _isLoading;

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConstants.tokenKey);
    if (_token != null) {
      _userId = prefs.getInt(AppConstants.userIdKey);
      _username = prefs.getString(AppConstants.usernameKey);
      _nickname = prefs.getString(AppConstants.nicknameKey);
      // 验证 token 是否仍然有效
      try {
        final res = await _api.getProfile();
        if (res['code'] == 200) {
          _isLoggedIn = true;
        } else {
          await _clearLoginData();
        }
      } catch (_) {
        // token 无效或后端不可达，清除登录态
        await _clearLoginData();
      }
      notifyListeners();
    }
  }

  Future<void> _clearLoginData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userIdKey);
    await prefs.remove(AppConstants.usernameKey);
    await prefs.remove(AppConstants.nicknameKey);
    _token = null;
    _userId = null;
    _username = null;
    _nickname = null;
    _isLoggedIn = false;
  }

  Future<String?> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _api.login(username, password);
      if (result['code'] == 200) {
        final data = result['data'];
        await _saveLoginData(data);
        return null;
      }
      return result['message'] ?? '登录失败';
    } catch (e) {
      return '网络错误，请检查后端服务是否启动';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> register(String username, String password,
      {String? nickname, String? email}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _api.register(username, password,
          nickname: nickname, email: email);
      if (result['code'] == 200) {
        final data = result['data'];
        await _saveLoginData(data);
        return null;
      }
      return result['message'] ?? '注册失败';
    } catch (e) {
      return '网络错误，请检查后端服务是否启动';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveLoginData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    _token = data['token'];
    _userId = data['userId'];
    _username = data['username'];
    _nickname = data['nickname'];
    _avatar = data['avatar'];
    _isLoggedIn = true;

    await prefs.setString(AppConstants.tokenKey, _token!);
    await prefs.setInt(AppConstants.userIdKey, _userId!);
    await prefs.setString(AppConstants.usernameKey, _username!);
    if (_nickname != null) {
      await prefs.setString(AppConstants.nicknameKey, _nickname!);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _isLoggedIn = false;
    _token = null;
    _userId = null;
    _username = null;
    _nickname = null;
    _avatar = null;
    notifyListeners();
  }
}
