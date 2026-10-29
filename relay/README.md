# BudgetSeal household relay

Lets the phones of one household sync without a Google, Dropbox or Microsoft
account. It stores files it cannot read: each phone encrypts everything with a
key that exists only on the household's phones and in its QR code.

A Cloudflare Worker (`src/index.js`) and one Durable Object per household
(SQLite: the key's hash, the file list, the files in 1 MB chunks). The protocol
is at the top of `src/index.js`.

Limits: 20 MB per file, 200 MB per household, 240 requests a minute per
household.

## Run your own

```bash
npm install
npx wrangler login
npx wrangler deploy        # prints the address to enter in the app
```

## Test

```bash
npx wrangler dev           # local, then in another terminal:
npm test
RELAY=https://<your address> npm test   # a deployed relay (throwaway household)
```

Hosted by BudgetSeal at `https://budgetseal-relay.budgetseal-relay.workers.dev`
(free workers.dev address while testing, Oct 2026).
