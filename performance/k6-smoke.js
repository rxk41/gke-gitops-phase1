import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';
const errors = new Rate('http_errors');
const base = (__ENV.BASE_URL || 'http://localhost:8080').replace(/\/$/, '');
export const options = {
  vus: 10,
  duration: '2m',
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<500'],
    http_errors: ['rate<0.01'],
  },
};
export default function () {
  for (const path of ['/health', '/api/products', '/api/orders']) {
    const res = http.get(`${base}${path}`, { tags: { endpoint: path } });
    const ok = check(res, { [`${path} returns 200`]: r => r.status === 200 });
    errors.add(!ok);
  }
  sleep(1);
}
