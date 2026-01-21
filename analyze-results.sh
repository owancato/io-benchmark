#!/bin/bash

if [ ! -f "summary.json" ]; then
    echo "❌ 找不到 summary.json 檔案"
    echo "請先執行 ./run-tests.sh"
    exit 1
fi

echo "📊 分析測試結果..."
echo ""

# 使用 jq 解析 JSON（如果已安裝）
if command -v jq &> /dev/null; then
    echo "使用 jq 解析結果..."
    
    # 提取關鍵指標
    echo "═══════════════════════════════════════════════════════"
    echo "            測試結果總覽"
    echo "═══════════════════════════════════════════════════════"
    echo ""
    
    jq -r '
    "📈 總請求數: " + (.metrics.http_reqs.values.count | tostring),
    "⏱️  測試時長: " + ((.state.testRunDurationMs / 1000) | tostring) + "s",
    "",
    "🚀 Go API",
    "────────────────────────────────────────────────────────",
    "成功率: " + ((.metrics.go_api_success_rate.values.rate * 100) | tostring | .[0:5]) + "%",
    "平均回應: " + (.metrics.go_api_duration.values.avg | tostring | .[0:7]) + "ms",
    "P95: " + (.metrics.go_api_duration.values["p(95)"] | tostring | .[0:7]) + "ms",
    "",
    "🐘 Laravel API",
    "────────────────────────────────────────────────────────",
    "成功率: " + ((.metrics.laravel_api_success_rate.values.rate * 100) | tostring | .[0:5]) + "%",
    "平均回應: " + (.metrics.laravel_api_duration.values.avg | tostring | .[0:7]) + "ms",
    "P95: " + (.metrics.laravel_api_duration.values["p(95)"] | tostring | .[0:7]) + "ms",
    "",
    "⚡ 效能差異",
    "────────────────────────────────────────────────────────",
    "平均回應時間: " + (
        ((.metrics.laravel_api_duration.values.avg - .metrics.go_api_duration.values.avg) / .metrics.go_api_duration.values.avg * 100) 
        | if . > 0 then "Laravel 慢 " + (. | tostring | .[0:5]) + "%" 
          else "Laravel 快 " + ((. * -1) | tostring | .[0:5]) + "%" end
    )
    ' summary.json
else
    echo "💡 提示：安裝 jq 可以看到更詳細的分析"
    echo "   macOS: brew install jq"
    echo "   Linux: sudo apt-get install jq"
    echo ""
    echo "目前顯示原始 JSON 檔案..."
    cat summary.json | python3 -m json.tool 2>/dev/null || cat summary.json
fi

echo ""
echo "═══════════════════════════════════════════════════════"
