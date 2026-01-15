# ROR Internship Assignment

## Tổng quan
Ứng dụng mạng xã hội mini xây dựng bằng Ruby on Rails, tập trung vào microposts, tương tác người dùng và realtime features. Dùng Docker để đồng bộ môi trường phát triển và hỗ trợ Solr cho tìm kiếm.

## Tính năng chính
- Microposts: tạo/sửa/xóa bằng AJAX, preview image trước khi upload, hiển thị theo card UI hiện đại
- Realtime feed: cập nhật micropost mới qua ActionCable
- Reactions (Like/Love/Haha): AJAX + danh sách người react (modal)
- Comments: AJAX, UI bubble, realtime notifications
- Mentions: @username -> link + notification
- Share: copy link micropost
- Privacy: Public / Friends / Only Me
- Hashtags: tự động extract, link & search
- Search: Solr full-text + fuzzy search + filters + highlight + autocomplete
- Notifications: realtime cho like/comment/mention

## Yêu cầu hệ thống
- Docker + Docker Compose
- Ruby 3.0.6 (đã cấu hình trong container)
- MySQL + Solr (chạy qua Docker Compose)

## Cài đặt & chạy dự án
1. Build image
   - docker compose build
2. Chạy services
   - docker compose up
3. Tạo database và migrate (nếu cần)
   - docker compose exec web bin/rails db:create db:migrate

## Solr
- Core và schema đã cấu hình cho micropost search
- Index tự động qua callbacks

## Quy tắc làm việc
- Tạo branch theo format:
  - feature/<so_issue>_<mo_ta>
- Luồng làm việc: Detail Design -> Review -> Coding -> PR -> Review chéo -> Mentor review

## Ghi chú
- Ưu tiên phát triển trên Docker để đảm bảo môi trường thống nhất
