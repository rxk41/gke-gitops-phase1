# Performance smoke test (k6)

Install k6 locally, deploy the app, then run:
#added

```bash
k6 run -e BASE_URL=http://YOUR_FRONTEND_LOAD_BALANCER_IP performance/k6-smoke.js
```

The smoke test uses 10 virtual users for 2 minutes, checks `/health`, `/api/products`, `/api/orders`, and enforces p95 latency < 500 ms and failed request rate < 1%.

This is a baseline, not a capacity benchmark. Start with low VUs to avoid unexpected cloud costs. Do not run load tests against a public endpoint you do not own.
