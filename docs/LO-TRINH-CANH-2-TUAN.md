# Lộ trình 2 tuần của Cảnh

## Mục tiêu

Hoàn thiện phần quản trị web và chuẩn bị báo cáo/demo theo bảng phân công. Kế hoạch dùng 10 ngày làm việc, khoảng 8–9 giờ/ngày (xấp xỉ 85 giờ). Bảng gốc ước lượng từng việc trong khoảng 72–100 giờ, nên cần chốt phạm vi với nhóm nếu phát sinh thêm.

## Đã kiểm tra trên nhánh `feature/canh`

- Đã có màn hình sản phẩm, đơn hàng, kho, mã giảm giá, người dùng, đánh giá và tổng quan.
- Nhánh đã có luồng thêm/sửa/xóa mềm sản phẩm; backend có API quản trị sản phẩm, điều chỉnh và lịch sử kho, danh sách/cập nhật trạng thái đơn, đổi vai trò người dùng, xem/xóa đánh giá.
- Chưa thấy màn hình quản trị banner, trả hàng và gửi thông báo trong `admin/src/app`; các mục này cần xác định API/schema với nhóm trước khi làm.
- Các màn hình đã có vẫn cần rà lại dữ liệu thật, phân quyền, trạng thái lỗi/rỗng/loading và kiểm thử end-to-end; sự tồn tại của trang chưa đồng nghĩa nghiệp vụ đã hoàn chỉnh.
- `feature/canh` và `main` hiện lệch nhau 6 commit mỗi phía. Ngày đầu cần thống nhất cách đồng bộ với nhóm; không tự gộp hoặc ghi đè phần của thành viên khác.

## Kết quả ngày 1 và ngày 2

### Ngày 1 — baseline và hợp đồng API

Đã cài dependency bằng `npm install` trong `admin` và `backend`; không thay đổi file lock. Đã kiểm tra API hiện có trên nhánh:

| Nghiệp vụ | API hiện có | Ghi chú |
|---|---|---|
| Sản phẩm | `/api/v1/admin/products` — xem danh sách/chi tiết, tạo, sửa, ẩn | Có validation backend và xóa mềm. |
| Đơn hàng | `/api/v1/admin/orders` — xem danh sách, cập nhật trạng thái | Có lọc theo truy vấn; cần rà UI với dữ liệu thật vào ngày 3. |
| Kho | `/api/v1/admin/inventory/adjust`, `/api/v1/admin/inventory/movements` | Có điều chỉnh số lượng và lịch sử. |
| Mã giảm giá | `/api/v1/admin/vouchers` — xem, tạo, sửa, xóa | API admin đã có; cần đối chiếu form và điều kiện áp dụng ngày 5. |
| Người dùng | `/api/v1/admin/users` và `/api/v1/admin/users/:id/role` | Danh sách/chi tiết và gán vai trò dành cho admin; staff bị từ chối. |
| Đánh giá | `/api/v1/admin/reviews` — xem và xóa | Chưa thấy API trả lời đánh giá. |
| Banner, gửi thông báo, duyệt trả hàng | Chưa thấy API quản trị tương ứng trên nhánh | Cần thống nhất contract với nhóm trước khi làm các mục ngày 7/9. |

Kết quả baseline:

- Backend: tại baseline ban đầu, `npm run build` đạt và `npm test` đạt 51/52; đã sửa lỗi phân quyền khiến staff xem được danh sách người dùng, đồng thời thêm kiểm tra staff không xem được chi tiết. Hiện `npm test` đạt 52/52 và `npm run build` đạt.
- Admin: tại baseline ban đầu, `npm run build` đạt; lint báo 2 lỗi gọi thời gian trong lúc render ở Cài đặt/Mã giảm giá. Đã chuyển thời điểm khởi tạo thời gian hoạt động sang effect/event handler; hiện `npm run lint` không còn lỗi (còn cảnh báo lint ở các file khác) và `npm run build` đạt.
- Flutter chưa cài trong môi trường (`flutter` không nhận diện được lệnh), nên chưa thể chạy `flutter pub get` hoặc `flutter run`.
- Không gộp `main` vào nhánh vì hai nhánh đã phân kỳ; cần xác nhận với nhóm trước khi đồng bộ.

### Ngày 2 — quản lý sản phẩm

- Dùng chung validation phía giao diện cho tên, giá và URL ảnh ở form thêm/sửa; kiểm tra size, màu, SKU, tồn kho và cặp size–màu trùng ở form tạo.
- Lỗi thao tác sản phẩm được hiển thị bằng trạng thái cảnh báo riêng thay vì trình bày giống thông báo thành công.
- Ổn định callback phân loại để các bộ lọc/sắp xếp phụ thuộc đúng dữ liệu; bỏ thao tác sửa trực tiếp đối tượng biến thể khi điều chỉnh tồn kho.
- Đã chạy 8 kiểm tra validation, ESLint tập trung và build production admin; đều đạt.

## Sửa lỗi sau ngày 2

- `admin/src/app/settings/page.tsx`: khởi tạo mốc uptime trong effect thay vì gọi `Date.now()` trong render.
- `admin/src/app/vouchers/page.tsx`: tạo ngày mặc định khi mở form và định dạng theo ngày địa phương, tránh gọi thời gian trong render và tránh lệch ngày do UTC.
- `backend/src/views/routes/user.routes.ts` và `backend/src/views/app.ts`: giới hạn xem danh sách/chi tiết tài khoản cho admin, nhất quán với quyền quản trị người dùng; staff vẫn được vận hành đơn hàng/sản phẩm nhưng không truy cập khu vực người dùng.
- `backend/tests/integration/api.test.ts`: bổ sung kiểm tra staff bị từ chối khi xem chi tiết người dùng.
- Xác minh lại: `npm run lint` admin không còn lỗi (còn cảnh báo), `npm run build` admin đạt, `npm test` backend đạt 52/52, `npm run build` backend đạt.

## Kế hoạch 10 ngày

| Ngày | Giờ | Trọng tâm và đầu ra |
|---|---:|---|
| 1 | 8 | Đối chiếu nhánh với nhóm; chạy baseline admin/backend; lập ma trận màn hình–API–quyền; chốt contract cho banner, trả hàng, thông báo và người dùng. |
| 2 | 8 | Rà soát quản lý sản phẩm: thêm/sửa/xóa mềm, validation, biến thể/tồn kho, làm mới danh sách và thông báo lỗi. Hoàn tất smoke test CRUD. |
| 3 | 9 | Hoàn thiện quản lý đơn: lọc/tìm kiếm, xem chi tiết, cập nhật trạng thái, xử lý lỗi và kiểm tra quyền. |
| 4 | 8 | Hoàn thiện kho: danh sách tồn, nhập/điều chỉnh số lượng, lịch sử biến động, kiểm tra dữ liệu sau thao tác. |
| 5 | 8 | Hoàn thiện mã giảm giá: danh sách, tạo/sửa, điều kiện áp dụng, thời hạn, trạng thái và validation dữ liệu. |
| 6 | 9 | Hoàn thiện người dùng: danh sách/tìm kiếm, chỉnh sửa thông tin, khóa/mở khóa và phân quyền; kiểm tra API bảo vệ thao tác quản trị. |
| 7 | 8 | Hoàn thiện kiểm duyệt đánh giá; xây dựng trang quản lý banner theo contract đã chốt, gồm trạng thái hiển thị và kiểm tra ảnh/liên kết. |
| 8 | 10 | Rà soát dashboard: số đơn, doanh thu, sản phẩm bán chạy, bộ lọc thời gian; ưu tiên số liệu lấy từ API thay vì dữ liệu mẫu. |
| 9 | 8 | Hoàn thiện gửi thông báo và duyệt yêu cầu trả hàng; kiểm tra phân quyền, trạng thái trước/sau thao tác và phản hồi cho người dùng. |
| 10 | 9 | Kiểm thử hồi quy toàn bộ luồng; sửa lỗi tích hợp; hoàn thiện báo cáo, slide, kịch bản demo và checklist bàn giao. Chốt việc đồng bộ nhánh với nhóm. |

## Nhịp commit đề xuất

Mục tiêu khoảng 20 commit có ý nghĩa (xấp xỉ 2 commit/ngày), không tạo commit rỗng hoặc chia nhỏ chỉ để tăng số lượng. Mỗi commit nên build được, có nội dung tập trung và được kiểm tra phù hợp trước khi ghi nhận.

1. `docs: ghi lộ trình và trạng thái phần quản trị của Cảnh`
2. `test(admin): bổ sung kiểm tra baseline và luồng API quản trị`
3. `fix(admin): hoàn thiện validation form sản phẩm`
4. `fix(admin): đồng bộ trạng thái sau CRUD sản phẩm`
5. `feat(admin): bổ sung lọc và xem chi tiết đơn hàng`
6. `feat(admin): hoàn thiện cập nhật trạng thái đơn`
7. `feat(admin): hoàn thiện điều chỉnh tồn kho`
8. `feat(admin): hiển thị lịch sử biến động kho`
9. `feat(admin): bổ sung tạo và chỉnh sửa mã giảm giá`
10. `fix(admin): kiểm tra điều kiện và thời hạn mã giảm giá`
11. `feat(admin): bổ sung chỉnh sửa thông tin người dùng`
12. `feat(admin): bổ sung khóa tài khoản và phân quyền`
13. `feat(admin): hoàn thiện kiểm duyệt đánh giá`
14. `feat(admin): bổ sung quản lý banner`
15. `feat(backend): cung cấp dữ liệu tổng hợp cho dashboard`
16. `feat(admin): hoàn thiện biểu đồ và bộ lọc dashboard`
17. `feat(admin): bổ sung gửi thông báo người dùng`
18. `feat(admin): bổ sung duyệt yêu cầu trả hàng`
19. `docs: hoàn thiện báo cáo và kịch bản demo`
20. `test: kiểm thử hồi quy các luồng quản trị`

Danh sách trên là mốc tham khảo, không phải yêu cầu phải tạo đủ 20 commit. Có thể tách thêm khi mỗi thay đổi là một phần độc lập, review được; nếu một commit chưa hoàn chỉnh thì gộp lại thay vì ghi lịch sử gây nhiễu.

## Cổng kiểm tra

- Hàng ngày: chạy `npm run lint` và `npm run build` trong `admin`; chạy `npm run build` và `npm test` trong `backend` khi có thay đổi backend.
- Sau mỗi nghiệp vụ: kiểm tra loading/rỗng/lỗi, quyền staff/admin, dữ liệu thật và trạng thái sau khi tạo/sửa/xóa.
- Trước demo: chạy lại các luồng sản phẩm, đơn, kho, mã giảm giá, người dùng, đánh giá, banner, dashboard, thông báo và trả hàng với dữ liệu thử; ghi rõ mục nào chưa thể kiểm tra do thiếu cấu hình hoặc API.
- Đồng bộ `main` chỉ sau khi thống nhất với nhóm vì hai nhánh đã phân kỳ; không commit secrets hoặc file môi trường.
