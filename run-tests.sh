#!/bin/bash

echo "🚀 啟動所有服務..."
docker-compose up -d

echo "⏳ 等待服務啟動..."
sleep 10

echo "🔍 檢查服務健康狀態..."
echo ""

# 檢查 IO Service
echo "檢查 IO Service (port 8080)..."
curl -s http://localhost:8080/io > /dev/null && echo "✅ IO Service 正常運作" || echo "❌ IO Service 無法連接"

# 檢查 Go API
echo "檢查 Go API (port 8081)..."
curl -s http://localhost:8081/call > /dev/null && echo "✅ Go API 正常運作" || echo "❌ Go API 無法連接"

# 檢查 Laravel API
echo "檢查 Laravel API (port 9000)..."
curl -s http://localhost:9000/api/call > /dev/null && echo "✅ Laravel API 正常運作" || echo "❌ Laravel API 無法連接"

echo ""
echo "📊 開始執行 k6 壓力測試..."
echo "================================"
echo ""

# 檢查 k6 是否已安裝
if ! command -v k6 &> /dev/null
then
    echo "❌ k6 未安裝"
    echo ""
    echo "請先安裝 k6:"
    echo "  macOS:   brew install k6"
    echo "  Linux:   參考 README.md 的安裝說明"
    echo "  Windows: choco install k6"
    exit 1
fi

# 執行比較測試
k6 run k6-test.js

echo ""
echo "✅ 測試完成！"
echo ""
echo "若要查看詳細報告，請查看 summary.json"
