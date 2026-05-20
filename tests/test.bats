#!/usr/bin/env bats

# bats test for ddev-supabase addon

setup() {
  set -eu -o pipefail
  export DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." >/dev/null 2>&1 && pwd)"
  export TESTDIR=~/tmp/test-ddev-supabase
  mkdir -p $TESTDIR
  export PROJNAME=test-ddev-supabase
  export DDEV_NON_INTERACTIVE=true
  ddev delete -Oy $PROJNAME >/dev/null 2>&1 || true
  cd "$TESTDIR"
  ddev config --project-name=$PROJNAME --project-type=php
  ddev start -y >/dev/null
}

health_checks() {
  # Wait for Supabase to be ready (it takes a while to start)
  echo "Waiting for Supabase services to be ready..."
  for i in $(seq 1 30); do
    if curl -sf http://localhost:8000/health >/dev/null 2>&1; then
      echo "Supabase API is ready"
      break
    fi
    sleep 10
  done

  # Check Kong (API gateway) is accessible
  run curl -sf -o /dev/null -w "%{http_code}" http://localhost:8000/health
  # Kong returns 200 on /health or redirects to Studio - either is fine
  [ "$status" -eq 0 ]

  # Check Studio is serving (basic auth protected, so we expect 401)
  run curl -sf -o /dev/null -w "%{http_code}" http://localhost:8000/
  [ "$output" = "401" ] || [ "$output" = "200" ]

  # Check PostgREST endpoint is accessible
  run curl -sf -o /dev/null -w "%{http_code}" \
    -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE" \
    http://localhost:8000/rest/v1/
  [ "$output" = "200" ]

  # Check Supavisor postgres port is listening
  run nc -z localhost 54322
  [ "$status" -eq 0 ]
}

teardown() {
  set -eu -o pipefail
  cd ${TESTDIR} || (printf "unable to cd to ${TESTDIR}\n" && exit 1)
  ddev delete -Oy $PROJNAME >/dev/null 2>&1
  [ "${TESTDIR}" != "" ] && rm -rf ${TESTDIR}
}

@test "install from directory" {
  set -eu -o pipefail
  cd ${TESTDIR}
  echo "# ddev add-on get ${DIR}" >&3
  ddev add-on get ${DIR}
  ddev restart >/dev/null
  health_checks
}

# bats test_tags=release
@test "install from release" {
  set -eu -o pipefail
  cd ${TESTDIR}
  echo "# ddev add-on get Farkie/ddev-supabase" >&3
  ddev add-on get Farkie/ddev-supabase
  ddev restart >/dev/null
  health_checks
}
