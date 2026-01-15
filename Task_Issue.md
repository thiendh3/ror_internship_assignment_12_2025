# Backgrounds

- Giao diện micropost hiện tại trông khá sơ sài và quê mùa, cần cải thiện trông thích mắt hơn và bổ sung các section như like/dislike/comments/share với tương tác responsive (không cần load lại trang)
- Khi có quá nhiều microposts việc tìm kiếm thủ công là quá bất tiện, cần có công cụ tìm kiếm nhanh gọn tiện lợi hơn
- User khi follow người khác, điều quan tâm nhất chính là các bài post của người đó nên cần công cụ thông báo real time
- Người dùng cũng muốn edit bài post inline, nghĩa là edit trực tiếp trên bài post để dễ quan sát những thay đổi mà không cần phải vào form edit rồi submit
- Thêm các chế độ privacy cho bài post

# Details

## 1. Solr Integration cho Microposts

- **Setup Solr**: Tạo core và cấu hình Solr schema cho `Micropost` model ([Docs](https://github.com/thiendh3/ror_internship_assignment_12_2025/blob/7e095a676c172e10ede5d2b54bf8ab8cfaa45416/SOLR_SETUP.md))
- **Search Implementation**:
  - Index micropost: content, created_at, user_id, hashtags
  - Full-text search cho microposts
  - Filter theo: date range, user (author), hashtags
  - Highlight search keywords trong results
  - Autocomplete suggestions khi search microposts
- **Hashtag System**:
  - Tạo `Hashtag` model
  - Extract hashtags từ micropost content
  - Association với microposts
  - Search microposts theo hashtag
- **Auto-indexing**:
  - Auto-index microposts to Solr khi có thay đổi (after_save callbacks)
  - Extract hashtags khi tạo/update micropost

## 2. Live Notifications cho Microposts

- **Backend**:
  - Tạo notifications khi:
    - Có người like micropost
    - Có người comment micropost
    - Có người mention trong micropost (@username)
  - `NotificationService` methods:
    - `create_like_notification(liker, micropost)`
    - `create_comment_notification(commenter, micropost)`
    - `create_mention_notification(mentioner, mentioned_user, micropost)`
- **Frontend**:
  - Real-time notification khi có like/comment/mention trên micropost
  - Notification hiển thị micropost preview
  - Click notification navigate đến micropost

## 3. AJAX Actions cho Microposts

- **Backend** (Controllers):
  - `MicropostsController`:
    - `create` - Tạo micropost (AJAX, trả về JSON)
    - `destroy` - Xóa micropost (AJAX)
    - `update` - Edit micropost (AJAX, inline editing)
    - `show` - Show micropost (AJAX modal)
- **Frontend**:
  - Create micropost form với AJAX submit
  - Delete micropost với AJAX (confirmation dialog)
  - Edit micropost inline với AJAX
  - View micropost trong modal (AJAX)
  - Real-time update khi có micropost mới (WebSocket)
  - Visual feedback cho mọi actions

## 4. Micropost Features

- Design dev tự thiết kế miễn sao dễ nhìn, thân thiện, hiện đại, responsive là được
- **Micropost Display**:
  - List microposts với pagination (AJAX pagination)
  - Micropost card với like count, comment count
  - Time ago display
  - User info (avatar, name)
- **Micropost Interactions**:
  - Like/Unlike micropost (AJAX)
  - View likes list (AJAX modal)
  - Share micropost (copy link)
- **Search UI**:
  - Search bar để search microposts
  - Search results page với filters
  - Hashtag links (click hashtag → search)

# Devices

- PC
