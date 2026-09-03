# Example — filled Project map / Project facts

Calibration for the density and shape the slots expect. Captured on 2026-08-31 from two real repos
(`api-gateway` — Bun unit tests, consumer-side surface; `web-app/e2e-tests` — pytest + Playwright,
native surface); the **System boundaries** block and its debt were captured on 2026-09-02 with
`--section mock-targets`. Repo names, vendor names and product-specific identifiers are
placeholders — structure, counts, commands and shapes are as captured. Every run, formatter and
discovery command below ran and returned output on that day. The E2E preflight block shows the
expected shape: at capture time the app was down (`curl` failed) — exactly the state a preflight
exists to catch, so it was recorded, not skipped. Entries marked *(chosen at install)* are role
decisions the user made when asked — illustrative, not prescriptive for your project.

> Your project's real map is not this file. It is rendered into that project's own
> `.claude/agents/` at install time, from discovery run against that repo.

---

## 1. `unit-test-author` Project map — api-gateway (Bun)

**Framework & run commands**
- Single file: `bun test --isolate tests/<name>.test.ts`
- Full suite: `bun test --isolate`
- Formatter: `bunx biome format --write <files>` (the `format` script covers `src tests`)
- `--isolate` is mandatory: plain `bun test` produces false `mock.module` pollution failures across files.
- `bunfig.toml` preloads `tests/test-env.ts`, which strips every var defined in `.env*` and forces the test fixtures (`=`, not `??=`) — a spec that "sees" a real value is reading the shell, not the file.

**Test root & layout**: flat `tests/*.test.ts` (101 files), no mirroring of `src/`; one file per route/service/plugin under test.

**Shared homes by role** (canonical — one path per role)
- Module mocks: `tests/helpers/` (`mock-supabase.ts`, `mock-payments.ts`)
- Helpers / wrappers: `tests/helpers/`
- Factories (data builders): none yet → `tests/factories/` *(chosen at install; 34 test files define local `make*`/`build*` builders — see debt)*
- Fixtures (static inputs): `tests/fixtures/` (`payments/cert.pem`, `payments/key.pem`)

**System boundaries** (the only things a unit test mocks — what it is → the shared mock that replaces it)
- Supabase (`@supabase/supabase-js`, wrapped by `src/services/supabase` and `supabase-internal`) → `buildMockSupabaseFactory(opts)` in `tests/helpers/mock-supabase.ts`, module registration via `makeSupabaseModuleRegistrars()` in `tests/helpers/mock-supabase-modules.ts`
- RabbitMQ (`amqplib`, wrapped by `src/services/rabbitmq`) → `installAmqpMock()` / `makeFakeChannel()` in `tests/helpers/mock-amqp.ts`
- The two payment-provider HTTP APIs (global `fetch`, wrapped by `src/lib/http-client`) → `setupPaymentsMock()` in `tests/helpers/mock-payments.ts`
- Redis (`ioredis`, wrapped by `src/services/redis`) → none yet → create at `tests/helpers/mock-redis.ts` *(mocked inline in 25 files — see debt)*
- JWKS (`jose`, wrapped by `src/lib/jwks`) → none yet → create at `tests/helpers/mock-jwks.ts` *(mocked inline in 19 files — see debt)*
- The clock → `withFrozenDate(iso, fn)` in `tests/helpers/with-frozen-date.ts`

**Discovery — run all of these on every dispatch, before writing**
```
bash .claude/testing-policy/scan-test-assets.sh --root tests --shared tests/helpers --shared tests/fixtures --section duplicate-symbols
bash .claude/testing-policy/scan-test-assets.sh --root tests --shared tests/helpers --shared tests/fixtures --section local-factories
grep -nE "^export (async )?function" tests/helpers/*.ts
```

**Idiom** (calibration only — never a catalog)
- Identifiers in English (same as the code policy). Module seams are replaced with `mock.module()` from `bun:test` (65 of 101 files); app instances are built per test with a local `makeApp()`/`buildApp()` that mounts the route under test with mocked plugins.
- Well-shaped shared assets: `withFrozenDate<T>(iso: string, fn: () => T): T` (`tests/helpers/with-frozen-date.ts`) · `setupPaymentsMock(): PaymentsMockHandle` (`tests/helpers/mock-payments.ts`) · `buildMockSupabaseFactory(opts: MockSupabaseOptions)` (`tests/helpers/mock-supabase.ts`).

**Debt found at install** (reported, not fixed — the second-use rule pays it)
- `makeApp` defined locally in 9 files, `buildApp` in 9, `makeFakeChannel`/`fakeChannel`/`fakeConn`/`fakeConsumeChannel` in 4 each, `makeFakeMsg` in 3, `buildValidSignaturePng`/`makeRequest`/`makeRow` in 2 each.
- `describe.skip(...)` at `tests/subscription-pay-credit-card.test.ts:494`.
- Boundaries mocked inline with no shared mock: `../src/services/redis` in 25 files, `../src/lib/jwks` in 19 — the next author needing either creates the shared mock and promotes.
- Internal collaborators mocked (a seam is the fix, the next time each test is touched): `../src/services/payments/token` in 12 files, `../src/services/payments/index` in 6, `../src/services/payments/invoices` in 4, `../src/services/payments/pix-invoice` and `pix-status` in 3 each, `../src/services/invoices` in 2, `../src/services/open-invoices`, `../src/middleware/audit`, `../src/services/web-app` in 1 each — all modules with no external import of their own, sitting behind `src/lib/http-client`.

---

## 2. `e2e-test-author` Project map — web-app (pytest + Playwright)

**Tool & run commands**
- Single flow: `cd e2e-tests && pytest client_tests/test_<flow>.py` (`base_url` defaults to `http://localhost:3000` via `pytest.ini`)
- Full suite (delivery gate — not yours to run): `pnpm test:e2e:remote` (remote runner; CI runs the same suite on PRs)
- Formatter / linter: `cd e2e-tests && ruff check --fix <file> && ruff format <file>` (ruff pinned in `requirements.txt`, config in `pyproject.toml`)
- Working directory is `e2e-tests/`; the `.venv` there holds pytest/playwright/ruff. `pytest-xdist` is installed — flows share one seeded database, so do not add `-n` on your own.

**Preflight — every check must pass before running**
```
curl -fsS http://localhost:3000/api/health
supabase status
docker compose -f docker-compose.dev.yml ps --status running
```
(third line: the app's compose stack; the gateway it talks to is brought up from `../api-gateway` by `pnpm docker:dev:gateway` — a gateway that is down shows up as a red flow, not as an infra error.)

**Flow root & naming**: `e2e-tests/<area>_tests/test_<journey>_<outcome>.py` — e.g. `client_tests/test_add_new_client_subscription_boleto_successful.py`, `client_tests/test_webhook_cancel_does_not_mark_invoice_paid.py`, `client_tests/test_pix_emission_and_reemission.py`.

**Shared homes by role** (canonical — one path per role)
- Page objects / interactions: `e2e-tests/pages/` (base class `CommonPage`)
- Data factories (entity builders): `e2e-tests/data/` (`clients_data.py`)
- Backend / DB helpers (fixture state, direct assertions): `e2e-tests/data/*_db.py` (`clients_db.py`, `invoices_db.py`, `db_cleanup.py`, ...) — same directory as the factories, two roles
- Fixtures (session, context, cleanup): `e2e-tests/conftest.py`

**Discovery — run all of these on every dispatch, before writing**
```
bash .claude/testing-policy/scan-test-assets.sh --root e2e-tests --flows e2e-tests --shared e2e-tests/pages --shared e2e-tests/data --section duplicate-symbols
bash .claude/testing-policy/scan-test-assets.sh --root e2e-tests --flows e2e-tests --shared e2e-tests/pages --shared e2e-tests/data --section inline-helpers
grep -nE "^\s+def [a-z_]+\(self" e2e-tests/pages/*.py
grep -nE "^def |^@pytest.fixture" e2e-tests/data/*.py e2e-tests/conftest.py
```

**Idiom** (calibration only — never a catalog)
- Page objects and fixtures use English identifiers; data factories use pt-BR names (`novo_cliente_pf(**overrides)`, `novo_cliente_pj(**overrides)`) — keep each tree's convention, the code policy does not apply here.
- Locators: `page.get_by_role(...)` dominates (126 uses vs 13 `page.locator(...)`); a new method uses a role/label locator unless the DOM offers none.
- Well-shaped shared assets: `ClientPage(CommonPage).create_new_client(self, client_data=None)` · `CommonPage.expect_text(self, text, exact=False)` · fixture `admin_page(browser, admin_storage, base_url, browser_context_args)` yielding a logged-in page · `purge_clients(client_ids: list[str]) -> None` (`data/db_cleanup.py`).

**Debt found at install**
- `class ClientPage(CommonPage)` is defined in both `pages/client_page.py:9` and `pages/invoices_page.py:9` — a fork; the next author needing either consolidates first.

---

## 3. Project facts — api-gateway (consumer-side surface)

- **Unit**: full suite `bun test --isolate` · single file `bun test --isolate tests/<name>.test.ts` · mandatory flags / known phantom failures: `--isolate` is mandatory (plain `bun test` gives false `mock.module` pollution failures); `tests/test-env.ts` preload strips `.env*` and forces fixtures · skip mechanisms: `test.skip` / `describe.skip` / `.only`
- **Consumers** — one line each: repo · E2E tool · run against this repo's local build · single flow · full suite · flow naming · known infra failures
  - `web-app` · pytest + Playwright · its local stack builds this gateway from the working tree via `pnpm docker:dev:gateway` (→ `bun run --cwd ../api-gateway docker:dev -- -d`) · `cd e2e-tests && pytest <area>_tests/test_<flow>.py` · `pnpm test:e2e:remote` · `e2e-tests/<area>_tests/test_<journey>_<outcome>.py` · remote runner unreachable, gateway container down, Supabase stack won't come up, app never becomes ready
  - `mobile-app` · Maestro · `E2E_COMPOSE_OVERRIDE=docker-compose.e2e.local.yml` (`pull_policy: never`) keeps the stack on the locally built gateway image · `E2E_FLOWS=".maestro/<flow>.yaml" pnpm test:e2e` · `pnpm test:e2e:remote` · `.maestro/<area>-<scenario>.yaml` · emulator died, stack won't come up, runner lagging
- **Duplication scan**: `bash .claude/testing-policy/scan-test-assets.sh --root tests --shared tests/helpers --shared tests/fixtures` · shared homes per role: the agents' Project map
- **Why the agents run in place**: the consumers' E2E stacks build this repo from the primary checkout's working tree; a worktree build would test the wrong code.
