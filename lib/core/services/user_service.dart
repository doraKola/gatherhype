import '../utils/app_config.dart';
import 'api_client.dart';

class UserService {
  static final UserService _i = UserService._();
  factory UserService() => _i;
  UserService._();

  final _api = ApiClient();
  final _base = '${AppConfig.apiUrl}/users';

  Future<Map<String, dynamic>> getTranslationSettings() async {
    return await _api.get('$_base/translation-settings') as Map<String, dynamic>;
  }
}
