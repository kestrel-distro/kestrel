#!/bin/bash

source "$(dirname "$0")/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

mock_bin="$test_tmp/bin"
mkdir -p "$mock_bin" "$test_tmp/home"

cat >"$mock_bin/kestrel-done" <<'SH'
#!/bin/bash
[[ $1 == "check" && $2 == "first-run-user" ]]
SH
cat >"$mock_bin/kestrel-provision-user" <<'SH'
#!/bin/bash
touch "$KESTREL_TEST_FINALIZE_CALLED"
SH
chmod +x "$mock_bin/kestrel-done" "$mock_bin/kestrel-provision-user"

finalize_called="$test_tmp/finalize-called"
HOME="$test_tmp/home" PATH="$mock_bin:$PATH" KESTREL_TEST_FINALIZE_CALLED="$finalize_called" \
  bash "$ROOT/bin/kestrel-provision-first-run" >"$test_tmp/output"

[[ ! -e $finalize_called ]] || fail "completed first-run exits before any setup step"
grep -F 'First-run already complete' "$test_tmp/output" >/dev/null || fail "completed first-run reports its lifecycle gate"

pass "first-run uses one lifecycle completion marker"
