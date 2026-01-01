# Solr Setup và Usage Guide

## Tổng quan

Project đã được setup với Apache Solr và Searchkick gem để hỗ trợ full-text search cho các models.

## Kiến trúc

- **Solr**: Apache Solr 9 chạy trong Docker container
- **Searchkick**: Ruby gem để integrate Solr với Rails models
- **rsolr**: Ruby client library để connect với Solr

## Setup

### 1. Start Solr Service

```bash
# Start Solr service
docker-compose up -d solr

# Check Solr status
docker-compose ps solr

# View Solr logs
docker-compose logs -f solr
```

### 2. Install Gems

```bash
# Install gems (nếu chưa install)
docker-compose exec web bundle install
```

### 3. Verify Solr Connection

```bash
# Check Solr connection
docker-compose exec web rake searchkick:check
```

### 4. Reindex Data

Sau khi setup, cần reindex data hiện có:

```bash
# Reindex tất cả models
docker-compose exec web rake searchkick:reindex_all

# Reindex một model cụ thể
docker-compose exec web rake searchkick:reindex[User]
docker-compose exec web rake searchkick:reindex[Micropost]
```

## Solr Admin UI

Truy cập Solr Admin UI tại: http://localhost:8983/solr

- **Admin UI**: http://localhost:8983/solr/#/
- **Core Browser**: Xem các cores/indexes đã được tạo
- **Query**: Test queries trực tiếp

## Tạo Core và Schema trên Solr

### Cách Searchkick tự động tạo Core

**Lưu ý**: Với Searchkick, cores và schema được tự động tạo khi bạn gọi `reindex` lần đầu tiên. Bạn không cần tạo manual, nhưng hiểu cách Solr hoạt động sẽ giúp bạn debug và customize tốt hơn.

Khi bạn chạy:
```bash
rake searchkick:reindex[User]
```

Searchkick sẽ tự động:
1. Tạo core với tên `users_development` (hoặc `users_production` tùy environment)
2. Tạo schema với các fields từ `search_data` method
3. Index data vào core đó

### Tạo Core Manual (Optional - để hiểu cách Solr hoạt động)

Nếu muốn tạo core manual để hiểu cách Solr hoạt động:

#### Cách 1: Sử dụng Solr Admin UI

1. Truy cập Solr Admin UI: http://localhost:8983/solr/#/

2. Vào **Core Admin** → **Add Core**

3. Điền thông tin:
   - **name**: `test_core` (tên core)
   - **instanceDir**: `test_core` (thư mục instance)
   - **dataDir**: `data` (thư mục data)
   - **config**: `solrconfig.xml` (config file)
   - **schema**: `managed-schema` (schema file)

4. Click **Add Core**

#### Cách 2: Sử dụng Solr API

```bash
# Tạo core mới
curl "http://localhost:8983/solr/admin/cores?action=CREATE&name=test_core&instanceDir=test_core"

# Kiểm tra core đã được tạo
curl "http://localhost:8983/solr/admin/cores?action=STATUS&core=test_core"
```

#### Cách 3: Sử dụng Docker exec

```bash
# Vào Solr container
docker-compose exec solr bash

# Tạo core
bin/solr create_core -c test_core

# Exit container
exit
```

### Tạo Schema Manual

#### Cách 1: Sử dụng Solr Admin UI

1. Vào core bạn muốn config (ví dụ: `users_development`)

2. Vào **Schema** tab

3. Click **Add Field** để thêm field mới:
   - **Field name**: `name` (tên field)
   - **Field type**: `text_general` (kiểu dữ liệu)
   - **Stored**: ✓ (lưu giá trị)
   - **Indexed**: ✓ (có thể search)
   - **Multi-valued**: (nếu field có nhiều giá trị)

4. Click **Add Field**

#### Cách 2: Sử dụng Solr API

```bash
# Thêm field vào schema
curl -X POST "http://localhost:8983/solr/users_development/schema" \
  -H "Content-Type: application/json" \
  -d '{
    "add-field": {
      "name": "name",
      "type": "text_general",
      "stored": true,
      "indexed": true
    }
  }'

# Thêm field type custom
curl -X POST "http://localhost:8983/solr/users_development/schema" \
  -H "Content-Type: application/json" \
  -d '{
    "add-field-type": {
      "name": "text_vi",
      "class": "solr.TextField",
      "analyzer": {
        "tokenizer": {
          "class": "solr.StandardTokenizerFactory"
        },
        "filters": [
          {"class": "solr.LowerCaseFilterFactory"},
          {"class": "solr.StopFilterFactory", "words": "stopwords.txt"}
        ]
      }
    }
  }'
```

#### Cách 3: Edit schema file trực tiếp

```bash
# Vào Solr container
docker-compose exec solr bash

# Edit schema file (ví dụ cho core users_development)
vi /var/solr/data/users_development/conf/managed-schema

# Thêm field definition:
# <field name="name" type="text_general" indexed="true" stored="true"/>

# Reload core sau khi edit
curl "http://localhost:8983/solr/admin/cores?action=RELOAD&core=users_development"
```

### Schema Fields được Searchkick tự động tạo

Khi Searchkick tạo core, nó sẽ tự động tạo các fields dựa trên `search_data` method:

**Ví dụ với User model:**
```ruby
def search_data
  {
    name: name,
    email: email,
    created_at: created_at,
    activated: activated?
  }
end
```

Searchkick sẽ tạo các fields trong Solr:
- `name_text` (text_general) - cho full-text search
- `email_text` (text_general) - cho full-text search
- `created_at_d` (pdate) - cho date search và sorting
- `activated_b` (boolean) - cho boolean filter

### Field Types trong Solr

Solr có nhiều field types, phổ biến nhất:

- **text_general**: Full-text search, có tokenization và stemming
- **string**: Exact match, không tokenize
- **pint**: Integer number
- **pfloat**: Float number
- **pdate**: Date/DateTime
- **boolean**: Boolean (true/false)
- **location**: Geographic location

### Xem Schema hiện tại

#### Cách 1: Solr Admin UI
1. Vào core (ví dụ: `users_development`)
2. Click tab **Schema**
3. Xem **Fields** và **Field Types**

#### Cách 2: Solr API
```bash
# Xem tất cả fields
curl "http://localhost:8983/solr/users_development/schema/fields"

# Xem field cụ thể
curl "http://localhost:8983/solr/users_development/schema/fields/name"

# Xem field types
curl "http://localhost:8983/solr/users_development/schema/fieldtypes"
```

### Customize Schema với Searchkick

Nếu muốn customize schema khi dùng Searchkick, bạn có thể:

```ruby
# Trong model
class User < ApplicationRecord
  searchkick(
    # Customize index name
    index_name: "custom_users",

    # Customize field mappings
    mappings: {
      properties: {
        name: { type: "text", analyzer: "standard" },
        email: { type: "keyword" } # exact match
      }
    },

    # Customize settings
    settings: {
      analysis: {
        analyzer: {
          custom_analyzer: {
            type: "custom",
            tokenizer: "standard",
            filter: ["lowercase", "stop"]
          }
        }
      }
    }
  )
end
```

### Xóa Core

#### Cách 1: Solr Admin UI
1. Vào **Core Admin**
2. Chọn core cần xóa
3. Click **Unload**

#### Cách 2: Solr API
```bash
# Unload core
curl "http://localhost:8983/solr/admin/cores?action=UNLOAD&core=test_core"

# Xóa core và data
curl "http://localhost:8983/solr/admin/cores?action=UNLOAD&deleteIndex=true&deleteDataDir=true&deleteInstanceDir=true&core=test_core"
```

#### Cách 3: Docker exec
```bash
docker-compose exec solr bash
bin/solr delete -c test_core
exit
```

### Best Practices

1. **Để Searchkick tự động tạo**: Với hầu hết use cases, để Searchkick tự động tạo core và schema là đủ

2. **Chỉ customize khi cần**: Chỉ customize schema khi bạn cần:
   - Custom analyzers (cho tiếng Việt, etc.)
   - Custom field types
   - Performance optimization

3. **Test schema changes**: Luôn test schema changes trong development trước khi apply production

4. **Reindex sau schema changes**: Sau khi thay đổi schema, cần reindex lại data:
   ```bash
   rake searchkick:clear[ModelName]
   rake searchkick:reindex[ModelName]
   ```

### Troubleshooting Schema Issues

#### Core không được tạo tự động

```bash
# Check Solr logs
docker-compose logs solr

# Verify Solr connection
rake searchkick:check

# Try manual reindex
rake searchkick:reindex[User]
```

#### Schema không match với search_data

```bash
# Clear và reindex
rake searchkick:clear[User]
rake searchkick:reindex[User]

# Verify schema trong Solr Admin UI
# http://localhost:8983/solr/users_development/schema
```

#### Field type không đúng

Nếu field type không đúng, bạn có thể:
1. Clear index
2. Customize mappings trong searchkick config
3. Reindex

## Models đã được setup

### User Model

```ruby
# Search data được index:
- name
- email
- created_at
- activated (boolean)

# Usage:
User.search("john")
User.search("john@example.com")
```

### Micropost Model

```ruby
# Search data được index:
- content
- user_id
- user_name
- created_at

# Usage:
Micropost.search("hello world")
Micropost.search("hello", where: { user_id: 1 })
```

## Rake Tasks

### Reindex Tasks

```bash
# Reindex tất cả models
rake searchkick:reindex_all

# Reindex một model cụ thể
rake searchkick:reindex[ModelName]
# Example: rake searchkick:reindex[User]
```

### Clear Tasks

```bash
# Clear tất cả indexes
rake searchkick:clear_all

# Clear một model index
rake searchkick:clear[ModelName]
# Example: rake searchkick:clear[User]
```

### Check Connection

```bash
# Check Solr connection
rake searchkick:check
```

## Usage trong Code

### Basic Search

```ruby
# Search users
users = User.search("john")

# Search microposts
microposts = Micropost.search("hello world")

# Search với filters
users = User.search("john", where: { activated: true })
microposts = Micropost.search("hello", where: { user_id: 1 })
```

### Advanced Search

```ruby
# Search với highlighting
results = User.search("john", highlight: true)

# Search với pagination
users = User.search("john", page: 1, per_page: 20)

# Search với sorting
users = User.search("john", order: { created_at: :desc })

# Search với fields
users = User.search("john", fields: [:name, :email])
```

### Auto-indexing

Models tự động được index khi:
- Tạo mới record
- Update record
- Delete record (tự động remove khỏi index)

## Environment Variables

- `SOLR_URL`: URL của Solr server
  - Default trong Docker: `http://solr:8983/solr`
  - Local development: `http://localhost:8983/solr`

## Troubleshooting

### Solr không start

```bash
# Check logs
docker-compose logs solr

# Restart service
docker-compose restart solr

# Recreate container
docker-compose up -d --force-recreate solr
```

### Connection Error

```bash
# Verify Solr is running
docker-compose ps solr

# Check Solr URL
docker-compose exec web rake searchkick:check

# Verify network
docker network inspect ror_internship_assignment_12_2025_rails_network
```

### Index không update

```bash
# Clear và reindex
docker-compose exec web rake searchkick:clear_all
docker-compose exec web rake searchkick:reindex_all
```

### Search không trả về kết quả

1. Kiểm tra data đã được index chưa:
   ```bash
   docker-compose exec web rake searchkick:reindex_all
   ```

2. Kiểm tra Solr Admin UI để xem indexes

3. Test query trực tiếp trong Solr Admin UI

## Extending Search cho Domain của bạn

Khi implement search cho domain được assign, bạn cần:

1. **Extend search_data method** trong model:
   ```ruby
   def search_data
     {
       # Thêm fields bạn muốn search
       field1: value1,
       field2: value2,
       # ...
     }
   end
   ```

2. **Reindex sau khi thay đổi search_data**:
   ```bash
   rake searchkick:reindex[YourModel]
   ```

3. **Implement search logic** trong controller/service:
   ```ruby
   def search
     @results = YourModel.search(params[:q])
   end
   ```

## Resources

- [Searchkick Documentation](https://github.com/ankane/searchkick)
- [Solr Documentation](https://solr.apache.org/guide/)
- [rsolr Documentation](https://github.com/rsolr/rsolr)
