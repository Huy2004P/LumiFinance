# LumiFinance - Quản lý thu chi (Personal Finance Tracker)

**LumiFinance** là ứng dụng di động được xây dựng bằng **Flutter**, thuộc đồ án môn Điện toán đám mây. Ứng dụng cung cấp các tính năng giúp người dùng quản lý tài chính cá nhân một cách hiệu quả, theo dõi thu chi, quản lý ví, ngân sách và phân tích thống kê chi tiết.

## 📸 Hình ảnh ứng dụng (Screenshots)

<p align="center">
  <img src="https://github.com/user-attachments/assets/10e651c1-bd78-4f7c-a423-37d2c3ef454b" width="240" />
  <img src="https://github.com/user-attachments/assets/ea57101a-f2ae-42c8-8a2e-e9e3587245a4" width="240" />
  <img src="https://github.com/user-attachments/assets/a26745f2-a3e9-48cb-be7c-54d14752b0c8" width="240" />
  <img src="https://github.com/user-attachments/assets/1bc13726-b3a2-4ba2-bb4f-537913414a1a" width="240" />
  <img src="https://github.com/user-attachments/assets/ccc409db-537b-4fae-9c4e-8af7dad6eec0" width="240" />
  <img src="https://github.com/user-attachments/assets/b15861a7-9665-41fa-b81c-86318e8aa313" width="240" />
  <img src="https://github.com/user-attachments/assets/df55dd5b-777c-4e0e-9e97-16843009d86e" width="240" />
  <img src="https://github.com/user-attachments/assets/1ec1614d-6856-40b1-bdc9-0117771ca606" width="240" />
  <img src="https://github.com/user-attachments/assets/17ae945a-5db3-4f70-aa94-949ca3fe1252" width="240" />
  <img src="https://github.com/user-attachments/assets/1fae0c4e-840a-482f-888a-8ad20ac4f430" width="240" />
  <img src="https://github.com/user-attachments/assets/bc920419-db24-413e-89d0-352cdea146a2" width="240" />
</p>

## 🌟 Tính năng nổi bật

- **Xác thực người dùng:** Đăng nhập, đăng ký, quên mật khẩu (Tích hợp Firebase Auth).
- **Quản lý hồ sơ:** Tạo, xem và chỉnh sửa thông tin cá nhân.
- **Quản lý tài chính cốt lõi:**
  - **Ví (Wallets):** Quản lý nhiều ví khác nhau, chuyển tiền giữa các ví.
  - **Giao dịch (Transactions):** Thêm, sửa, xóa các khoản thu/chi. Chi tiết giao dịch rành mạch.
  - **Danh mục (Categories):** Phân loại giao dịch theo các danh mục chi tiêu/thu nhập đa dạng.
  - **Ngân sách (Budgets):** Đặt giới hạn chi tiêu và theo dõi mức độ hoàn thành ngân sách.
- **Thống kê & Lịch sử:** Biểu đồ trực quan và danh sách lịch sử giao dịch.
- **Thông báo:** Nhận thông báo (Push Notification qua Firebase Messaging).
- **Trích xuất dữ liệu:** Xuất lịch sử giao dịch ra file PDF.

## 🎨 Ngôn ngữ thiết kế (Design Language)

Dự án áp dụng **Apple Design Language** (Minimalist & Clean):
- Sử dụng các tone màu đặc trưng của Apple: `pureWhite`, `lightGray`, `nearBlack`, `appleBlue`.
- Kiểu chữ tinh tế (Typography) với `displayHero` (to, hầm hố) và `body` gọn gàng, mang lại trải nghiệm người dùng hiện đại và mượt mà.

## 🛠 Công nghệ & Thư viện sử dụng

- **Khung giao diện (Framework):** [Flutter](https://flutter.dev/) (SDK ^3.11.4)
- **Quản lý trạng thái (State Management):** `provider`
- **Kết nối mạng & API:** `dio`, `http`
- **Cơ sở dữ liệu đám mây & Dịch vụ:** 
  - `firebase_core`, `firebase_auth`, `cloud_firestore`
  - `firebase_messaging` (Push Notifications)
- **Lưu trữ cục bộ:** `shared_preferences`
- **Xử lý tiện ích:** `jwt_decoder` (xử lý Token), `intl` (Định dạng ngày/tiền tệ), `image_picker` (Tải ảnh lên)
- **UI & Thiết kế:** `cupertino_icons`, `google_fonts`, `flutter_spinkit`
- **File & Share:** `path_provider`, `flutter_pdfview`, `html_to_pdf_plus`, `share_plus`

## 📁 Cấu trúc thư mục (Folder Structure)

```text
lib/
├── config/        # Cấu hình hệ thống (API endpoints, biến môi trường...)
├── screens/       # Giao diện người dùng (Home, Wallet, Budget, Auth...)
├── services/      # Xử lý logic và gọi API (AuthService, TransactionService...)
├── theme/         # Cấu hình thiết kế (Apple design system)
└── main.dart      # Điểm bắt đầu của ứng dụng
```

## ⚙️ Cài đặt & Chạy ứng dụng

1. **Yêu cầu hệ thống:**
   - Flutter SDK đã được cài đặt và thiết lập đường dẫn (Path).
   - Thiết bị di động thật hoặc Emulator (Android/iOS).

2. **Clone dự án (nếu có URL repository) & Cài đặt thư viện:**
   ```bash
   flutter pub get
   ```

3. **Cấu hình môi trường (API & Firebase):**
   - Đảm bảo file `google-services.json` (Android) / `GoogleService-Info.plist` (iOS) đã có trong dự án cho Firebase.
   - Các API Endpoint hiện được trỏ về backend `https://personalfinancetrackerbe.onrender.com/api` (hoặc localhost) tại `lib/config/api_constants.dart`.

4. **Chạy ứng dụng:**
   ```bash
   flutter run
   ```

---
*Dự án được xây dựng với mục đích học thuật và quản lý tài chính cá nhân. Developed for Cloud Computing Project.*
