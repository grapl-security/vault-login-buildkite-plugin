#!/usr/bin/env bats

load "$BATS_PATH/load.bash"

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

@test "VAULT_ADDR and VAULT_NAMESPACE are accepted in the absence of explicit overrides" {
    [ -n "${VAULT_ADDR}" ]
    unset BUILDKITE_PLUGIN_VAULT_LOGIN_ADDRESS
    [ -n "${VAULT_NAMESPACE}" ]
    unset BUILDKITE_PLUGIN_VAULT_LOGIN_NAMESPACE

    stub docker \
         "run --init --rm --cap-add IPC_LOCK --env=VAULT_ADDR=${VAULT_ADDR} --env=VAULT_NAMESPACE=${VAULT_NAMESPACE} -- ${DEFAULT_IMAGE}:${DEFAULT_TAG} login -method=aws -token-only role=default : echo 'THIS_IS_YOUR_VAULT_TOKEN'"

    run "${PWD}/hooks/environment"
    assert_success

    unstub docker
}

@test "VAULT_ADDR is overridden in the presence of an explicitly configured address" {
    export BUILDKITE_PLUGIN_VAULT_LOGIN_ADDRESS=override.vault.mycompany.com:8200

    stub docker \
         "run --init --rm --cap-add IPC_LOCK --env=VAULT_ADDR=override.vault.mycompany.com:8200 --env=VAULT_NAMESPACE=${VAULT_NAMESPACE} -- ${DEFAULT_IMAGE}:${DEFAULT_TAG} login -method=aws -token-only role=default : echo 'THIS_IS_YOUR_VAULT_TOKEN'"

    run "${PWD}/hooks/environment"
    assert_success

    unstub docker
}

@test "Missing both VAULT_ADDR and explicitly configured address is a failure" {
    unset VAULT_ADDR
    unset BUILDKITE_PLUGIN_VAULT_LOGIN_ADDRESS

    run "${PWD}/hooks/environment"
    assert_output --partial "Could not find 'VAULT_ADDR' in the environment, and 'BUILDKITE_PLUGIN_VAULT_LOGIN_ADDRESS' was not specified!"

    assert_failure

}

@test "VAULT_NAMESPACE is overridden in the presence of an explicitly configured namespace" {
    export BUILDKITE_PLUGIN_VAULT_LOGIN_NAMESPACE=override_namespace

    stub docker \
         "run --init --rm --cap-add IPC_LOCK --env=VAULT_ADDR=${VAULT_ADDR} --env=VAULT_NAMESPACE=override_namespace -- ${DEFAULT_IMAGE}:${DEFAULT_TAG} login -method=aws -token-only role=default : echo 'THIS_IS_YOUR_VAULT_TOKEN'"

    run "${PWD}/hooks/environment"
    assert_success

    unstub docker
}

@test "Missing VAULT_NAMESPACE and an explicitly configured namespace is a failure" {
    unset VAULT_NAMESPACE
    unset BUILDKITE_PLUGIN_VAULT_LOGIN_NAMESPACE

    run "${PWD}/hooks/environment"
    assert_output --partial "Could not find 'VAULT_NAMESPACE' in the environment, and 'BUILDKITE_PLUGIN_VAULT_LOGIN_NAMESPACE' was not specified!"

    assert_failure
}

@test "The image can be overridden" {
    export BUILDKITE_PLUGIN_VAULT_LOGIN_IMAGE=mycompany/vault

    stub docker \
         "run --init --rm --cap-add IPC_LOCK --env=VAULT_ADDR=${VAULT_ADDR} --env=VAULT_NAMESPACE=${VAULT_NAMESPACE} -- mycompany/vault:${DEFAULT_TAG} login -method=aws -token-only role=default : echo 'THIS_IS_YOUR_VAULT_TOKEN'"

    run "${PWD}/hooks/environment"
    assert_success

    unstub docker
}

@test "The image tag can be overridden" {
    export BUILDKITE_PLUGIN_VAULT_LOGIN_TAG=v1.2.3

    stub docker \
         "run --init --rm --cap-add IPC_LOCK --env=VAULT_ADDR=${VAULT_ADDR} --env=VAULT_NAMESPACE=${VAULT_NAMESPACE} -- ${DEFAULT_IMAGE}:v1.2.3 login -method=aws -token-only role=default : echo 'THIS_IS_YOUR_VAULT_TOKEN'"

    run "${PWD}/hooks/environment"
    assert_success

    unstub docker
}

@test "Image and tag can be overridden simultaneously" {
    export BUILDKITE_PLUGIN_VAULT_LOGIN_IMAGE=mycompany/vault
    export BUILDKITE_PLUGIN_VAULT_LOGIN_TAG=v1.2.3

    stub docker \
         "run --init --rm --cap-add IPC_LOCK --env=VAULT_ADDR=${VAULT_ADDR} --env=VAULT_NAMESPACE=${VAULT_NAMESPACE} -- mycompany/vault:v1.2.3 login -method=aws -token-only role=default : echo 'THIS_IS_YOUR_VAULT_TOKEN'"

    run "${PWD}/hooks/environment"
    assert_success

    unstub docker
}

@test "A queue name with a slash is converted to the proper authentication role name" {
    export BUILDKITE_AGENT_META_DATA_QUEUE=default/testing

    stub docker \
         "run --init --rm --cap-add IPC_LOCK --env=VAULT_ADDR=${VAULT_ADDR} --env=VAULT_NAMESPACE=${VAULT_NAMESPACE} -- ${DEFAULT_IMAGE}:${DEFAULT_TAG} login -method=aws -token-only role=default-testing : echo 'THIS_IS_YOUR_VAULT_TOKEN'"

    run "${PWD}/hooks/environment"
    assert_success

    unstub docker

}
