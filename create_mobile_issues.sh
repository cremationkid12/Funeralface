#!/usr/bin/env bash
set -euo pipefail

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) is required."
  exit 1
fi

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <owner/repo>"
  echo "Example: $0 your-org/funeralface-mobile"
  exit 1
fi

REPO="$1"

echo "Creating mobile issues in $REPO..."

gh issue create -R "$REPO" \
  --title "[Mobile] Flutter foundation: flavors, API client, and architecture" \
  --label "mobile,testing" \
  --body "$(cat <<'EOF'
## Description
Create Flutter app foundation for REST integration with environment-aware configuration.

## Scope
- `dev/staging/prod` flavors
- `API_BASE_URL` via `--dart-define`
- Shared API client + error mapping
- App routing and DI foundation

## Tasks
- [ ] Configure Flutter flavors.
- [ ] Implement environment config loader.
- [ ] Build shared API client layer.
- [ ] Add dependency injection and base navigation scaffold.
- [ ] Add baseline test setup for unit/widget tests.

## Test Checklist
- [ ] Unit tests for flavor/base URL selection.
- [ ] Widget test for app boot with mocked API.
- [ ] API error mapping tests.

## Acceptance Criteria (DoD)
- App can target staging/prod without code changes.
- Foundational architecture and tests are in place.
EOF
)"

gh issue create -R "$REPO" \
  --title "[Mobile] Verified deep links (App Links + Universal Links) for family token flow" \
  --label "mobile,security,testing" \
  --body "$(cat <<'EOF'
## Description
Implement verified deep-link handling for family token links with in-app-only routing and strict host/path allowlisting.

## Scope
- Android App Links (`autoVerify`, intent filters)
- iOS Universal Links (Associated Domains)
- Strict parser for expected host/path
- In-app routing only for token flows
- Safe rejection of unverified/malformed links

## Tasks
- [ ] Configure Android verified links.
- [ ] Configure iOS associated domains.
- [ ] Build deep-link parsing + allowlist validation.
- [ ] Route verified links to family token flow.
- [ ] Add safe fallback screen for invalid links.

## Test Checklist
- [ ] Verified links open app directly on Android and iOS.
- [ ] Unverified host/path is rejected.
- [ ] Malformed token link is safely rejected.
- [ ] Cold-start and warm-start deep-link behavior verified.

## Acceptance Criteria (DoD)
- Family links are handled only through verified app link mechanisms.
- Untrusted links do not expose data or navigate to sensitive views.
EOF
)"

gh issue create -R "$REPO" \
  --title "[Mobile] Feature parity delivery with test-per-step policy" \
  --label "mobile,testing" \
  --body "$(cat <<'EOF'
## Description
Deliver Flutter feature parity for Dashboard, Assignments, Staff, Settings, and Family View using REST endpoints and verified deep links.

## Scope
- Dashboard data and summaries
- Assignments list/detail/status updates
- Staff list/forms/invite
- Settings read/update/upload
- Family token flow screen

## Tasks
- [ ] Implement Dashboard feature module.
- [ ] Implement Assignments feature module.
- [ ] Implement Staff feature module.
- [ ] Implement Settings feature module.
- [ ] Implement Family View module from deep-link token.
- [ ] Add fixture-driven API tests for all modules.
- [ ] Add OpenAPI sync procedure in mobile CI/docs.

## Test Checklist
- [ ] At least one automated test for each feature module.
- [ ] Widget/integration coverage for critical user paths.
- [ ] API fixture tests catch response shape regressions.
- [ ] End-to-end family token happy path passes on staging.

## Acceptance Criteria (DoD)
- All priority screens function against staging REST backend.
- Test-per-step policy is met and verified in PRs.
- CI is green for mobile release candidate build.
EOF
)"

echo "Done. Mobile issues created in $REPO."
