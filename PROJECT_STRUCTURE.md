# 專案結構說明

```
io-benchmark/
│
├── 📄 docker-compose.yml          # Docker Compose 配置
├── 📄 .gitignore                  # Git 忽略檔案
│
├── 📚 文件
│   ├── README.md                  # 完整說明文件
│   ├── QUICKSTART.md              # 快速開始指南
│   └── PROJECT_STRUCTURE.md       # 本檔案
│
├── 🔧 執行腳本
│   ├── run-tests.sh               # 一鍵執行測試
│   ├── run-comparison.sh          # 完整比較測試
│   ├── analyze-results.sh         # 分析測試結果
│   └── stop-services.sh           # 停止所有服務
│
├── 📊 k6 測試腳本
│   ├── k6-test.js                 # 比較測試（Go vs Laravel）
│   ├── k6-test-go-only.js         # Go API 專用測試
│   └── k6-test-laravel-only.js    # Laravel API 專用測試
│
├── 🚀 io-service/                 # I/O 模擬服務
│   ├── Dockerfile                 # Docker 配置
│   ├── go.mod                     # Go 模組定義
│   └── main.go                    # 主程式（1 秒延遲）
│
├── 🔵 go-api/                     # Go API 服務
│   ├── Dockerfile                 # Docker 配置
│   ├── go.mod                     # Go 模組定義
│   └── main.go                    # 主程式（呼叫 io-service）
│
└── 🐘 laravel-api/                # Laravel API 服務
    ├── Dockerfile                 # Docker 配置
    ├── php.ini                    # PHP 配置
    └── src/                       # Laravel 專案目錄
        ├── app/
        │   └── Http/Controllers/
        │       └── TestController.php  # API 控制器
        ├── routes/
        │   ├── api.php            # API 路由定義
        │   └── web.php            # Web 路由定義
        └── ...                    # 其他 Laravel 檔案
```

## 服務說明

### 1. IO Service (Port 8080)
- **用途**: 模擬需要時間的 I/O 操作
- **端點**: `GET /io`
- **行為**: 延遲 1 秒後回應 "ok"
- **技術**: Go 1.22

### 2. Go API (Port 8081)
- **用途**: 使用 Go 呼叫 IO Service
- **端點**: `GET /call`
- **行為**: 呼叫 io-service:8080/io 並返回結果
- **技術**: Go 1.22 + 原生 net/http

### 3. Laravel API (Port 9000)
- **用途**: 使用 Laravel 呼叫 IO Service
- **端點**: `GET /api/call`
- **行為**: 呼叫 io-service:8080/io 並返回 JSON 格式結果
- **技術**: Laravel 12 + PHP 8.4 + PHP-FPM + Nginx
- **架構**: 
  - Nginx 作為 Web 伺服器（監聽 port 9000）
  - PHP-FPM 處理 PHP 請求（Unix socket 通訊）
  - 動態進程管理：最多 50 個 worker 進程
  - 已啟用 OPcache 優化

## 測試流程

```
┌─────────────┐
│   k6 測試    │
└──────┬──────┘
       │
       ├──────────────────┐
       │                  │
       ▼                  ▼
┌─────────────┐    ┌─────────────┐
│   Go API    │    │ Laravel API │
│  (8081)     │    │   (9000)    │
└──────┬──────┘    └──────┬──────┘
       │                  │
       └──────────┬───────┘
                  │
                  ▼
           ┌─────────────┐
           │ IO Service  │
           │   (8080)    │
           └─────────────┘
           延遲 1 秒回應
```

## 測試腳本功能

### k6-test.js
- 同時測試兩個 API
- 逐步增加負載（10 → 50 → 100 並發用戶）
- 記錄個別 API 的效能指標
- 產生比較報告

### k6-test-go-only.js
- 專注測試 Go API
- 高負載測試（50 → 100 → 200 並發用戶）
- 測試極限效能

### k6-test-laravel-only.js
- 專注測試 Laravel API
- 高負載測試（50 → 100 → 200 並發用戶）
- 測試極限效能

## 執行腳本功能

### run-tests.sh
1. 啟動 Docker 服務
2. 等待服務就緒
3. 健康檢查
4. 執行比較測試
5. 顯示結果

### run-comparison.sh
1. 檢查服務狀態
2. 執行完整比較測試
3. 執行 Go API 高負載測試
4. 執行 Laravel API 高負載測試
5. 儲存所有結果

### analyze-results.sh
1. 讀取 summary.json
2. 解析測試結果
3. 格式化輸出比較報告
4. 顯示效能差異百分比

### stop-services.sh
- 停止並清理所有 Docker 容器

## 測試結果檔案

執行測試後會產生：

- `summary.json` - 比較測試結果
- `comparison-results.json` - 完整比較測試詳細結果
- `go-only-results.json` - Go API 高負載測試結果
- `laravel-only-results.json` - Laravel API 高負載測試結果

## Docker 網路

所有服務都在 `benchmark-network` 網路中：

- 服務間可以透過容器名稱互相通訊
- 外部可以透過 localhost:PORT 存取
- 網路驅動: bridge

## 自訂配置

### 調整 PHP 設定
編輯 `laravel-api/php.ini`:
```ini
memory_limit=512M
max_execution_time=5
```

### 調整 Go 並發數
編輯 `go-api/main.go` 或 `io-service/main.go`

### 調整測試參數
編輯 k6 測試腳本中的 `options` 物件

## 最佳化方向

### Laravel 最佳化
- 啟用 OPcache
- 調整 PHP-FPM workers
- 使用 Laravel Octane (Swoole/RoadRunner)
- 啟用響應快取

### Go 最佳化
- 調整 HTTP Client 連線池
- 使用 goroutine pool
- 實作連線重用
- 調整 GOMAXPROCS

## 擴展方向

可以新增的測試場景：

1. **資料庫操作**: 測試 CRUD 操作效能
2. **檔案上傳**: 測試大檔案處理
3. **WebSocket**: 測試即時通訊效能
4. **快取操作**: 測試 Redis/Memcached
5. **佇列處理**: 測試非同步任務

## 開發建議

### 新增服務
1. 在專案根目錄建立新的服務目錄
2. 建立 Dockerfile
3. 在 docker-compose.yml 中註冊
4. 建立對應的 k6 測試腳本

### 新增測試
1. 複製現有的 k6 測試腳本
2. 修改測試目標和參數
3. 在執行腳本中加入新測試

### 最佳化流程
1. 執行基準測試
2. 修改配置
3. 重新測試
4. 比較結果
5. 記錄改進
