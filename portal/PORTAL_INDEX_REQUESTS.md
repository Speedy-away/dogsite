# How `portal/index.html` Works (Requests + Flow)

This file documents exactly how the portal frontend talks to the backend so you can reuse it somewhere else.

## 1) Core config in `portal/index.html`

`portal/index.html` defines two hidden inputs used by all API calls:

- `#apiUrl` = `https://proudlyauthentication.com/`
- `#portalKey` = `pk_gri2butNfQ28AWQqNTD5xLtQKwer2MNv`

Also loaded on page startup:

- `portal.css`
- `portal.js`
- Google Fonts CSS (`fonts.googleapis.com`)
- Font Awesome CSS (`cdnjs.cloudflare.com`)

## 2) Request builder in `portal/portal.js`

All backend calls go through:

- `getApiUrl(endpoint)`
- `getHeaders()`
- `api(method, endpoint, body)`

Request URL format:

- `{apiUrl}/api/portal/v1/{portalKey}{endpoint}`

Example final URL:

- `https://proudlyauthentication.com/api/portal/v1/pk_xxx/auth/session`

Headers:

- Always: `Content-Type: application/json`
- If logged in: `Authorization: Bearer {portalSessionToken}`

Session token storage:

- `localStorage['portalSessionToken']`

## 3) Startup request order

On `DOMContentLoaded`:

1. Handle OAuth callback hash params (`oauth_session`, etc.)
2. `GET /info`
3. If token exists, `GET /auth/session`
4. Route from `window.location.hash`
5. Load page-specific data (forum/chat/messages/etc.)

## 4) OAuth redirect request (not through `api()`)

When clicking OAuth login/register/link, browser is redirected to:

- `GET /auth/oauth/{provider}/authorize?action={login|register|link}&redirect_uri={encodedUrl}`
- For link flow it also appends `&session_token={token}`

This is built as a full absolute URL and assigned to `window.location.href`.

## 5) Complete API endpoint list

All of these are relative to `/api/portal/v1/{portalKey}`.

### Auth

- `GET /auth/session`
- `POST /auth/login`
- `POST /auth/register`
- `POST /auth/register/verify`
- `POST /auth/register/resend`
- `POST /auth/password-reset/request`
- `POST /auth/password-reset/confirm`
- `POST /auth/logout`
- `POST /auth/set-password`
- `POST /auth/hwid/reset`
- `POST /auth/redeem-key`
- `GET /auth/oauth/status`
- `POST /auth/oauth/link`
- `POST /auth/oauth/unlink`

### Portal metadata

- `GET /info`
- `GET /subscriptions`

### Forums + threads + replies + moderation

- `GET /forum/categories`
- `POST /forum/categories`
- `PUT /forum/categories/{categoryId}`
- `DELETE /forum/categories/{categoryId}`
- `POST /forum/categories/reorder`
- `GET /forum/recent-activity?limit=10`
- `GET /forum/categories/{categoryId}/threads`
- `POST /forum/categories/{categoryId}/threads`
- `GET /forum/threads/{threadId}`
- `PUT /forum/threads/{threadId}`
- `DELETE /forum/threads/{threadId}`
- `POST /forum/threads/{threadId}/like`
- `POST /forum/threads/{threadId}/react`
- `POST /forum/threads/{threadId}/poll/vote`
- `POST /forum/threads/{threadId}/watch`
- `DELETE /forum/threads/{threadId}/watch`
- `GET /forum/threads/{threadId}/watchers`
- `POST /forum/threads/{threadId}/lock`
- `POST /forum/threads/{threadId}/pin`
- `POST /forum/threads/{threadId}/move`
- `POST /forum/threads/{threadId}/replies`
- `PUT /forum/threads/{threadId}/replies/{replyId}`
- `DELETE /forum/threads/{threadId}/replies/{replyId}`
- `POST /forum/threads/{threadId}/replies/{replyId}/like`
- `POST /forum/threads/{threadId}/replies/{replyId}/react`
- `GET /forum/threads/{threadId}/history`
- `GET /forum/threads/{threadId}/replies/{replyId}/history`
- `DELETE /forum/threads/{threadId}/replies` (admin bulk reply delete)

### Reports

- `POST /reports`
- `GET /reports?status=pending&limit=1`
- `GET /reports?status=pending`
- `GET /reports?status={status}` (or `/reports`)
- `PUT /reports/{reportId}`

### Global chat

- `GET /chat/messages?limit=50`
- `POST /chat/messages`
- `DELETE /chat/messages/{messageId}`
- `POST /chat/participants/{participantKey}/mute`
- `DELETE /chat/participants/{participantKey}/mute`
- `GET /chat/muted`
- `DELETE /chat/participants/{participantKey}/messages`
- `DELETE /chat/messages/bulk`
- `DELETE /chat`

### Private messages

- `GET /messages/conversations`
- `GET /messages/conversations/{conversationId}`
- `POST /messages/conversations/{conversationId}/read`
- `POST /messages`

### Members, users, profile, friends

- `GET /members?online=true&limit=50`
- `GET /members?q={query}&limit=30`
- `GET /profile`
- `PUT /profile`
- `GET /profile/{userId}`
- `GET /users/{id}`
- `GET /users/by-username/{username}`
- `GET /users/blocked`
- `POST /users/block`
- `POST /users/{uid}/ban`
- `GET /users/{uid}/activity`
- `DELETE /users/{uid}/content`
- `GET /friends/requests?_={timestamp}`
- `GET /friends?_={timestamp}`
- `POST /friends/request`
- `POST /friends/accept`
- `POST /friends/reject`
- `POST /friends/cancel`
- `DELETE /friends/{userId}`

### Support tickets

- `GET /support/tickets`
- `GET /support/tickets/{ticketId}`
- `POST /support/tickets`
- `POST /support/tickets/{ticketId}/reply`
- `POST /support/tickets/{ticketId}/close`
- `PATCH /support/tickets/{ticketId}` (priority/category/status updates)
- `POST /support/tickets/{ticketId}/reopen`
- `GET /support/tickets/stats`
- `POST /support/tickets/bulk-close`
- `DELETE /support/tickets/{ticketId}`

### Badges, notifications, search

- `GET /badges`
- `GET /notifications?limit=20`
- `GET /notifications/unread-count`
- `POST /notifications/{notificationId}/read`
- `POST /notifications/read-all`
- `GET /search?q={query}&type=all&limit=20`

## 6) Polling/timed requests

- Chat auto refresh: every 5s -> `GET /chat/messages?limit=50`
- Thread watcher heartbeat: every 30s -> `POST /forum/threads/{threadId}/watch`
- Friends lists use cache-buster query (`?_={Date.now()}`)

## 7) Hash routes that trigger requests

Main hash routes and typical request made:

- `#forum` -> categories/recent activity
- `#category/{id}` -> category threads
- `#thread/{id}` -> thread details + replies
- `#chat` -> chat messages + polling
- `#messages` -> conversations
- `#conversation/{id}` -> conversation detail
- `#support` -> tickets
- `#ticket/{id}` -> ticket detail
- `#members` -> online members
- `#profile` -> profile + friends + requests
- `#reports` -> reports list (mod only)
- `#badges` -> badges
- `#search/{query}` -> global search

## 8) If you want to reuse this elsewhere

Minimum pieces to copy:

1. Hidden/API config (`apiUrl`, `portalKey`)
2. `getApiUrl`, `getHeaders`, `api` helper
3. Token persistence (`portalSessionToken` in localStorage)
4. Startup flow (`loadPortalInfo` -> `validateSession` -> route handler)
5. Route-specific loaders and endpoint calls above
6. OAuth redirect + callback hash handling

If you keep those pieces, the same backend contract will work in another frontend.