#!/usr/bin/env bash

set -euo pipefail

log() {
  LEVEL="$1"
  shift
  TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
  printf "[%s] [%s] %s\n" "$TIMESTAMP" "$LEVEL" "$*"
}

# Required variables
BASE_URL=${BASE_URL:?'BASE_URL variable missing.'}
MARTINI_ACCESS_TOKEN=${MARTINI_ACCESS_TOKEN:?'MARTINI_ACCESS_TOKEN variable missing.'}
PACKAGE_DIR=${PACKAGE_DIR:-'packages'}
PACKAGE_NAME_PATTERN=${PACKAGE_NAME_PATTERN:-'.*'}
ASYNC_UPLOAD=${ASYNC_UPLOAD:-false}
SUCCESS_CHECK_TIMEOUT=${SUCCESS_CHECK_TIMEOUT:-6}
SUCCESS_CHECK_DELAY=${SUCCESS_CHECK_DELAY:-30}
SUCCESS_CHECK_PACKAGE_NAME=${SUCCESS_CHECK_PACKAGE_NAME:-''}

# Remove trailing slash from BASE_URL if present
BASE_URL="${BASE_URL%/}"

log INFO "BASE_URL: $BASE_URL"
log INFO "PACKAGE_DIR: $PACKAGE_DIR"
log INFO "PACKAGE_NAME_PATTERN: $PACKAGE_NAME_PATTERN"
log INFO "ASYNC_UPLOAD: $ASYNC_UPLOAD"

if [ "$ASYNC_UPLOAD" = "true" ]; then
  log INFO "SUCCESS_CHECK_TIMEOUT: $SUCCESS_CHECK_TIMEOUT"
  log INFO "SUCCESS_CHECK_DELAY: $SUCCESS_CHECK_DELAY"
  log INFO "SUCCESS_CHECK_PACKAGE_NAME: $SUCCESS_CHECK_PACKAGE_NAME"
fi

HOST=$(printf "%s" "$BASE_URL" | awk -F/ '{print $3}')
if ! getent hosts "$HOST" > /dev/null; then
  log ERROR "Cannot resolve host $HOST"
  exit 1
fi

if [ ! -d "$PACKAGE_DIR" ]; then
  log ERROR "$PACKAGE_DIR directory does not exist."
  exit 1
fi

if [ -z "$(ls -A "$PACKAGE_DIR")" ]; then
  log ERROR "$PACKAGE_DIR is empty. No packages to upload."
  exit 1
fi

should_process_package() {
  echo "$1" | grep -Eq "$PACKAGE_NAME_PATTERN"
}

MATCHING_PACKAGES=()
for dir in "$PACKAGE_DIR"/*; do
  if [ -d "$dir" ]; then
    PACKAGE_NAME=$(basename "$dir")
    if should_process_package "$PACKAGE_NAME"; then
      MATCHING_PACKAGES+=("$PACKAGE_NAME")
    fi
  fi
done

if [ ${#MATCHING_PACKAGES[@]} -eq 0 ]; then
  log INFO "No matching packages to upload."
  exit 0
fi

FINAL_ZIP="packages.zip"
log INFO "Zipping packages: ${MATCHING_PACKAGES[*]}"
(cd "$PACKAGE_DIR" && zip -qr "../$FINAL_ZIP" "${MATCHING_PACKAGES[@]}")
log INFO "Created zip: $FINAL_ZIP"

upload_package() {
  local upload_url="${BASE_URL}/esbapi/packages/upload?stateOnCreate=STARTED&replaceExisting=true"
  log INFO "Uploading packages to: $upload_url"

  response=$(curl --progress-bar \
    -w "%{http_code}" \
    -o response_body.log \
    "$upload_url" \
    -H "accept:application/json" \
    -F "file=@${FINAL_ZIP};type=application/zip" \
    -H "Authorization:Bearer $MARTINI_ACCESS_TOKEN")

  http_code="${response: -3}"

  if [ "$ASYNC_UPLOAD" = "true" ] && { [ "$http_code" = "504" ] || { [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; }; }; then
    log INFO "Async upload accepted (HTTP $http_code)"
  elif [ "$ASYNC_UPLOAD" = "false" ] && [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
    log INFO "Upload successful (HTTP $http_code)"
    cat response_body.log
    exit 0
  else
    log ERROR "Upload failed with HTTP $http_code"
    cat response_body.log
    exit 1
  fi
}
upload_package

check_package_started() {
  local package_name="$1"
  local attempts=0

  while [ "$attempts" -lt "$SUCCESS_CHECK_TIMEOUT" ]; do
    response=$(curl -s -X GET "${BASE_URL}/esbapi/packages/${package_name}?version=2" \
      -H "accept:application/json" \
      -H "Authorization:Bearer $MARTINI_ACCESS_TOKEN")

    if printf "%s" "$response" | jq -e . >/dev/null 2>&1; then
      status=$(echo "$response" | jq -r '.status')
      if [ "$status" = "STARTED" ]; then
        log INFO "Package '$package_name' started successfully"
        printf "%s\n" "$response" >> results.log
        return 0
      fi
    fi

    log INFO "Waiting for $package_name... ($((attempts+1))/$SUCCESS_CHECK_TIMEOUT)"
    sleep "$SUCCESS_CHECK_DELAY"
    attempts=$((attempts+1))
  done

  log ERROR "Package '$package_name' did not start in time"
  printf "Package '%s' timed out\n" "$package_name" >> results.log
  return 1
}

log INFO "Polling for package start status..."

failures=0
if [ -n "$SUCCESS_CHECK_PACKAGE_NAME" ]; then
  check_package_started "$SUCCESS_CHECK_PACKAGE_NAME" || failures=$((failures+1))
else
  pids=()
  for package in "${MATCHING_PACKAGES[@]}"; do
    check_package_started "$package" &
    pids+=("$!")
  done

  for pid in "${pids[@]}"; do
    wait "$pid" || failures=$((failures+1))
  done
fi

if [ "$failures" -ne 0 ]; then
  log ERROR "One or more packages failed to start."
  exit 1
fi

log INFO "Done polling for package startup:"
cat results.log

exit 0
