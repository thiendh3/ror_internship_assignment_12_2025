# ASSIGNMENTS
- Source code được built dùng để training interns ROR
- Bao gồm source code base và 4 bài tập khác nhau
- Interns bắt buộc sử dụng docker để chạy web
## Quy tắc đặt tên branch
- Mỗi intern sẽ được assign 1 issue khác nhau
- Checkout từ main đặt tên theo cú pháp:
```
 feature/<số_issue>_<miêu tả feature>
```
- Ví dụ: Issue 1: tạo page user profile -> `feature/1_user_profile_page`

## Workflow
- Intern nhận issue, đọc hiểu phân tích spec và QA xác nhận (nếu có)
- Viết Detail Design (DD) chi tiết bao gồm ý tưởng, những việc sẽ làm (thêm/xoá/sửa code ở đâu), Flow chart (optional) và estimate time cho từng đầu mục. Ví dụ:
  - Tạo db mới: 4h
  - Tạo UI/UX page: 8h
  - ...
  - Total: X
- Gửi DD cho mentor review, bổ sung chỉnh sửa nếu cần
- Sau khi mentor đồng ý với DD thì intern bắt đầu coding
- Kết thúc coding gửi PR cho các intern khác review chéo lẫn nhau
- Intern review chéo xong thì gửi cho các mentors
- Mentors review xong approve PR, intern tiến hành deploy để testing/fix bugs nếu có
