# Lộ trình 2 tuần của Cảnh

## Mục tiêu

Hoàn thiện phần quản trị web và chuẩn bị báo cáo/demo theo bảng phân công. Kế hoạch dùng 10 ngày làm việc, khoảng 8–9 giờ/ngày (xấp xỉ 85 giờ). Bảng gốc ước lượng từng việc trong khoảng 72–100 giờ, nên cần chốt phạm vi với nhóm nếu phát sinh thêm.

## Đã kiểm tra trên nhánh `feature/canh`

- Đã có màn hình sản phẩm, đơn hàng, kho, mã giảm giá, người dùng, đánh giá và tổng quan.
- Nhánh đã có luồng thêm/sửa/xóa mềm sản phẩm; backend có API quản trị sản phẩm, điều chỉnh và lịch sử kho, danh sách/cập nhật trạng thái đơn, đổi vai trò người dùng, xem/xóa đánh giá.
- Chưa thấy màn hình quản trị banner, trả hàng và gửi thông báo trong `admin/src/app`; các mục này cần xác định API/schema với nhóm trước khi làm.
- Các màn hình đã có vẫn cần rà lại dữ liệu thật, phân quyền, trạng thái lỗi/rỗng/loading và kiểm thử end-to-end; sự tồn tại của trang chưa đồng nghĩa nghiệp vụ đã hoàn chỉnh.
- `feature/canh` và `main` hiện lệch nhau 6 commit mỗi phía. Ngày đầu cần thống nhất cách đồng bộ với nhóm; không tự gộp hoặc ghi đè phần của thành viên khác.

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
