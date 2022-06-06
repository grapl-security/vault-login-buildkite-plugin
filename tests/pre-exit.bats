#!/usr/bin/env bats

load "$BATS_PLUGIN_PATH/load.bash"

# Uncomment to enable stub debugging
# export DOCKER_STUB_DEBUG=/dev/tty

setup() {
    # TODO: These two variable values duplicate stuff from vault.sh;
    # split things up better
    export DEFAULT_IMAGE=hashicorp/vault
    export DEFAULT_TAG=latest

    export BUILDKITE_AGENT_META_DATA_QUEUE=default

    export VAULT_ADDR=default.vault.mycompany.com:8200
    export VAULT_NAMESPACE=default_namespace
}

teardown() {
    unset VAULT_ADDR
    unset VAULT_NAMESPACE
    unset BUILDKITE_AGENT_META_DATA_QUEUE
    unset BUILDKITE_PLUGIN_VAULT_LOGIN_ADDRESS
    unset BUILDKITE_PLUGIN_VAULT_LOGIN_NAMESPACE
    unset BUILDKITE_PLUGIN_VAULT_LOGIN_IMAGE
    unset BUILDKITE_PLUGIN_VAULT_LOGIN_TAG
}

@test "When missing a VAULT_TOKEN, do nothing" {
    unset VAULT_TOKEN

    run "${PWD}/hooks/pre-exit"

    assert_output --partial "No 'VAULT_TOKEN' found in the environment; skipping revocation"
    assert_success
}

@test "When VAULT_TOKEN is present, revoke the token" {
    export VAULT_TOKEN="THIS_IS_A_PRETEND_VAULT_TOKEN"

    stub docker \
         "run --init --rm --env=SKIP_SETCAP=true --env=VAULT_ADDR=${VAULT_ADDR} --env=VAULT_NAMESPACE=${VAULT_NAMESPACE} --env=VAULT_TOKEN -- ${DEFAULT_IMAGE}:${DEFAULT_TAG} token revoke -self : echo 'Success! Revoked token (if it existed)'"

    run "${PWD}/hooks/pre-exit"

    assert_output --partial "Success! Revoked token (if it existed)"
    assert_success

    unstub docker
}
