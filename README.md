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
  <img src="https://github.com/user-attachments/assets/1bc13726-b3a2-4ba2-bb4f-537913414a1a" width="240" />
  <img src="https://github.com/user-attachments/assets/ccc409db-537b-4fae-9c4e-8af7dad6eec0" width="240" />
  <img src="https://github.com/user-attachments/assets/99d724f7-64d3-40f0-990d-a02b7126808a" width="240" />
  <img src="https://github.com/user-attachments/assets/b15861a7-9665-41fa-b81c-86318e8aa313" width="240" />
  <img src="https://github.com/user-attachments/assets/df55dd5b-777c-4e0e-9e97-16843009d86e" width="240" />
  <img src="https://github.com/user-attachments/assets/1ec1614d-6856-40b1-bdc9-0117771ca606" width="240" />
  <img src="https://github.com/user-attachments/assets/17ae945a-5db3-4f70-aa94-949ca3fe1252" width="240" />
  <img src="https://github.com/user-attachments/assets/1fae0c4e-840a-482f-888a-8ad20ac4f430" width="240" />
  <img src="https://github.com/user-attachments/assets/bc920419-db24-413e-89d0-352cdea146a2" width="240" />
  <img src="https://github.com/user-attachments/assets/fc75110d-b7b1-4cad-8bf4-d9c6dfc37fad" width="240" />
</p>
> *Hình ảnh minh họa các tính năng chính của Lumi Finance trên nền tảng Mobile.*

👤 Tác giả
Văn Bá Phát Huy - Email: [phathuy2004h@gmail.com]
Role: Mobile Developer
