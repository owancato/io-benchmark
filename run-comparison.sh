#!/bin/bash

echo "🔥 執行 Laravel vs Go 完整比較測試"
echo "================================"
echo ""

# 確保服務正在運行
echo "檢查服務狀態..."
if ! curl -s http://localhost:8081/call > /dev/null; then
    echo "❌ Go API 未運行，請先執行 docker-compose up"
    exit 1
fi

if ! curl -s http://localhost:9000/api/call > /dev/null; then
    echo "❌ Laravel API 未運行，請先執行 docker-compose up"
    exit 1
fi

echo "✅ 所有服務正常運行"
echo ""

# 1. 執行完整比較測試
echo "📊 第一輪：完整比較測試"
echo "------------------------"
k6 run k6-test.js --out json=comparison-results.json
echo ""

# 2. 單獨測試 Go API（高負載）
echo "🚀 第二輪：Go API 高負載測試"
echo "------------------------"
k6 run k6-test-go-only.js --out json=go-only-results.json
echo ""

# 3. 單獨測試 Laravel API（高負載）
echo "🐘 第三輪：Laravel API 高負載測試"
echo "------------------------"
k6 run k6-test-laravel-only.js --out json=laravel-only-results.json
echo ""

echo "✅ 所有測試完成！"
echo ""
echo "測試結果已儲存至："
echo "  - comparison-results.json (比較測試)"
echo "  - go-only-results.json (Go API 高負載)"
echo "  - laravel-only-results.json (Laravel API 高負載)"