#!/usr/bin/env bash

set -euo pipefail

readonly default_image="hashicorp/vault"
readonly default_tag="latest"
# TODO: add a "debug" mode where we spit out the specific image and
# commands being used
readonly image="${BUILDKITE_PLUGIN_VAULT_LOGIN_IMAGE:-${default_image}}:${BUILDKITE_PLUGIN_VAULT_LOGIN_TAG:-${default_tag}}"

# VAULT_ADDR="https://vault-cluster.private.vault.b3b89729-5226-4b15-8c8a-b42572e88e7c.aws.hashicorp.cloud:8200"
# readonly VAULT_ADDR
# export VAULT_ADDR
# VAULT_NAMESPACE="admin/buildkite"
# readonly VAULT_NAMESPACE
# export VAULT_NAMESPACE

# --cap-add IPC_LOCK is required to prevent silly error messages from
# polluting stdout
#
# Rather than that, just don't use --interactive / -tty

# --tty adds in the ANSI control characters we don't want
# --interactive seems control the stderr/stdout conflation
vault() {
    docker run \
        --init \
        --rm \
        --cap-add IPC_LOCK \
        --env=VAULT_ADDR \
        --env=VAULT_NAMESPACE \
        --env=VAULT_TOKEN \
        -- \
        "${image}" "$@"
}
