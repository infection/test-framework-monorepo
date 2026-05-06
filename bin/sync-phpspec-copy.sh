#!/usr/bin/env bash

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly SOURCE_DIR="${ROOT_DIR}/sources/phpspec-adapter/tests/e2e/PhpSpec"
readonly TARGET_DIR="${ROOT_DIR}/tests/PhpSpec"
readonly HASH_FILE="${TARGET_DIR}/source.hash"

EXCLUDES=(
    "composer.lock"
    "$(basename "${HASH_FILE}")"
    "vendor"
)
readonly EXCLUDES

source_hash() {
    (
        cd "${SOURCE_DIR}"

        find . -type f -print0 \
            | LC_ALL=C sort -z \
            | xargs -0 shasum -a 256 \
            | shasum -a 256 \
            | cut -d " " -f 1
    )
}

configure_composer_json() {
    (
        cd "${TARGET_DIR}"

        composer config --unset repositories.phpspec-adapter || true
        composer config --unset repositories.infection || true
        composer config repositories.phpspec-adapter '{"type":"path","url":"../../sources/phpspec-adapter","options":{"versions":{"infection/phpspec-adapter":"0.3.99"}}}'
        composer config repositories.infection '{"type":"path","url":"../../sources/infection","options":{"symlink":true,"versions":{"infection/infection":"0.32.99"}}}'
        composer config --json 'allow-plugins.infection/extension-installer' true
        composer require --dev --no-update --no-interaction infection/phpspec-adapter || true
        composer require --dev --no-update --no-interaction 'infection/infection:^0.32.6'
    )
}

sync_copy() {
    local actual_hash
    local exclude_args=()
    local exclude
    local expected_hash

    for exclude in "${EXCLUDES[@]}"; do
        exclude_args+=("--exclude=${exclude}")
    done

    expected_hash="$(source_hash)"

    if [[ -f "${HASH_FILE}" ]]; then
        actual_hash="$(< "${HASH_FILE}")"

        if [[ "${actual_hash}" == "${expected_hash}" ]]; then
            configure_composer_json
            return
        fi
    fi

    rsync \
        --archive \
        --delete \
        "${exclude_args[@]}" \
        "${SOURCE_DIR}/" \
        "${TARGET_DIR}/"

    configure_composer_json
    echo "${expected_hash}" > "${HASH_FILE}"
}

sync_copy
