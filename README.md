# 🌟 Lumi Finance

**Lumi Finance** là một ứng dụng quản lý tài chính cá nhân hiện đại được xây dựng trên nền tảng Flutter. Với triết lý "Minh bạch - Đơn giản - Tinh tế", ứng dụng giúp người dùng xóa tan sự mù mờ trong chi tiêu và định hướng rõ ràng cho các mục tiêu tiết kiệm dài hạn.

---

## ✨ Tính năng nổi bật

- **Lumi Dashboard:** Theo dõi biến động số dư và dòng tiền (Cash flow) thông qua biểu đồ trực quan.
- **Smart Tracking:** Ghi chép các khoản thu chi nhanh chóng với phân loại thông minh.
- **Financial Goals:** Thiết lập và theo dõi tiến độ các mục tiêu tài chính (Mua nhà, du lịch, quỹ khẩn cấp).
- **Lumi Insights:** Báo cáo chi tiết hàng tuần/tháng giúp tối ưu hóa thói quen tiêu dùng.
- **Đa tiền tệ:** Hỗ trợ VNĐ, USD và tự động cập nhật tỷ giá.

## 🛠 Công nghệ sử dụng

Ứng dụng được phát triển với các công nghệ và mô hình hiện đại nhất:

- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **State Management:** BLoC / Riverpod (Tùy chọn theo dự án)
- **Architecture:** Clean Architecture (Data, Domain, Presentation)
- **Dependency Injection:** GetIt & Injectable
- **Local Database:** Hive / Isar (Đảm bảo tốc độ truy xuất nhanh)
- **UI Components:** - `fl_chart` cho biểu đồ.
  - `google_fonts` cho typography chuyên nghiệp.
  - `intl` cho định dạng tiền tệ.

## 🏗 Cấu trúc thư mục

Dự án tuân thủ cấu trúc **Clean Architecture** để dễ dàng mở rộng và bảo trì:

```text
lib/
├── core/             # Cấu hình chung, theme, constants, utils
├── data/             # Triển khai Repository, Data Sources, Models
├── domain/           # Business Logic: Entities, Repository Interfaces, Use cases
├── presentation/     # UI: Screens, Widgets, State Management (Controllers/Blocs)
└── main.dart         # Điểm khởi đầu của ứng dụng
```

Cài đặt và Chạy thử
Để chạy dự án này ở môi trường local, bạn cần cài đặt Flutter SDK.
1. Clone dự án
git clone [https://github.com/your-username/personal_finance_tracker.git](https://github.com/your-username/personal_finance_tracker.git)
2. Cài đặt các packages:
flutter pub get
3. Chạy code generation (nếu có sử dụng build_runner):
flutter pub run build_runner build --delete-conflicting-outputs
4. Chạy ứng dụng:
flutter run
### 📸 Screenshots

<p align="center">
  <img src="https://github.com/user-attachments/assets/10e651c1-bd78-4f7c-a423-37d2c3ef454b" width="240" />
  <img src="https://github.com/user-attachments/assets/ea57101a-f2ae-42c8-8a2e-e9e3587245a4" width="240" />
  <img src="https://github.com/user-attachments/assets/a26745f2-a3e9-48cb-be7c-54d14752b0c8" width="240" />
</p>
> *Hình ảnh minh họa các tính năng chính của Lumi Finance trên nền tảng Mobile.*
👤 Tác giả
Văn Bá Phát Huy - Email: [phathuy2004h@gmail.com]
Role: Mobile Developer
