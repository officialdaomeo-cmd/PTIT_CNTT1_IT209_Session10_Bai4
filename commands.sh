#!/usr/bin/env bash
# Script triển khai Custom Network & Named Volume bằng Docker CLI

set -e

echo "=== 1. Tạo Custom Network 'app-net' ==="
docker network create --driver bridge app-net

echo "=== 2. Tạo Named Volume 'db-data' ==="
docker volume create db-data

echo "=== 3. Khởi chạy Database Container 'db-server' ==="
docker run -d \
  --name db-server \
  --network app-net \
  -v db-data:/var/lib/postgresql/data \
  -e POSTGRES_DB=mydb \
  -e POSTGRES_USER=myuser \
  -e POSTGRES_PASSWORD=mypassword \
  postgres:15-alpine

echo "Đợi database sẵn sàng..."
sleep 5

echo "=== 4. Tạo dữ liệu mẫu vào PostgreSQL ==="
docker exec -i db-server psql -U myuser -d mydb <<EOF
CREATE TABLE IF NOT EXISTS users (id SERIAL PRIMARY KEY, name VARCHAR(50));
INSERT INTO users (name) VALUES ('DevOps Student');
SELECT * FROM users;
EOF

echo "=== 5. Khởi chạy Backend Container trong 'app-net' để kiểm tra kết nối DNS ==="
docker run --rm \
  --network app-net \
  postgres:15-alpine \
  psql -h db-server -U myuser -d mydb -c "SELECT current_database(), current_user;"

echo "=== 6. Kiểm tra Data Persistence (Xóa cứng container db-server) ==="
docker rm -f db-server

echo "=== 7. Khởi chạy Container db-server-new gắn cùng Volume db-data ==="
docker run -d \
  --name db-server-new \
  --network app-net \
  -v db-data:/var/lib/postgresql/data \
  -e POSTGRES_DB=mydb \
  -e POSTGRES_USER=myuser \
  -e POSTGRES_PASSWORD=mypassword \
  postgres:15-alpine

sleep 5

echo "=== 8. Xác minh dữ liệu vẫn còn nguyên vẹn sau khi thay container ==="
docker exec -i db-server-new psql -U myuser -d mydb -c "SELECT * FROM users;"

echo "=== HOÀN THÀNH KIỂM TRA BỀN VỮNG DỮ LIỆU ==="
