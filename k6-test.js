import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// 自訂指標
const goApiSuccessRate = new Rate('go_api_success_rate');
const laravelApiSuccessRate = new Rate('laravel_api_success_rate');
const goApiDuration = new Trend('go_api_duration');
const laravelApiDuration = new Trend('laravel_api_duration');

// 測試配置
export const options = {
  stages: [
    { duration: '30s', target: 100 },   // 逐漸增加到 100 個並發用戶
    { duration: '1m', target: 200 },    // 逐漸增加到 200 個並發用戶
    { duration: '2m', target: 300 },   // 逐漸增加到 300 個並發用戶
    { duration: '1m', target: 150 },    // 逐漸減少到 150 個並發用戶
    { duration: '30s', target: 0 },    // 逐漸減少到 0
  ],
  thresholds: {
    'http_req_duration': ['p(95)<3000'], // 95% 的請求應在 3 秒內完成
    'go_api_success_rate': ['rate>0.95'], // Go API 成功率應 > 95%
    'laravel_api_success_rate': ['rate>0.95'], // Laravel API 成功率應 > 95%
  },
};

const GO_API_URL = 'http://localhost:8081/call';
const LARAVEL_API_URL = 'http://localhost:9000/api/call';

export default function () {
  // 測試 Go API
  const goStart = new Date();
  const goResponse = http.get(GO_API_URL);
  const goDuration = new Date() - goStart;
  
  const goSuccess = check(goResponse, {
    'Go API status is 200': (r) => r.status === 200,
    'Go API response time < 2000ms': (r) => r.timings.duration < 2000,
  });
  
  goApiSuccessRate.add(goSuccess);
  goApiDuration.add(goDuration);

  // 測試 Laravel API
  const laravelStart = new Date();
  const laravelResponse = http.get(LARAVEL_API_URL);
  const laravelDuration = new Date() - laravelStart;
  
  const laravelSuccess = check(laravelResponse, {
    'Laravel API status is 200': (r) => r.status === 200,
    'Laravel API response time < 2000ms': (r) => r.timings.duration < 2000,
  });
  
  laravelApiSuccessRate.add(laravelSuccess);
  laravelApiDuration.add(laravelDuration);

  sleep(1);
}

export function handleSummary(data) {
  return {
    'summary.json': JSON.stringify(data),
    stdout: textSummary(data),
  };
}

function textSummary(data) {
  // 安全取得指標數據，若不存在則返回預設值
  const safeGet = (metric, key, defaultValue = 0) => {
    return metric && metric.values && metric.values[key] !== undefined 
      ? metric.values[key] 
      : defaultValue;
  };

  const goApiDurationData = data.metrics.go_api_duration;
  const laravelApiDurationData = data.metrics.laravel_api_duration;
  const goSuccessRate = data.metrics.go_api_success_rate;
  const laravelSuccessRate = data.metrics.laravel_api_success_rate;

  // 檢查是否有足夠的數據
  if (!goApiDurationData || !laravelApiDurationData || !goSuccessRate || !laravelSuccessRate) {
    return `
╔════════════════════════════════════════════════════════════════╗
║           Laravel vs Go API 效能比較測試報告                    ║
╚════════════════════════════════════════════════════════════════╝

❌ 測試數據不完整，無法生成報告
請檢查：
- 服務是否正常運行
- 是否有請求成功完成
- 網路連接是否正常
`;
  }

  const goAvg = safeGet(goApiDurationData, 'avg');
  const laravelAvg = safeGet(laravelApiDurationData, 'avg');
  const goP95 = safeGet(goApiDurationData, 'p(95)');
  const laravelP95 = safeGet(laravelApiDurationData, 'p(95)');

  return `
╔════════════════════════════════════════════════════════════════╗
║           Laravel vs Go API 效能比較測試報告                    ║
╚════════════════════════════════════════════════════════════════╝

📊 測試統計
────────────────────────────────────────────────────────────────
總請求數: ${data.metrics.http_reqs?.values?.count || 0}
測試時長: ${(data.state.testRunDurationMs / 1000).toFixed(2)}s

🚀 Go API 效能
────────────────────────────────────────────────────────────────
成功率:     ${(safeGet(goSuccessRate, 'rate') * 100).toFixed(2)}%
平均回應:   ${goAvg.toFixed(2)}ms
中位數:     ${safeGet(goApiDurationData, 'med').toFixed(2)}ms
P95:        ${goP95.toFixed(2)}ms
P99:        ${safeGet(goApiDurationData, 'p(99)').toFixed(2)}ms
最小值:     ${safeGet(goApiDurationData, 'min').toFixed(2)}ms
最大值:     ${safeGet(goApiDurationData, 'max').toFixed(2)}ms

🐘 Laravel API 效能
────────────────────────────────────────────────────────────────
成功率:     ${(safeGet(laravelSuccessRate, 'rate') * 100).toFixed(2)}%
平均回應:   ${laravelAvg.toFixed(2)}ms
中位數:     ${safeGet(laravelApiDurationData, 'med').toFixed(2)}ms
P95:        ${laravelP95.toFixed(2)}ms
P99:        ${safeGet(laravelApiDurationData, 'p(99)').toFixed(2)}ms
最小值:     ${safeGet(laravelApiDurationData, 'min').toFixed(2)}ms
最大值:     ${safeGet(laravelApiDurationData, 'max').toFixed(2)}ms

⚡ 效能比較
────────────────────────────────────────────────────────────────
平均回應時間差異: ${goAvg > 0 ? ((laravelAvg - goAvg) / goAvg * 100).toFixed(2) : 'N/A'}%
P95 回應時間差異: ${goP95 > 0 ? ((laravelP95 - goP95) / goP95 * 100).toFixed(2) : 'N/A'}%

${goAvg > 0 && laravelAvg > 0 && goAvg < laravelAvg ? '✅ Go API 平均回應時間更快' : '✅ Laravel API 平均回應時間更快'}
`;
}
