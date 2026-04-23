class ApiConstants {
  // 1. ĐỊA CHỈ SERVER
  static const bool useLocal = false;

  static const String baseUrl = useLocal
      ? 'http://100.66.128.18:3000/api'
      : 'https://personalfinancetrackerbe.onrender.com/api';

  // 2. CÁC ĐƯỜNG DẪN API (ENDPOINTS)s

  // --- QUẢN LÝ USER & AUTH ---
  static const String profileEndpoint = '/users/profile'; // POST/PUT Profile
  static const String fcmTokenEndpoint = '/users/fcm-token';
  static const String authMeEndpoint = '/auth/me';
  static const String logoutEndpoint = '/logout';
  static const String deleteAccountEndpoint = '/users/account';

  // --- QUẢN LÝ GIAO DỊCH ---
  static const String transactionsEndpoint = '/transactions';
  static const String statsEndpoint = '/stats';
  static const String uploadImageEndpoint = '/upload';

  // --- QUẢN LÝ DANH MỤC ---
  static const String categoriesEndpoint = '/categories';

  // --- QUẢN LÝ NGÂN SÁCH ---
  static const String budgetsEndpoint = '/budgets';

  // --- QUẢN LÝ THÔNG BÁO ---
  static const String notificationsEndpoint = '/notifications';

  static const String exportPdfEndpoint = '/transactions/export-pdf';

  static const String walletsEndpoint = '/wallets';
  static const String transferEndpoint = '/wallets/transfer';

  // 3. CẤU HÌNH FIREBASE (CHỈ DÙNG CHO AUTH SERVICE)
  static const String firebaseApiKey =
      "AIzaSyDOK8gxS-kCPDJ_U1nUV84XLFne_sDVZtA";
}
