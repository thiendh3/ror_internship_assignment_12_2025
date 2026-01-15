Các đầu mục công việc (tóm tắt) và estimate

1. DB + Models (Hashtag, join table, privacy, notifications)

- Việc: tạo migrations cho hashtags + micropost_hashtags, thêm cột privacy vào microposts, (nếu cần) tạo bảng notifications.
- Thêm/sửa: app/models/hashtag.rb, micropost.rb (association + privacy enum), micropost_hashtag.rb, notification.rb
- Xoá: không cần xoá lớn
- Thời gian: 4 giờ

2. Hashtag extraction & basic service

- Việc: service nhỏ để parse content -> list hashtag, tạo/associate hashtag khi create/update micropost
- Thêm: app/services/hashtag_extractor.rb, gọi từ callbacks hoặc controller
- Thời gian: 3 giờ

3. Solr integration (core + schema + indexer + reindex task)

- Việc: cấu hình core/schema (fields: content, user_id, created_at, hashtags, privacy), viết service/index job để index/update/delete documents, rake task reindex
- Thêm/sửa: SOLR_SETUP.md, app/services/solr_indexer.rb, app/jobs/solr_index_job.rb, lib/tasks/solr.rake
- Thời gian: 8 giờ

4. Search endpoints + Autocomplete + Filters + Highlight

- Việc: backend search endpoint querying Solr (q, date range, author, hashtag, privacy), autocomplete endpoint (suggester), trả về results + highlight
- Thêm/sửa: routes + controller action (e.g., microposts#search, #autocomplete)
- Thời gian: 8 giờ

5. AJAX API cho Microposts (create/update/destroy/show) & inline edit

- Việc: make create/update/destroy respond JSON, show for modal; parse mentions on create/update
- Thêm/sửa: app/controllers/microposts_controller.rb (AJAX responses), client-side fetch/XHR handlers
- Thời gian: 8 giờ

6. Likes & Comments (AJAX) và NotificationService hooks

- Việc: ensure like/comment endpoints are AJAX; tạo NotificationService với methods create_like_notification, create_comment_notification, create_mention_notification; trigger notifications
- Thêm/sửa: likes_controller, comments_controller, app/services/notification_service.rb
- Thời gian: 6 giờ

7. Realtime (ActionCable) — notifications + feed updates

- Việc: channels (notifications_channel, microposts_channel), broadcast jobs when new micropost/like/comment/mention created, frontend consumer to show live notifications and feed inserts
- Thêm/sửa: app/channels/_, app/jobs/_, frontend channel JS
- Thời gian: 8 giờ

8. Frontend UI/UX (micropost card, inline edit, modal, search UI, responsive CSS)

- Việc: design & implement micropost card partial, inline edit UI, modal view, search bar + results UI, hashtag links, visual feedback
- Thêm/sửa: app/views/microposts/\_micropost.\*, app/views/microposts/index/show, assets/js (Stimulus controllers or plain JS), SCSS
- Thời gian: 16 giờ

9. Privacy & Authorization

- Việc: enforce privacy rules (public / followers_only / private) in controllers/policies and on search results
- Thêm/sửa: policies (Pundit) or controller before_actions; ensure Solr queries respect privacy (or post-filter)
- Thời gian: 4 giờ

10. Tests & QA (basic unit + controller + a couple system tests)

- Việc: unit tests for extractor, indexer, NotificationService; controller tests for AJAX endpoints; 1-2 system tests for inline edit and realtime notification
- Thời gian: 10 giờ

Flow (rất ngắn, textual)

- Create micropost (AJAX) → save & extract hashtags → enqueue Solr index → create mention notifications → broadcast new-post to followers (ActionCable) → frontend inserts card.
- Search input (debounced) → autocomplete endpoint (Solr suggester) → submit search → Solr query with filters & highlight → render results.
