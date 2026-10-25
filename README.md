# 🛍️ Menly — Ứng dụng Mua sắm Thời trang Nam

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter" />
  <img src="https://img.shields.io/badge/Node.js-Express-green?logo=nodedotjs" />
  <img src="https://img.shields.io/badge/Next.js-Admin-black?logo=nextdotjs" />
  <img src="https://img.shields.io/badge/Supabase-Database-brightgreen?logo=supabase" />
</p>

> **Đồ án tốt nghiệp** — Ứng dụng thương mại điện tử thời trang nam trên nền tảng di động (iOS/Android) với giao diện premium dark theme.

---

## 📁 Cấu trúc dự án

```
DATN_Mua-sam-thoi-trang-nam-Menly/
├── frontend/        # Flutter app (iOS & Android)
├── backend/         # Node.js + Express REST API
└── admin/           # Next.js Admin Dashboard
```

---

## ✨ Tính năng chính

### 📱 Mobile App (Flutter)

- **Trang chủ & Khám phá:** Banner khuyến mãi, Flash Sale, danh mục và gợi ý sản phẩm thịnh hành.
- **Tìm kiếm & Phân loại:** Tìm kiếm sản phẩm theo từ khóa, lọc theo danh mục, chuyển đổi chế độ xem Grid/List linh hoạt.
- **Chi tiết sản phẩm & Tư vấn size:** Chọn biến thể size/màu, bảng hướng dẫn chọn size chuẩn (Size Advisor) và Lookbook gợi ý phối đồ thông minh.
- **Tư vấn AI & CSKH:** Tích hợp trợ lý ảo AI tư vấn phối đồ, phong cách thời trang và hỗ trợ chat trực tiếp với nhân viên hỗ trợ (Live Chat).
- **Hệ thống thông báo:** Cập nhật thông báo trạng thái đơn hàng, ưu đãi và tin tức theo thời gian thực.
- **Giỏ hàng & Đặt hàng:** Quản lý giỏ hàng trực quan, hỗ trợ thanh toán khi nhận hàng (COD) và cổng thanh toán trực tuyến (VNPay).
- **Tài khoản cá nhân:** Đăng ký/Đăng nhập bảo mật JWT, theo dõi tiến trình đơn hàng (Timeline tracking), quản lý sổ địa chỉ giao hàng.
- **Giao diện & Trải nghiệm:** Thiết kế Dark theme hiện đại, tối ưu giao diện responsive mượt mà trên mọi kích thước màn hình thiết bị.

### ⚙️ Backend (Node.js & Express)

- **Kiến trúc Clean Architecture:** RESTful API hoàn chỉnh cho sản phẩm, đơn hàng, người dùng, đánh giá và thông báo.
- **Tích hợp Gemini AI:** API xử lý chatbot tư vấn thời trang thông minh.
- **Bảo mật & Hiệu năng:** Xác thực JWT (Access/Refresh Token), phân quyền Admin/Customer, Rate Limiting chống spam và tấn công API.
- **Quản lý dữ liệu:** Lưu trữ và quản lý tồn kho theo biến thể đa chiều (size, màu) trên Supabase.

### 🖥️ Admin Dashboard (Next.js)

- **Quản lý sản phẩm & Kho hàng:** Phân loại sản phẩm theo nhóm biến thể, tạo mới, chỉnh sửa và xóa an toàn.
- **Quản trị đơn hàng & Người dùng:** Theo dõi và cập nhật trạng thái đơn hàng, quản lý danh sách tài khoản khách hàng.
- **Báo cáo & Thống kê:** Biểu đồ trực quan về doanh thu và top các sản phẩm bán chạy nhất.

---

## 🚀 Hướng dẫn cài đặt & chạy

### Yêu cầu

| Công cụ  | Phiên bản |
| -------- | --------- |
| Flutter  | 3.x       |
| Node.js  | 18+       |
| Supabase |           |
| npm      | 9+        |

---

### 1️⃣ Clone dự án

```bash
git clone https://github.com/ThanhToan05022/DATN_Mua-sam-thoi-trang-nam-Menly.git
cd DATN_Mua-sam-thoi-trang-nam-Menly
```

---

### 2️⃣ Cài đặt Backend

```bash
cd backend
cp .env.example .env     # Sao chép file cấu hình
```

Mở file `.env` và điền thông tin:

```bash
npm install
npm run dev       # Backend chạy tại http://localhost:5000
```

---

### 3️⃣ Cài đặt Admin Dashboard

```bash
cd admin
npm install
npm run dev       # Admin chạy tại http://localhost:3000
```

---

### 4️⃣ Cài đặt Flutter App

```bash
cd frontend
flutter pub get
```

#### ⚠️ QUAN TRỌNG — Cấu hình IP Backend

iOS Simulator **không dùng được `localhost`** — phải dùng IP LAN của máy chạy backend.

**Bước 1:** Tìm IP máy của bạn:

```bash
# macOS / Linux
ifconfig | grep "inet " | grep -v 127.0.0.1

# Windows (CMD)
ipconfig
# → tìm dòng "IPv4 Address"
```

**Bước 2:** Mở file `frontend/lib/core/config/api_config.dart` và đổi IP:

```dart
/// ✏️ THAY GIÁ TRỊ NÀY = IP máy đang chạy backend của bạn
static const String _localIp = '192.168.x.x';   // ← đổi thành IP của bạn
```

**Bước 3:** Chạy app:

```bash
# Xem danh sách thiết bị/simulator
flutter devices

# Chạy trên simulator/emulator
flutter run -d <device-id>

# Hoặc chạy trên thiết bị thật (đảm bảo cùng mạng WiFi với backend)
flutter run
```

---

## 📱 Các nhánh Git

| Nhánh                          | Mô tả                             |
| ------------------------------ | --------------------------------- |
| `main`                         | Nhánh chính, ổn định              |
| `feat/mobile-ui-redesign`      | ✨ UI/UX mới — premium dark theme |
| `feat/profile-upload-password` | Tính năng đổi avatar & mật khẩu   |

---

## 🔧 Troubleshooting

### App không kết nối được backend

- ✅ Đảm bảo backend đang chạy (`npm run dev`)
- ✅ Đổi đúng IP trong `api_config.dart`
- ✅ Máy điện thoại/simulator và máy chạy backend **phải cùng mạng WiFi**
- ✅ Tắt VPN nếu đang bật

### iOS Simulator lỗi "Connection refused"

```bash
# Tìm IP đúng
ifconfig en0 | grep "inet "
# → Dùng địa chỉ "inet xxx.xxx.xxx.xxx" đó trong api_config.dart
```

### Android Emulator

Android Emulator dùng `10.0.2.2` thay cho `localhost` — **đã được cấu hình sẵn**, không cần đổi.

### flutter pub get lỗi

```bash
flutter clean
flutter pub get
```

---

## 👥 Nhóm thực hiện

> Đồ án tốt nghiệp — Khoa Công nghệ Thông tin

---

## 📄 License

MIT License — Chỉ dùng cho mục đích học tập.
