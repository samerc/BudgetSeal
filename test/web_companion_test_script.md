# Web Companion Test Script

Run these tests against the Web Companion API using curl or a browser.
Replace `HOST` with the phone's IP (e.g., `http://192.168.1.100:7432`).

---

## 1. AUTH & SESSIONS

### PIN Authentication
```bash
# Set PIN to 1234 on the phone first, then:

# Correct PIN → get token
curl -X POST $HOST/auth/pin \
  -H "Content-Type: application/json" \
  -d '{"pin":"1234"}'
# Expected: 200 {"token":"uuid-here","expiresAt":"..."}

# Wrong PIN
curl -X POST $HOST/auth/pin \
  -H "Content-Type: application/json" \
  -d '{"pin":"0000"}'
# Expected: 401 {"error":"Incorrect PIN. Please try again."}
# NOTE: no attempt count revealed

# 5 wrong PINs → lockout
for i in {1..5}; do
  curl -X POST $HOST/auth/pin -H "Content-Type: application/json" -d '{"pin":"9999"}'
done
# Expected: 429 {"error":"Too many failed attempts. Please try again later."}
# NOTE: no lockout duration revealed

# Missing PIN field
curl -X POST $HOST/auth/pin \
  -H "Content-Type: application/json" \
  -d '{"code":"1234"}'
# Expected: 400 {"error":"PIN must be a 4-digit string"}
```

### Token Validation
```bash
TOKEN="paste-token-here"

# Valid token
curl $HOST/auth/status -H "Authorization: Bearer $TOKEN"
# Expected: 200 {"authenticated":true}

# Invalid token
curl $HOST/auth/status -H "Authorization: Bearer fake-token"
# Expected: 200 {"authenticated":false}

# No token
curl $HOST/auth/status
# Expected: 200 {"authenticated":false}
```

### Logout
```bash
# Logout (revoke token)
curl -X POST $HOST/auth/logout -H "Authorization: Bearer $TOKEN"
# Expected: 200 {"success":true}

# Verify token is now invalid
curl $HOST/auth/status -H "Authorization: Bearer $TOKEN"
# Expected: 200 {"authenticated":false}
```

---

## 2. INPUT VALIDATION

### Transactions
```bash
# Missing required field
curl -X POST $HOST/api/transactions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type":"expense"}'
# Expected: 400 {"error":"accountId is required"}

# Negative amount
curl -X POST $HOST/api/transactions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type":"expense","accountId":"REAL-ID","amount":-50}'
# Expected: 400 {"error":"amount must be a positive number"}

# Amount exceeds max
curl -X POST $HOST/api/transactions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type":"expense","accountId":"REAL-ID","amount":9999999999}'
# Expected: 400 {"error":"amount exceeds maximum allowed value"}

# Invalid account ID
curl -X POST $HOST/api/transactions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type":"expense","accountId":"nonexistent-id","amount":10}'
# Expected: 400 {"error":"accountId does not exist"}

# Too many lines
curl -X POST $HOST/api/transactions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type":"expense","accountId":"REAL-ID","lines":[REPEAT_51_TIMES]}'
# Expected: 400 {"error":"Too many lines (max 50)"}

# Zero exchange rate
curl -X POST $HOST/api/transactions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type":"expense","accountId":"REAL-ID","amount":10,"exchangeRateToBase":0}'
# Expected: 400 {"error":"exchangeRateToBase must be positive"}

# Transfer without destination
curl -X POST $HOST/api/transactions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type":"transfer","accountId":"REAL-ID","amount":10}'
# Expected: 400 {"error":"destinationAccountId is required for transfers"}

# Negative page number
curl "$HOST/api/transactions?page=-1" -H "Authorization: Bearer $TOKEN"
# Expected: 200 with page=1 results (clamped to 1)

# Empty lines array
curl -X POST $HOST/api/transactions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type":"expense","accountId":"REAL-ID","lines":[],"amount":10}'
# Expected: 200 (single-line fallback with top-level amount)
```

### Accounts
```bash
# Invalid currency
curl -X POST $HOST/api/accounts \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","currency":"123","type":"cash"}'
# Expected: 400 {"error":"currency must be a 1–10 letter code (e.g. USD)"}

# Missing name
curl -X POST $HOST/api/accounts \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"currency":"USD","type":"cash"}'
# Expected: 400 {"error":"name is required"}

# Invalid account type
curl -X POST $HOST/api/accounts \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","currency":"USD","type":"crypto"}'
# Expected: 400 {"error":"type must be cash, bank, credit, or wallet"}
```

### Categories
```bash
# Invalid color hex
curl -X POST $HOST/api/categories \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","colorHex":"not-a-color"}'
# Expected: 400 {"error":"colorHex must be a valid hex color (e.g. #FF5733)"}

# Invalid transaction type
curl -X POST $HOST/api/categories \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","transactionType":"refund"}'
# Expected: 400 {"error":"transactionType must be income or expense"}
```

---

## 3. SECURITY

### XSS Injection
```bash
# Script tag in note
curl -X POST $HOST/api/transactions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type":"expense","accountId":"REAL-ID","amount":1,"note":"<script>alert(1)</script>"}'
# Expected: 400 {"error":"Request contains invalid characters"}

# SQL injection in title
curl -X POST $HOST/api/categories \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"x; DROP TABLE categories; --"}'
# Expected: 400 {"error":"Request contains invalid characters"}
```

### Rate Limiting
```bash
# Fire 12 POST requests rapidly
for i in {1..12}; do
  curl -s -o /dev/null -w "%{http_code}\n" \
    -X POST $HOST/api/transactions \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"type":"expense","accountId":"REAL-ID","amount":1}'
done
# Expected: first 10 return 201, last 2 return 429
```

### Honeypot
```bash
# Request with honeypot field
curl -X POST $HOST/api/transactions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type":"expense","accountId":"REAL-ID","amount":1,"website":"http://spam.com"}'
# Expected: 400 {"error":"Invalid request"}
```

### CORS
```bash
# Cross-origin request
curl -X OPTIONS $HOST/api/transactions \
  -H "Origin: http://evil.com" \
  -H "Access-Control-Request-Method: POST"
# Expected: 403 {"error":"Cross-origin request denied"}
```

### Private IP
```bash
# Only accessible from private IPs (192.168.x.x, 10.x.x.x, etc.)
# From a public IP: Expected: 403 {"error":"Access denied: not on local network"}
```

### Oversized Field
```bash
# Field > 10,000 chars
curl -X POST $HOST/api/transactions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"type\":\"expense\",\"accountId\":\"REAL-ID\",\"amount\":1,\"note\":\"$(python3 -c 'print("A"*11000)')\"}"
# Expected: 400 {"error":"Field \"note\" exceeds maximum length"}
```

---

## 4. EDGE CASES

### Reports with edge dates
```bash
# Month 0
curl "$HOST/api/reports/cashflow?year=2026&month=0" -H "Authorization: Bearer $TOKEN"
# Expected: 200 (clamped to month 1)

# Month 13
curl "$HOST/api/reports/cashflow?year=2026&month=13" -H "Authorization: Bearer $TOKEN"
# Expected: 200 (clamped to month 12)
```

### Fund nonexistent envelope
```bash
curl -X POST $HOST/api/envelopes/fake-uuid-here/fund \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"amount":10,"currency":"USD"}'
# Expected: 404 {"error":"Envelope not found"}
```

### Delete already-deleted transaction
```bash
# Delete once
curl -X DELETE $HOST/api/transactions/REAL-TX-ID -H "Authorization: Bearer $TOKEN"
# Expected: 200

# Delete again
curl -X DELETE $HOST/api/transactions/REAL-TX-ID -H "Authorization: Bearer $TOKEN"
# Expected: 404 (already deleted, not found)
```

---

## 5. ERROR RESPONSE VERIFICATION

For EVERY error response above, verify:
- [ ] No stack traces in response body
- [ ] No file paths in response body
- [ ] No database column/table names in response body
- [ ] No exception type names (SqliteException, StateError, etc.)
- [ ] Response Content-Type is application/json
- [ ] X-Frame-Options: DENY header present
- [ ] Content-Security-Policy header present
- [ ] Cache-Control: no-store header present

---

## 6. SPA BROWSER TESTS

Open the Web Companion in a browser and test:

- [ ] Login with correct PIN → dashboard loads
- [ ] Add transaction → appears in list
- [ ] Edit transaction → old is deleted, new is created (no data loss)
- [ ] Delete transaction → removed from list
- [ ] Navigate to all tabs (transactions, categories, accounts, envelopes, recurring, subscriptions, reports)
- [ ] Logout button → returns to PIN screen, token cleared
- [ ] Refresh page after logout → stays on PIN screen (not auto-logged-in)
- [ ] Open DevTools console → zero console.log/error/warn messages during normal use
- [ ] Right-click "View Source" → no sensitive data in HTML
- [ ] Check Network tab → Authorization header on every API request
- [ ] Check Network tab → CSP header on every response
