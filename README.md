# Bài 4: Thiết lập Custom Network & Named Volume bằng Docker CLI

## Mục tiêu
- Thiết lập phân tầng mạng riêng biệt (Custom Bridge Network `app-net`) cho phép các container giao tiếp qua hostname (DNS).
- Cấu hình lưu trữ dữ liệu bền vững (Named Volume `db-data`) cho cơ sở dữ liệu.
- Kiểm tra tính bền vững của dữ liệu (Data Persistence) khi container bị hủy hoàn toàn (`docker rm -f`).

---

## 1. Cấu trúc Thư mục
```text
ss10/b4/
├── commands.sh         # Script tự động hóa toàn bộ quy trình CLI
├── docker-compose.yml  # File compose mở rộng tương đương
└── README.md           # Báo cáo kỹ thuật chi tiết
```

---

## 2. Quy trình Thực hiện bằng Docker CLI

### Bước 1: Tạo Network và Volume
```bash
docker network create --driver bridge app-net
docker volume create db-data
```

### Bước 2: Khởi chạy Database Container (`postgres:15-alpine`)
```bash
docker run -d \
  --name db-server \
  --network app-net \
  -v db-data:/var/lib/postgresql/data \
  -e POSTGRES_DB=mydb \
  -e POSTGRES_USER=myuser \
  -e POSTGRES_PASSWORD=mypassword \
  postgres:15-alpine
```

### Bước 3: Khởi tạo dữ liệu mẫu
```bash
docker exec -i db-server psql -U myuser -d mydb -c "CREATE TABLE users (id SERIAL PRIMARY KEY, name VARCHAR(50)); INSERT INTO users (name) VALUES ('DevOps Student');"
```

### Bước 4: Kiểm tra kết nối từ container khác qua DNS nội bộ `db-server`
```bash
docker run --rm --network app-net postgres:15-alpine \
  psql -h db-server -U myuser -d mydb -c "SELECT * FROM users;"
```
*Kết quả:*
```text
 id |      name      
----+----------------
  1 | DevOps Student
(1 row)
```

### Bước 5: Kiểm tra Data Persistence khi container bị xóa hoàn toàn
```bash
# Xóa cưỡng chế container cũ
docker rm -f db-server

# Khởi chạy container mới tên db-server-new gắn cùng volume db-data
docker run -d \
  --name db-server-new \
  --network app-net \
  -v db-data:/var/lib/postgresql/data \
  -e POSTGRES_DB=mydb \
  -e POSTGRES_USER=myuser \
  -e POSTGRES_PASSWORD=mypassword \
  postgres:15-alpine

# Đợi DB khởi động và truy vấn lại dữ liệu:
docker exec -i db-server-new psql -U myuser -d mydb -c "SELECT * FROM users;"
```
*Kết quả thực tế:*
```text
 id |      name      
----+----------------
  1 | DevOps Student
(1 row)
```
Dữ liệu vẫn được bảo toàn nguyên vẹn trên Named Volume `db-data`.

---

## 3. Dọn dẹp Tài nguyên
```bash
docker rm -f db-server-new
docker volume rm db-data
docker network rm app-net
```
