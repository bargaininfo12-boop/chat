<!-- v0.3-server_adapter_spec · 2025-10-25T05:24 IST (complete) -->
# Server Adapter Spec — WebSocket + Signed Uploads (complete)

**Purpose:** backend contract for the client-side code provided (WsClient, WsMessageHandler, CdnUploader, MessageRepository).
**Assumptions:** CDN (ImageKit/Bunny/S3-style) handles media storage; server provides signed upload URLs and a WebSocket (WS) gateway for realtime messaging. Firestore/SQL is canonical metadata store. Keep secrets server-side.

---

## Table of contents
1. Overview
2. Auth & session model
3. HTTP endpoints (signing, HTTP fallback)
4. WebSocket protocol (envelope + events)
5. Message lifecycle (server responsibilities)
6. DB schema (recommended fields)
7. Idempotency & dedup rules
8. Security, rate-limits & quotas
9. Error codes & handling
10. Scalability & operational notes
11. Example flows (sequence)
12. Testing checklist
13. Appendix — implementation notes

---

## 1) Overview (short)
- Clients upload media directly to CDN using **presigned upload URLs** provided by server (`/api/get-upload-url`).
- Clients send ephemeral JSON events over **WebSocket** for messaging, presence, typing, and receipts.
- Server validates events, persists message metadata to DB, replies with `message.ack`, and broadcasts `message.new`.
- If recipients are offline, server triggers push (FCM / APNs) with a compact payload.

---

## 2) Auth & session model
Two choices; pick one for your deployment:

**A. Firebase ID token (simple)**
- Client obtains Firebase ID token on sign-in. On WS connect, client sends `auth` event with that token. Server verifies token with Firebase Admin SDK and extracts `userId`. No token exchange endpoint required.

**B. Short-lived WS tokens (recommended for fine control)**
1. Client calls `POST /api/get-ws-token` with Firebase token (or cookie-based auth).
2. Server validates Firebase token, issues a short-lived signed WS token (JWT/HMAC) with claims: `{ userId, exp: <short> }`.
3. Client connects to WS and sends `auth` event with that WS token. Server verifies signature and accepts the session.

**WS Auth envelope (client→server):**
```json
{ "event":"auth", "data": { "token": "<firebase-or-ws-token>" } }
