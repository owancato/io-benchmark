# 快速開始指南

## 🚀 一鍵測試

```bash
# 1. 啟動服務並執行測試
./run-tests.sh

# 2. 查看結果
./analyze-results.sh
```

就這麼簡單！

## 📋 詳細步驟

### 前置要求

- Docker 和 Docker Compose
- k6（壓力測試工具）

### 安裝 k6

**macOS:**
```bash
brew install k6
```

**Linux (Ubuntu/Debian):**
```bash
sudo gpg -k
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update
sudo apt-get install k6
```

**Windows:**
```powershell
choco install k6
```

### 執行測試

#### 選項 1: 基本測試
```bash
./run-tests.sh
```

這會：
1. 啟動所有 Docker 容器
2. 檢查服務健康狀態
3. 執行 k6 壓力測試
4. 顯示結果

#### 選項 2: 完整比較測試（推薦）
```bash
./run-comparison.sh
```

這會執行三輪測試：
1. **完整比較測試**: 同時測試 Go 和 Laravel
2. **Go API 高負載測試**: 200 個並發用戶
3. **Laravel API 高負載測試**: 200 個並發用戶

#### 選項 3: 手動測試
```bash
# 啟動服務
docker-compose up -d

# 等待服務啟動
sleep 10

# 測試健康狀態
curl http://localhost:8080/io
curl http://localhost:8081/call
curl http://localhost:9000/api/call

# 執行壓力測試
k6 run k6-test.js

# 或分別測試
k6 run k6-test-go-only.js
k6 run k6-test-laravel-only.js
```

### 查看結果

```bash
# 分析測試結果（需要 jq）
./analyze-results.sh

# 或直接查看 JSON 檔案
cat summary.json
```

### 停止服務

```bash
./stop-services.sh
```

## 📊 理解測試結果

### 關鍵指標

- **成功率**: 應該 > 95%
- **平均回應時間**: 由於 IO Service 有 1 秒延遲，預期約 1000-1200ms
- **P95**: 95% 的請求在此時間內完成
- **P99**: 99% 的請求在此時間內完成

### 預期結果

| 指標 | Go API | Laravel API |
|------|--------|-------------|
| 平均回應時間 | ~1000-1100ms | ~1000-1200ms |
| 並發能力 | 更高 | 中等 |
| 記憶體使用 | 更低 | 更高 |

## 🔧 自訂測試

### 調整並發數

編輯 `k6-test.js`:

```javascript
export const options = {
  stages: [
    { duration: '30s', target: 10 },   // 改成你想要的數字
    { duration: '1m', target: 50 },
    // ...
  ],
};
```

### 調整測試時長

```bash
# 100 個並發用戶，持續 1 分鐘
k6 run --vus 100 --duration 1m k6-test.js
```

### 只測試特定 API

```bash
# 只測試 Go
k6 run k6-test-go-only.js

# 只測試 Laravel
k6 run k6-test-laravel-only.js
```

## 🐛 常見問題

### 1. 服務無法啟動

```bash
# 查看日誌
docker-compose logs

# 重新建置
docker-compose down
docker-compose up --build
```

### 2. k6 找不到

確保已安裝 k6:
```bash
k6 version
```

### 3. API 無法連接

檢查容器狀態:
```bash
docker-compose ps
```

確保所有服務都是 "Up" 狀態。

### 4. Laravel API 錯誤

查看 Laravel 日誌:
```bash
docker-compose logs laravel-api
```

## 📈 進階使用

### 匯出詳細報告

```bash
k6 run k6-test.js --out json=detailed-results.json
```

### 使用 k6 Cloud（需註冊）

```bash
k6 cloud k6-test.js
```

### 整合 CI/CD

```bash
# 在 CI/CD pipeline 中使用
k6 run k6-test.js --quiet --no-color
```

## 🎯 下一步

1. 嘗試最佳化 Laravel 配置（OPcache、PHP-FPM）
2. 測試 Laravel Octane 的效能
3. 調整 Go API 的連線池設定
4. 增加更多測試場景

更多資訊請參考 [README.md](README.md)
