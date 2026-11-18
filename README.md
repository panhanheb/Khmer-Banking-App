# Khmer Digital Bank

Digital banking for Cambodia — Khmer / English, USD / KHR.

| Part | Location | Stack |
|---|---|---|
| Mobile app | [`lib/`](lib/) | Flutter, BLoC, go_router, Dio, get_it |
| Backend API | [`backend/`](backend/) | Java 21, Spring Boot 3, PostgreSQL, Redis, Flyway, JWT |
| Admin dashboard | — | Phase 9 (planned) |

**Docs:** [Architecture & roadmap](docs/ARCHITECTURE.md) · [Database / ER](docs/DATABASE.md) ·
[REST API](docs/API.md) · [Setup, testing & deployment](docs/SETUP.md)

> ⚠️ This project does **not** have KHQR / Bakong, card-network, biller or telco connectivity.
> Those integrations are defined as interfaces and require licensed, authorized credentials.
> Money added through the dev-only deposit endpoint is **SIMULATED** and flagged as such.

Quick start: `cp .env.example .env`, fill in secrets, `docker compose up --build`, then
`flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1`.

The older coupon/promotion demo screens remain under `lib/coupon`, `lib/coins`, `lib/store`, etc.
