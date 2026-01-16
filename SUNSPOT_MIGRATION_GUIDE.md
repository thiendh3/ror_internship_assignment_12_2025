# Hướng dẫn chuyển đổi từ Searchkick sang Sunspot

## Tổng quan

Searchkick không hỗ trợ Solr, chỉ hỗ trợ Elasticsearch và OpenSearch. Vì project đang sử dụng Solr, cần chuyển đổi sang **Sunspot** - gem chính thức để tích hợp Solr với Rails.

## Lý do chuyển đổi

- **Searchkick**: Chỉ hỗ trợ Elasticsearch và OpenSearch
- **Sunspot**: Hỗ trợ Solr (phù hợp với project hiện tại)
- **rsolr**: Đã có sẵn trong Gemfile, Sunspot sử dụng rsolr

---

## ⚠️ QUAN TRỌNG: Quy trình Migration với Docker

**Lưu ý:** Project này chạy bằng Docker. Bạn cần thực hiện theo đúng thứ tự sau:

1. **Dừng và xóa Docker containers/images cũ** (trước khi sửa code)
2. **Sửa code** (các file cần thiết)
3. **Build và chạy Docker mới** (sau khi sửa code xong)

---

## Bước 1: Dừng và xóa Docker cũ (TRƯỚC KHI SỬA CODE)

### 1.1. Dừng tất cả containers đang chạy

```bash
# Dừng tất cả containers
docker-compose down

# Kiểm tra không còn containers nào đang chạy
docker-compose ps
```

### 1.2. Xóa containers, networks và volumes (nếu cần)

```bash
# Xóa containers, networks (giữ lại volumes - data)
docker-compose down

# Xóa tất cả bao gồm volumes (CẨN THẬN: sẽ mất data trong volumes)
docker-compose down -v

# Hoặc xóa từng service cụ thể
docker-compose rm -f web db solr
```

### 1.3. Xóa images cũ (optional - nếu muốn build lại từ đầu)

```bash
# Xem images hiện có
docker images

# Xóa image của project (thay tên image nếu khác)
docker rmi ror_internship_assignment_12_2025-web

# Hoặc xóa tất cả images không dùng
docker image prune -a
```

### 1.4. Kiểm tra không còn containers/images liên quan

```bash
# Kiểm tra containers
docker ps -a | grep rails

# Kiểm tra images
docker images | grep rails

# Kiểm tra volumes
docker volume ls | grep rails
```

**Sau khi hoàn thành bước 1, bạn đã dọn dẹp Docker cũ. Tiếp tục với Bước 2: Sửa code.**

---

## Bước 2: Sửa code (CẬP NHẬT CÁC FILE CẦN THIẾT)

**Lưu ý:** Chỉ sửa code khi Docker đã được dừng. Không chạy Docker trong lúc này.

## Các file cần sửa

### 1. **Gemfile**

**Thay đổi:**
```ruby
# Xóa dòng này:
gem 'searchkick'

# Giữ lại (Sunspot sử dụng rsolr):
gem 'rsolr'

# Thêm dòng này:
gem 'sunspot_rails'
```

**Sau khi sửa:**
```ruby
gem 'mini_magick'
gem 'sunspot_rails'  # Thay thế searchkick
gem 'rsolr'
```

**Lưu ý:** Lệnh `bundle install` sẽ được chạy trong Docker ở Bước 3, không cần chạy bây giờ.

---

### 2. **Xóa file: `config/initializers/searchkick.rb`**

File này không cần nữa với Sunspot. Sunspot sẽ tự động cấu hình từ `config/sunspot.yml`.

**Lệnh:**
```bash
rm config/initializers/searchkick.rb
```

---

### 3. **Xóa file: `lib/tasks/searchkick.rake`**

Sunspot có sẵn các rake tasks, không cần file custom này.

**Lệnh:**
```bash
rm lib/tasks/searchkick.rake
```

**Sunspot rake tasks có sẵn:**
- `rake sunspot:reindex` - Reindex tất cả models
- `rake sunspot:reindex[ModelName]` - Reindex một model cụ thể
- `rake sunspot:solr:start` - Start Solr server (nếu dùng embedded)
- `rake sunspot:solr:stop` - Stop Solr server
- `rake sunspot:solr:reindex` - Reindex với Solr

---

### 4. **Tạo file: `config/sunspot.yml`**

Tạo file cấu hình mới cho Sunspot:

```yaml
development:
  solr:
    hostname: <%= ENV.fetch("SOLR_HOST", "solr") %>
    port: <%= ENV.fetch("SOLR_PORT", 8983) %>
    path: /solr/solr_development
    log_level: INFO
    read_timeout: 2
    open_timeout: 1

test:
  solr:
    hostname: <%= ENV.fetch("SOLR_HOST", "localhost") %>
    port: <%= ENV.fetch("SOLR_PORT", 8982) %>
    path: /solr/solr_test
    log_level: WARNING
    read_timeout: 2
    open_timeout: 1

production:
  solr:
    hostname: <%= ENV.fetch("SOLR_HOST", "localhost") %>
    port: <%= ENV.fetch("SOLR_PORT", 8983) %>
    path: <%= ENV.fetch("SOLR_PATH", "/solr/production") %>
    log_level: WARNING
    read_timeout: 5
    open_timeout: 2
```

**Lưu ý:**
- Development: Sử dụng `solr` (Docker service name), path phải là `/solr/solr_development` (bao gồm core name)
- Production: Sử dụng biến môi trường `SOLR_HOST`, `SOLR_PORT`, và `SOLR_PATH`
- Test: Sử dụng localhost mặc định, path là `/solr/solr_test`
- Path phải bao gồm core name: `/solr/{core_name}` (ví dụ: `/solr/solr_development`)

---

### 5. **Cập nhật: `app/models/user.rb`**

**Thêm `searchable` block vào User model:**

```ruby
class User < ApplicationRecord
  # ... existing code ...

  # Sunspot searchable configuration
  searchable do
    text :name, :email
    
    boolean :activated
    time :created_at
    integer :id
    
    # Index followers and following count 
    integer :followers_count, stored: true do
      followers.count
    end
    
    integer :following_count, stored: true do
      following.count
    end
  end

  # Auto-reindex when user is created or updated
  after_commit :reindex, on: [:create, :update]
  
  # Reindex when user is destroyed
  after_commit :remove_from_index, on: :destroy

  private
  
  def reindex
    Sunspot.index(self)
  end
  
  def remove_from_index
    Sunspot.remove(self)
  end
end
```

**Giải thích:**
- `text :name, :email` - Full-text search trên name và email
- `boolean :activated` - Filter theo activated status
- `time :created_at` - Sort theo thời gian tạo
- `integer :id` - ID để reference
- `after_commit` callbacks - Tự động reindex khi có thay đổi

---

### 6. **Cập nhật: `app/models/micropost.rb` (nếu cần search microposts)**

Nếu cần search microposts, thêm vào model:

```ruby
class Micropost < ApplicationRecord
  # ... existing code ...

  searchable do
    text :content
    integer :user_id
    text :user_name do
      user.name
    end
    time :created_at
  end

  # Auto-reindex when micropost is created or updated
  after_commit :reindex, on: [:create, :update]
  
  # Reindex when micropost is destroyed
  after_commit :remove_from_index, on: :destroy

  private
  
  # Reindex micropost to Solr
  def reindex
    Sunspot.index(self)
  end
  
  # Remove micropost from Solr index
  def remove_from_index
    Sunspot.remove(self)
  end
end
```

---

## Cập nhật Controllers

### **UsersController - Search Action**

**Thay đổi từ Searchkick syntax sang Sunspot:**

**Trước (Searchkick):**
```ruby
def search
  @users = User.search(params[:q], 
    where: { activated: true },
    highlight: true,
    page: params[:page],
    per_page: 20
  )
end
```

**Sau (Sunspot):**
```ruby
def search
  search = Sunspot.search(User) do
    fulltext params[:q] do
      fields(:name, :email)
    end
    
    with(:activated, true)
    
    paginate page: params[:page], per_page: 20
  end
  
  @users = search.results
  @total = search.total
end
```

**Ví dụ đầy đủ với filters:**
```ruby
def search
  query = params[:q]
  
  search = Sunspot.search(User) do
    if query.present?
      fulltext query do
        fields(:name, :email)
      end
    end
    
    # Filter theo activated status
    with(:activated, true) unless current_user&.admin?
    
    # Filter theo following status
    if params[:following] == 'true'
      with(:id).any_of(current_user.following_ids)
    end
    
    # Sort
    order_by :created_at, :desc
    
    # Pagination
    paginate page: params[:page] || 1, per_page: 20
  end
  
  @users = search.results
  @total = search.total
  @current_page = params[:page] || 1
end
```

---

---

## Bước 3: Build và chạy Docker mới (SAU KHI SỬA CODE XONG)

### 3.1. Build lại Docker images

```bash
# Build lại images với code mới
docker-compose build

# Hoặc build lại từ đầu (nếu có thay đổi Dockerfile)
docker-compose build --no-cache
```

### 3.2. Start các services

```bash
# Start tất cả services (db, solr, web)
docker-compose up -d

# Kiểm tra status các services
docker-compose ps

# Xem logs để đảm bảo mọi thứ chạy OK
docker-compose logs -f
```

### 3.3. Kiểm tra Solr đang chạy

```bash
# Kiểm tra Solr container
docker-compose ps solr

# Xem Solr logs
docker-compose logs solr

# Test Solr connection từ host machine
curl -f http://localhost:8983/solr/admin/info/system

```

### 3.4. Cài đặt gems mới (sunspot_rails)

```bash
# Cài đặt gems trong Docker container
docker-compose exec web bundle install

# Kiểm tra gem đã được cài đặt
docker-compose exec web bundle list | grep sunspot
```

### 3.5. Chạy database migrations

**Quan trọng:** Đảm bảo database đã được migrate trước khi reindex data.

```bash
# Chạy migrations trong Docker container
docker-compose exec web bundle exec rake db:migrate

# Kiểm tra migrations đã chạy
docker-compose exec web bundle exec rake db:migrate:status
```

**Lưu ý:**
- Nếu database mới, có thể cần tạo database trước: `docker-compose exec web bundle exec rake db:create`
- Nếu cần reset database: `docker-compose exec web bundle exec rake db:reset` (CẨN THẬN: sẽ xóa toàn bộ data)

### 3.6. Chạy sunspot-installer

Sau khi chạy migrations, chạy `sunspot-installer` để tạo configset với schema.xml từ Sunspot:

```bash
# Chạy sunspot-installer trong Docker container
docker-compose exec web bundle exec sunspot-installer

# Kiểm tra files đã được tạo
ls -la solr/configsets/sunspot/conf/
# Phải có: schema.xml, solrconfig.xml và các files khác
```

**Lưu ý:** 
- Files sẽ được tạo ở `solr/configsets/sunspot/conf/` trên local (do volume mount `.:/rails`)
- Schema.xml từ `sunspot-installer` cần được sửa để tương thích với Solr 9

### 3.7. Sửa schema.xml để tương thích Solr 9

Schema.xml từ `sunspot-installer` cần được sửa để tương thích với Solr 9. Mở file `solr/configsets/sunspot/conf/schema.xml` và thực hiện các sửa đổi sau:

**1. Xóa StandardFilterFactory (2 chỗ):**

Tìm và xóa 2 dòng này:
```xml
<filter class="solr.StandardFilterFactory"/>
```

**2. Sửa LatLonType:**

Tìm dòng:
```xml
<fieldType name="location" class="solr.LatLonType" subFieldSuffix="_coordinate"/>
```

Sửa thành:
```xml
<fieldType name="location" class="solr.LatLonPointSpatialField"/>
```

**3. Xóa defaultSearchField:**

Tìm và xóa dòng:
```xml
<defaultSearchField>text</defaultSearchField>
```

**4. Xóa solrQueryParser:**

Tìm và xóa dòng:
```xml
<solrQueryParser defaultOperator="AND"/>
```

**Hoặc sử dụng lệnh sed để tự động sửa:**

```bash
# Xóa StandardFilterFactory
sed -i.bak '/StandardFilterFactory/d' solr/configsets/sunspot/conf/schema.xml

# Sửa LatLonType
sed -i.bak2 's/class="solr\.LatLonType" subFieldSuffix="_coordinate"/class="solr.LatLonPointSpatialField"/g' solr/configsets/sunspot/conf/schema.xml

# Xóa defaultSearchField
sed -i.bak3 '/defaultSearchField/d' solr/configsets/sunspot/conf/schema.xml

# Xóa solrQueryParser
sed -i.bak4 '/solrQueryParser/d' solr/configsets/sunspot/conf/schema.xml

# Kiểm tra đã sửa đúng
grep -E "StandardFilterFactory|LatLonType|defaultSearchField|solrQueryParser" solr/configsets/sunspot/conf/schema.xml || echo "Đã sửa thành công!"
```

**Schema.xml đã sửa đúng (tham khảo):**

File `solr/configsets/sunspot/conf/schema.xml` sau khi sửa sẽ có nội dung như sau (các phần quan trọng):

```xml
<schema name="sunspot" version="1.0">
  <types>
    <!-- *** This fieldType is used by Sunspot! *** -->
    <fieldType name="string" class="solr.StrField" omitNorms="true"/>
    <fieldType name="tdouble" class="solr.TrieDoubleField" omitNorms="true"/>
    <fieldType name="rand" class="solr.RandomSortField" omitNorms="true"/>
    <fieldType name="text" class="solr.TextField" omitNorms="false">
      <analyzer>
        <tokenizer class="solr.StandardTokenizerFactory"/>
        <!-- Đã xóa: <filter class="solr.StandardFilterFactory"/> -->
        <filter class="solr.LowerCaseFilterFactory"/>
        <filter class="solr.PorterStemFilterFactory"/>
      </analyzer>
    </fieldType>
    <fieldType name="boolean" class="solr.BoolField" omitNorms="true"/>
    <fieldType name="tint" class="solr.TrieIntField" omitNorms="true"/>
    <fieldType name="tlong" class="solr.TrieLongField" omitNorms="true"/>
    <fieldType name="tfloat" class="solr.TrieFloatField" omitNorms="true"/>
    <fieldType name="tdate" class="solr.TrieDateField" omitNorms="true"/>
    <fieldType name="daterange" class="solr.DateRangeField" omitNorms="true" />
    <fieldType name="textSpell" class="solr.TextField" positionIncrementGap="100" omitNorms="true">
      <analyzer>
        <tokenizer class="solr.StandardTokenizerFactory"/>
        <!-- Đã xóa: <filter class="solr.StandardFilterFactory"/> -->
        <filter class="solr.LowerCaseFilterFactory"/>
      </analyzer>
    </fieldType>
    <!-- Đã sửa: LatLonType → LatLonPointSpatialField -->
    <fieldType name="location" class="solr.LatLonPointSpatialField"/>
  </types>
  <fields>
    <!-- ... các fields ... -->
  </fields>
  <uniqueKey>id</uniqueKey>
  <!-- Đã xóa: <defaultSearchField>text</defaultSearchField> -->
  <!-- Đã xóa: <solrQueryParser defaultOperator="AND"/> -->
  <copyField source="*_text"  dest="textSpell" />
  <copyField source="*_s"  dest="textSpell" />
</schema>
```

### 3.8. Mount configset vào docker-compose.yml và restart Solr

**1. Cập nhật `docker-compose.yml`:**

Đảm bảo service `solr` có volume mount cho configset (nếu chưa có, thêm vào):

```yaml
solr:
  image: solr:9
  container_name: rails_solr
  restart: unless-stopped
  ports:
    - "8983:8983"
  volumes:
    - solr_data:/var/solr
    - ./solr/configsets/sunspot:/opt/solr/server/solr/configsets/sunspot
  environment:
    SOLR_HEAP: "512m"
```

**2. Restart Solr container:**

```bash
# Stop và start lại Solr để áp dụng volume mount
docker-compose stop solr
docker-compose up -d solr

# Kiểm tra configset đã được mount
docker-compose exec solr ls -la /opt/solr/server/solr/configsets/sunspot/conf/
# Phải có: schema.xml và solrconfig.xml
```

### 3.9. Tạo Solr Core với sunspot configset

**Quan trọng:** 
- Sunspot sử dụng core name theo pattern: `solr_{environment}` (ví dụ: `solr_development`)
- Phải tạo core với configset `sunspot` (không dùng `_default`)

```bash
# Kiểm tra environment hiện tại
docker-compose exec web ./bin/rails runner "puts Rails.env"

# Xóa core cũ nếu đã tồn tại
docker-compose exec solr solr delete -c solr_development 2>/dev/null || true

# Tạo core cho development environment với sunspot configset
docker-compose exec solr solr create_core -c solr_development -d sunspot

# Kiểm tra cores đã được tạo
curl "http://localhost:8983/solr/admin/cores?action=STATUS&wt=json" | python3 -m json.tool
```

### 3.10. Test reindex (tạo user và reindex)

**1. Tạo user test trong database:**

```bash
# Tạo user test
docker-compose exec web ./bin/rails runner "User.create!(name: 'Test User', email: 'test@example.com', password: 'password', activated: true)"
```

**2. Reindex data:**

```bash
# Reindex User model
docker-compose exec web bundle exec rake 'sunspot:reindex[User]'
```

**3. Kiểm tra data đã được index:**

```bash
# Kiểm tra số documents trong Solr
curl -s "http://localhost:8983/solr/solr_development/select?q=*:*&rows=0&wt=json" | python3 -c "import sys, json; data = json.load(sys.stdin); print(f\"Total documents: {data['response']['numFound']}\")"
```

### 3.11. Test search

```bash
# Test search trong Rails runner
docker-compose exec web ./bin/rails runner "search = Sunspot.search(User) { fulltext 'test' }; puts \"Found: #{search.total} users\"; search.results.each { |u| puts \"  - #{u.name} (#{u.email})\" }"
```

**Kết quả mong đợi:**
```
Found: 1 users
  - Test User (test@example.com)
```

**Hoặc test trong Rails console:**

```bash
docker-compose exec web ./bin/rails console

# Trong console:
search = Sunspot.search(User) { fulltext 'test' }
puts "Total: #{search.total}"
search.results.each { |u| puts "#{u.name} - #{u.email}" }

# Exit
exit
```

---

## Rake Tasks (Chạy trong Docker)

**Lưu ý:** Tất cả rake tasks phải chạy trong Docker container bằng `docker-compose exec web`

### **Reindex tất cả models:**
```bash
docker-compose exec web bundle exec rake sunspot:reindex
```

### **Reindex một model cụ thể:**
```bash
docker-compose exec web bundle exec rake sunspot:reindex[User]
docker-compose exec web bundle exec rake sunspot:reindex[Micropost]
```

### **Clear và reindex:**
```bash
# Clear index và reindex
docker-compose exec web bundle exec rake sunspot:solr:reindex

# Hoặc reindex từng model
docker-compose exec web bundle exec rake sunspot:reindex[User]
```

### **Kiểm tra Sunspot status:**
```bash
# Test connection
docker-compose exec web ./bin/rails runner "Sunspot.commit; puts 'OK'"
```

---

## So sánh Syntax: Searchkick vs Sunspot

### **Basic Search**

**Searchkick:**
```ruby
User.search("john")
```

**Sunspot:**
```ruby
Sunspot.search(User) do
  fulltext "john"
end.results
```

### **Search với Filters**

**Searchkick:**
```ruby
User.search("john", where: { activated: true })
```

**Sunspot:**
```ruby
Sunspot.search(User) do
  fulltext "john"
  with(:activated, true)
end.results
```

### **Search với Pagination**

**Searchkick:**
```ruby
User.search("john", page: 1, per_page: 20)
```

**Sunspot:**
```ruby
Sunspot.search(User) do
  fulltext "john"
  paginate page: 1, per_page: 20
end.results
```

### **Search với Highlighting**

**Searchkick:**
```ruby
results = User.search("john", highlight: true)
results.each do |result|
  result.highlight.name
end
```

**Sunspot:**
```ruby
search = Sunspot.search(User) do
  fulltext "john" do
    highlight :name, :email
  end
end

search.results.each do |result|
  highlights = search.hits.find { |h| h.primary_key == result.id.to_s }.highlights
  highlights.each do |highlight|
    puts highlight.format { |word| "<strong>#{word}</strong>" }
  end
end
```

---

## Testing (Chạy trong Docker)

### **1. Kiểm tra kết nối Solr:**
```bash
# Vào Rails console trong Docker
docker-compose exec web ./bin/rails console

# Test connection
Sunspot.commit
# Nếu không có lỗi, kết nối thành công

# Exit console
exit
```

### **2. Test search:**
```bash
# Vào Rails console
docker-compose exec web ./bin/rails console

# Trong console, chạy:
search = Sunspot.search(User) do
  fulltext "john"
  with(:activated, true)
end

puts "Total: #{search.total}"
search.results.each { |u| puts u.name }

# Exit console
exit
```

### **3. Test reindex:**
```bash
# Vào Rails console
docker-compose exec web ./bin/rails console

# Trong console, chạy:
User.first.sunspot_index
Sunspot.commit

# Hoặc reindex tất cả từ command line
docker-compose exec web rake sunspot:reindex[User]
```

### **4. Test từ browser:**

Sau khi đã reindex, bạn có thể test search từ browser:
- Truy cập: `http://localhost:3000/users/search?q=john`
- Kiểm tra kết quả trả về

### **5. Kiểm tra Solr Admin UI:**

Truy cập Solr Admin UI để xem indexes:
- URL: `http://localhost:8983/solr`
- Vào **Core Selector** → chọn core (ví dụ: `solr_development`)
- Vào tab **Query** để test query trực tiếp

---

## Migration Checklist

### Phase 1: Dọn dẹp Docker cũ
- [ ] Dừng tất cả containers: `docker-compose down`
- [ ] Xóa containers cũ (nếu cần): `docker-compose rm -f`
- [ ] Kiểm tra không còn containers đang chạy: `docker-compose ps`

### Phase 2: Sửa code (khi Docker đã dừng)
- [ ] Cập nhật Gemfile (xóa searchkick, thêm sunspot_rails)
- [ ] Xóa `config/initializers/searchkick.rb`
- [ ] Xóa `lib/tasks/searchkick.rake`
- [ ] Tạo `config/sunspot.yml`
- [ ] Cập nhật `app/models/user.rb` với `searchable` block
- [ ] Cập nhật `app/models/micropost.rb` (nếu cần)
- [ ] Cập nhật Controllers (thay đổi search syntax)

### Phase 3: Build và chạy Docker mới
- [ ] Build lại images: `docker-compose build`
- [ ] Start services: `docker-compose up -d`
- [ ] Kiểm tra services đang chạy: `docker-compose ps`
- [ ] Kiểm tra Solr logs: `docker-compose logs solr`
- [ ] Test Solr connection: `curl http://localhost:8983/solr/admin/info/system`

### Phase 4: Cài đặt và cấu hình
- [ ] Cài đặt gems: `docker-compose exec web bundle install`
- [ ] Verify Sunspot: `docker-compose exec web ./bin/rails runner "puts Sunspot::Rails::VERSION"`
- [ ] Chạy database migrations: `docker-compose exec web bundle exec rake db:migrate`
- [ ] Kiểm tra migrations: `docker-compose exec web bundle exec rake db:migrate:status`
- [ ] Chạy sunspot-installer: `docker-compose exec web bundle exec sunspot-installer`
- [ ] Kiểm tra files đã được tạo: `ls -la solr/configsets/sunspot/conf/`
- [ ] Sửa schema.xml (xóa StandardFilterFactory, sửa LatLonType, xóa defaultSearchField và solrQueryParser)
- [ ] Cập nhật docker-compose.yml để mount configset: `./solr/configsets/sunspot:/opt/solr/server/solr/configsets/sunspot`
- [ ] Restart Solr: `docker-compose stop solr && docker-compose up -d solr`
- [ ] Kiểm tra configset đã được mount: `docker-compose exec solr ls -la /opt/solr/server/solr/configsets/sunspot/conf/`
- [ ] Tạo Solr core với sunspot: `docker-compose exec solr solr create_core -c solr_development -d sunspot`
- [ ] Kiểm tra cores đã tạo: `curl "http://localhost:8983/solr/admin/cores?action=STATUS&wt=json"`
- [ ] Test Sunspot connection: `docker-compose exec web ./bin/rails runner "Sunspot.commit"`

### Phase 5: Test reindex và search
- [ ] Tạo user test: `docker-compose exec web ./bin/rails runner "User.create!(name: 'Test User', email: 'test@example.com', password: 'password', activated: true)"`
- [ ] Reindex data: `docker-compose exec web bundle exec rake 'sunspot:reindex[User]'`
- [ ] Test search: `docker-compose exec web ./bin/rails runner "search = Sunspot.search(User) { fulltext 'test' }; puts \"Found: #{search.total} users\""`
- [ ] Test search từ browser
- [ ] Test auto-reindex (tạo/update user)
- [ ] Test pagination
- [ ] Test filters
- [ ] Kiểm tra Solr Admin UI: `http://localhost:8983/solr`

---

## Tài liệu tham khảo

- [Sunspot Rails Documentation](https://github.com/sunspot/sunspot)
- [Sunspot API Documentation](http://sunspot.github.io/sunspot/docs/)
- [Solr Documentation](https://solr.apache.org/guide/)

---

## Lưu ý quan trọng

1. **Thứ tự thực hiện:** Luôn dừng Docker trước khi sửa code, sau đó build lại và chạy Docker mới
2. **Backup data trước khi reindex:** Reindex có thể mất thời gian với database lớn
3. **Test trong development trước:** Đảm bảo mọi thứ hoạt động trước khi deploy
4. **Monitor Solr performance:** Solr có thể ảnh hưởng đến performance nếu không được tối ưu
5. **Auto-reindex callbacks:** Sử dụng `after_commit` thay vì `after_save` để tránh reindex trong transaction
6. **Docker commands:** Tất cả rake tasks và Rails commands phải chạy qua `docker-compose exec web`
7. **Network configuration:** Đảm bảo `config/sunspot.yml` sử dụng đúng hostname (`solr` cho Docker, `localhost` cho local)

---

## Next Steps

Sau khi hoàn thành migration:

1. Implement search functionality trong UsersController
2. Implement AJAX search với Sunspot
3. Add search suggestions/autocomplete
4. Add search highlighting
5. Test và optimize performance