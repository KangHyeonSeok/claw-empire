#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
RUNTIME_DIR="${ROOT_DIR}/deploy/docker/runtime"
HEX_BYTES="${HEX_BYTES:-32}"

if ! command -v openssl >/dev/null 2>&1; then
  echo "[docker-fleet:secrets] openssl is required." >&2
  exit 1
fi

if [[ ! -d "${RUNTIME_DIR}" ]]; then
  echo "[docker-fleet:secrets] runtime directory not found: ${RUNTIME_DIR}" >&2
  exit 1
fi

shopt -s nullglob
files=("${RUNTIME_DIR}"/*.env)
shopt -u nullglob

if [[ ${#files[@]} -eq 0 ]]; then
  echo "[docker-fleet:secrets] no runtime env files found in ${RUNTIME_DIR}" >&2
  exit 1
fi

generate_hex() {
  openssl rand -hex "${HEX_BYTES}"
}

replace_file() {
  local file="$1"
  local tmp_file
  local changed=0

  tmp_file="$(mktemp)"

  while IFS= read -r line || [[ -n "${line}" ]]; do
    if [[ "${line}" =~ ^([A-Z0-9_]+)=CHANGE_ME[A-Z0-9_]*$ ]]; then
      local key="${BASH_REMATCH[1]}"
      printf '%s=%s\n' "${key}" "$(generate_hex)" >>"${tmp_file}"
      changed=1
    else
      printf '%s\n' "${line}" >>"${tmp_file}"
    fi
  done <"${file}"

  mv "${tmp_file}" "${file}"

  if [[ ${changed} -eq 1 ]]; then
    echo "[docker-fleet:secrets] updated $(basename "${file}")"
  else
    echo "[docker-fleet:secrets] no placeholders in $(basename "${file}")"
  fi
}

for file in "${files[@]}"; do
  replace_file "${file}"
done
