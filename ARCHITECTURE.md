# 專案架構詳解

## Laravel API 架構

### 為什麼使用 PHP-FPM + Nginx？

1. **並發處理能力**
   - `php artisan serve` 是單進程開發伺服器，無法處理並發請求
   - PHP-FPM 使用進程池模式，可以同時處理多個請求

2. **效能優化**
   - PHP-FPM 支援動態進程管理
   - OPcache 快取 PHP 字節碼，減少編譯開銷
   - Nginx 作為反向代理，效能優異

### PHP-FPM 配置說明

```ini
pm = dynamic                    # 動態進程管理
pm.max_children = 50           # 最大子進程數
pm.start_servers = 10          # 啟動時的子進程數
pm.min_spare_servers = 5       # 空閒時最少保持的子進程數
pm.max_spare_servers = 20      # 空閒時最多保持的子進程數
pm.max_requests = 500          # 每個子進程處理的最大請求數
request_terminate_timeout = 10s # 請求超時時間
```

### 進程管理模式

PHP-FPM 的 `pm = dynamic` 模式會根據負載自動調整進程數：

- **低負載**: 保持 5-10 個進程待命
- **中等負載**: 逐漸增加到 20 個進程
- **高負載**: 最多可以有 50 個進程同時處理請求

### 為什麼選擇這些數值？

1. **pm.max_children = 50**
   - 考慮容器資源限制
   - 每個 PHP-FPM 進程約需 30-50MB 記憶體
   - 50 個進程約需 1.5-2.5GB 記憶體

2. **pm.start_servers = 10**
   - 啟動時就準備好 10 個進程
   - 可以立即處理突發流量
   - 不會浪費太多記憶體

3. **pm.max_requests = 500**
   - 防止記憶體洩漏
   - 每個進程處理 500 個請求後自動重啟

## Go API 架構

### 並發模型

Go 使用 goroutine 實現高並發：

```go
http.ListenAndServe(":8081", nil)
```

- 每個請求自動在新的 goroutine 中處理
- goroutine 非常輕量（約 2KB 記憶體）
- 可以輕鬆處理數千個並發連接

### 優勢

1. **記憶體效率**: goroutine 比系統線程輕量得多
2. **調度效率**: Go runtime 自動調度 goroutine
3. **簡單性**: 不需要額外配置進程池

## 效能比較預期

### 並發能力

| 指標 | Go API | Laravel API (PHP-FPM) |
|------|--------|----------------------|
| 最大並發數 | 10,000+ | 50 (可配置) |
| 記憶體使用 | 低 (~50MB) | 中等 (~2GB) |
| CPU 使用 | 高效 | 中等 |
| 響應時間 | 一致 | 隨負載增加 |

### 測試場景

1. **低並發 (10 用戶)**
   - Go: ~1000-1050ms
   - Laravel: ~1000-1100ms
   - **差異**: 幾乎相同

2. **中等並發 (50 用戶)**
   - Go: ~1000-1100ms
   - Laravel: ~1000-1150ms
   - **差異**: 輕微差距

3. **高並發 (100+ 用戶)**
   - Go: ~1000-1200ms (穩定)
   - Laravel: ~1100-1500ms (開始排隊)
   - **差異**: 明顯差距

4. **極限並發 (200+ 用戶)**
   - Go: ~1000-1500ms (依然穩定)
   - Laravel: 開始拒絕連接或超時
   - **差異**: Laravel 達到 max_children 限制

## 最佳化建議

### Laravel 進階最佳化

1. **增加 PHP-FPM worker 數量**
   ```ini
   pm.max_children = 100  # 需要更多記憶體
   ```

2. **使用 Laravel Octane**
   - 基於 Swoole 或 RoadRunner
   - 常駐記憶體，無需每次請求都啟動 PHP
   - 效能可提升 3-5 倍

3. **啟用 HTTP 快取**
   - 對於相同的請求，直接返回快取結果
   - 適用於讀取操作

### Go 最佳化

1. **調整 HTTP Client 設定**
   ```go
   client := &http.Client{
       Timeout: 2 * time.Second,
       Transport: &http.Transport{
           MaxIdleConns:        100,
           MaxIdleConnsPerHost: 100,
       },
   }
   ```

2. **使用連線池**
   - 重用 HTTP 連線
   - 減少建立連線的開銷

3. **調整 GOMAXPROCS**
   ```go
   runtime.GOMAXPROCS(runtime.NumCPU())
   ```

## 測試驗證

執行壓力測試來驗證配置：

```bash
# 測試 PHP-FPM 並發能力
./run-comparison.sh

# 觀察 PHP-FPM 進程
docker exec laravel-api ps aux | grep php-fpm

# 觀察資源使用
docker stats
```

## 結論

- **Laravel (PHP-FPM)**: 適合中等並發場景，配置靈活，生態系統豐富
- **Go**: 適合高並發場景，記憶體效率高，效能穩定

選擇哪個取決於：
1. 團隊技能
2. 專案規模
3. 並發需求
4. 維護成本
