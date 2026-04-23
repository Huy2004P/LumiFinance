import '../services/api_service.dart';
import '../config/api_constants.dart';

class NotificationService {
  Future<Map<String, dynamic>> getNotificationData() async {
    try {
      final response = await ApiService().get(
        ApiConstants.notificationsEndpoint,
      );
      return response.data;
    } catch (e) {
      return {'data': [], 'unreadCount': 0};
    }
  }
}
