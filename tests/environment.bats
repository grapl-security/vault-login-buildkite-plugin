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
    unset BUILDKITE_AGENT_META_DATA_QUEUE
    unset BUILDKITE_PLUGIN_VAULT_LOGIN_ADDRESS
    unset BUILDKITE_PLUGIN_VAULT_LOGIN_ALWAYS_PULL
    unset BUILDKITE_PLUGIN_VAULT_LOGIN_AUTH_ROLE
    unset BUILDKITE_PLUGIN_VAULT_LOGIN_IMAGE
    unset BUILDKITE_PLUGIN_VAULT_LOGIN_NAMESPACE
    unset BUILDKITE_PLUGIN_VAULT_LOGIN_ATTEMPT_COUNT
    unset BUILDKITE_PLUGIN_VAULT_LOGIN_ATTEMPT_WAIT_SECONDS
    unset BUILDKITE_PLUGIN_VAULT_LOGIN_TAG
    unset VAULT_ADDR
    unset VAULT_NAMESPACE
}

@test "VAULT_ADDR and VAULT_NAMESPACE are accepted in the absence of explicit overrides" {
    [ -n "${VAULT_ADDR}" ]
    unset BUILDKITE_PLUGIN_VAULT_LOGIN_ADDRESS
    [ -n "${VAULT_NAMESPACE}" ]
    unset BUILDKITE_PLUGIN_VAULT_LOGIN_NAMESPACE

    docker_vault_cmd="run --init --rm --env=SKIP_SETCAP=true --env=VAULT_ADDR=${VAULT_ADDR} --env=VAULT_NAMESPACE=${VAULT_NAMESPACE} -- ${DEFAULT_IMAGE}:${DEFAULT_TAG}"
    stub docker \
         "inspect ${DEFAULT_IMAGE}:${DEFAULT_TAG} --format='{{ index .RepoDigests 0 }}' : echo 'fake image ID'" \
         "${docker_vault_cmd} --version : echo 'Vault v6.6.6 (The Secrets Manager of the Beast)'" \
         "${docker_vault_cmd} login -method=aws -token-only role=default : echo 'THIS_IS_YOUR_VAULT_TOKEN'"

    run "${PWD}/hooks/environment"
    assert_success

    unstub docker
}

@test "VAULT_ADDR is overridden in the presence of an explicitly configured address" {
    export BUILDKITE_PLUGIN_VAULT_LOGIN_ADDRESS=override.vault.mycompany.com:8200

    docker_vault_cmd="run --init --rm --env=SKIP_SETCAP=true --env=VAULT_ADDR=override.vault.mycompany.com:8200 --env=VAULT_NAMESPACE=${VAULT_NAMESPACE} -- ${DEFAULT_IMAGE}:${DEFAULT_TAG}"
    stub docker \
         "inspect ${DEFAULT_IMAGE}:${DEFAULT_TAG} --format='{{ index .RepoDigests 0 }}' : echo 'fake image ID'" \
         "${docker_vault_cmd} --version : echo 'Vault v6.6.6 (The Secrets Manager of the Beast)'" \
         "${docker_vault_cmd} login -method=aws -token-only role=default : echo 'THIS_IS_YOUR_VAULT_TOKEN'"

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

    docker_vault_cmd="run --init --rm --env=SKIP_SETCAP=true --env=VAULT_ADDR=${VAULT_ADDR} --env=VAULT_NAMESPACE=override_namespace -- ${DEFAULT_IMAGE}:${DEFAULT_TAG}"
    stub docker \
         "inspect ${DEFAULT_IMAGE}:${DEFAULT_TAG} --format='{{ index .RepoDigests 0 }}' : echo 'fake image ID'" \
         "${docker_vault_cmd} --version : echo 'Vault v6.6.6 (The Secrets Manager of the Beast)'" \
         "${docker_vault_cmd} login -method=aws -token-only role=default : echo 'THIS_IS_YOUR_VAULT_TOKEN'"

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

    docker_vault_cmd="run --init --rm --env=SKIP_SETCAP=true --env=VAULT_ADDR=${VAULT_ADDR} --env=VAULT_NAMESPACE=${VAULT_NAMESPACE} -- mycompany/vault:${DEFAULT_TAG}"
    stub docker \
         "inspect mycompany/vault:${DEFAULT_TAG} --format='{{ index .RepoDigests 0 }}' : echo 'fake image ID'" \
         "${docker_vault_cmd} --version : echo 'Vault v6.6.6 (The Secrets Manager of the Beast)'" \
         "${docker_vault_cmd} login -method=aws -token-only role=default : echo 'THIS_IS_YOUR_VAULT_TOKEN'"

    run "${PWD}/hooks/environment"
    assert_success

    unstub docker
}

@test "The image tag can be overridden" {
    export BUILDKITE_PLUGIN_VAULT_LOGIN_TAG=v1.2.3

    docker_vault_cmd="run --init --rm --env=SKIP_SETCAP=true --env=VAULT_ADDR=${VAULT_ADDR} --env=VAULT_NAMESPACE=${VAULT_NAMESPACE} -- ${DEFAULT_IMAGE}:v1.2.3"
    stub docker \
         "inspect ${DEFAULT_IMAGE}:v1.2.3 --format='{{ index .RepoDigests 0 }}' : echo 'fake image ID'" \
         "${docker_vault_cmd} --version : echo 'Vault v6.6.6 (The Secrets Manager of the Beast)'" \
         "${docker_vault_cmd} login -method=aws -token-only role=default : echo 'THIS_IS_YOUR_VAULT_TOKEN'"

    run "${PWD}/hooks/environment"
    assert_success

    unstub docker
}

@test "Image and tag can be overridden simultaneously" {
    export BUILDKITE_PLUGIN_VAULT_LOGIN_IMAGE=mycompany/vault
    export BUILDKITE_PLUGIN_VAULT_LOGIN_TAG=v1.2.3

    docker_vault_cmd="run --init --rm --env=SKIP_SETCAP=true --env=VAULT_ADDR=${VAULT_ADDR} --env=VAULT_NAMESPACE=${VAULT_NAMESPACE} -- mycompany/vault:v1.2.3"
    stub docker \
         "inspect mycompany/vault:v1.2.3 --format='{{ index .RepoDigests 0 }}' : echo 'fake image ID'" \
         "${docker_vault_cmd} --version : echo 'Vault v6.6.6 (The Secrets Manager of the Beast)'" \
         "${docker_vault_cmd} login -method=aws -token-only role=default : echo 'THIS_IS_YOUR_VAULT_TOKEN'"

    run "${PWD}/hooks/environment"
    assert_success

    unstub docker
}

@test "A queue name with a slash is converted to the proper authentication role name" {
    export BUILDKITE_AGENT_META_DATA_QUEUE=default/testing

    docker_vault_cmd="run --init --rm --env=SKIP_SETCAP=true --env=VAULT_ADDR=${VAULT_ADDR} --env=VAULT_NAMESPACE=${VAULT_NAMESPACE} -- ${DEFAULT_IMAGE}:${DEFAULT_TAG}"
    stub docker \
         "inspect ${DEFAULT_IMAGE}:${DEFAULT_TAG} --format='{{ index .RepoDigests 0 }}' : echo 'fake image ID'" \
         "${docker_vault_cmd} --version : echo 'Vault v6.6.6 (The Secrets Manager of the Beast)'" \
         "${docker_vault_cmd} login -method=aws -token-only role=default : echo 'THIS_IS_YOUR_VAULT_TOKEN'"

    run "${PWD}/hooks/environment"
    assert_success

    unstub docker

}

@test "Overriding the authentication role takes priority" {
    export BUILDKITE_AGENT_META_DATA_QUEUE=default/testing
    export BUILDKITE_PLUGIN_VAULT_LOGIN_AUTH_ROLE=monkeypants

    docker_vault_cmd="run --init --rm --env=SKIP_SETCAP=true --env=VAULT_ADDR=${VAULT_ADDR} --env=VAULT_NAMESPACE=${VAULT_NAMESPACE} -- ${DEFAULT_IMAGE}:${DEFAULT_TAG}"
    stub docker \
         "inspect ${DEFAULT_IMAGE}:${DEFAULT_TAG} --format='{{ index .RepoDigests 0 }}' : echo 'fake image ID'" \
         "${docker_vault_cmd} --version : echo 'Vault v6.6.6 (The Secrets Manager of the Beast)'" \
         "${docker_vault_cmd} login -method=aws -token-only role=monkeypants : echo 'THIS_IS_YOUR_VAULT_TOKEN'"

    run "${PWD}/hooks/environment"
    assert_success

    unstub docker
}

@test "Multiple login attempts work" {

    docker_vault_cmd="run --init --rm --env=SKIP_SETCAP=true --env=VAULT_ADDR=${VAULT_ADDR} --env=VAULT_NAMESPACE=${VAULT_NAMESPACE} -- ${DEFAULT_IMAGE}:${DEFAULT_TAG}"
    stub docker \
         "inspect ${DEFAULT_IMAGE}:${DEFAULT_TAG} --format='{{ index .RepoDigests 0 }}' : echo 'fake image ID'" \
         "${docker_vault_cmd} --version : echo 'Vault v6.6.6 (The Secrets Manager of the Beast)'" \
         "${docker_vault_cmd} login -method=aws -token-only role=default : exit 1" \
         "${docker_vault_cmd} login -method=aws -token-only role=default : exit 2" \
         "${docker_vault_cmd} login -method=aws -token-only role=default : echo 'THIS_IS_YOUR_VAULT_TOKEN'"

    run "${PWD}/hooks/environment"
    assert_success

    assert_output --partial "Failed login attempt 1/3; will try again in 5 seconds"
    assert_output --partial "Failed login attempt 2/3; will try again in 5 seconds"
    refute_output --partial "Failed to login 3 times!"

    unstub docker
}

@test "Exhausting all login attempts fails" {
    # Waiting 5 seconds during tests sucks
    export BUILDKITE_PLUGIN_VAULT_LOGIN_ATTEMPT_WAIT_SECONDS=1

    docker_vault_cmd="run --init --rm --env=SKIP_SETCAP=true --env=VAULT_ADDR=${VAULT_ADDR} --env=VAULT_NAMESPACE=${VAULT_NAMESPACE} -- ${DEFAULT_IMAGE}:${DEFAULT_TAG}"
    stub docker \
         "inspect ${DEFAULT_IMAGE}:${DEFAULT_TAG} --format='{{ index .RepoDigests 0 }}' : echo 'fake image ID'" \
         "${docker_vault_cmd} --version : echo 'Vault v6.6.6 (The Secrets Manager of the Beast)'" \
         "${docker_vault_cmd} login -method=aws -token-only role=default : exit 3" \
         "${docker_vault_cmd} login -method=aws -token-only role=default : exit 4" \
         "${docker_vault_cmd} login -method=aws -token-only role=default : exit 5"

    run "${PWD}/hooks/environment"
    assert_failure

    assert_output --partial "Failed login attempt 1/3; will try again in 1 second"
    assert_output --partial "Failed login attempt 2/3; will try again in 1 second"
    assert_output --partial "Failed to login 3 times!"

    unstub docker
}

@test "attempt count can be modified" {
    # Waiting 5 seconds during tests sucks
    export BUILDKITE_PLUGIN_VAULT_LOGIN_ATTEMPT_WAIT_SECONDS=1
    export BUILDKITE_PLUGIN_VAULT_LOGIN_ATTEMPT_COUNT=5

    docker_vault_cmd="run --init --rm --env=SKIP_SETCAP=true --env=VAULT_ADDR=${VAULT_ADDR} --env=VAULT_NAMESPACE=${VAULT_NAMESPACE} -- ${DEFAULT_IMAGE}:${DEFAULT_TAG}"
    stub docker \
         "inspect ${DEFAULT_IMAGE}:${DEFAULT_TAG} --format='{{ index .RepoDigests 0 }}' : echo 'fake image ID'" \
         "${docker_vault_cmd} --version : echo 'Vault v6.6.6 (The Secrets Manager of the Beast)'" \
         "${docker_vault_cmd} login -method=aws -token-only role=default : exit 6" \
         "${docker_vault_cmd} login -method=aws -token-only role=default : exit 7" \
         "${docker_vault_cmd} login -method=aws -token-only role=default : exit 8" \
         "${docker_vault_cmd} login -method=aws -token-only role=default : exit 9" \
         "${docker_vault_cmd} login -method=aws -token-only role=default : exit 10"

    run "${PWD}/hooks/environment"
    assert_failure

    assert_output --partial "Failed login attempt 1/5; will try again in 1 second"
    assert_output --partial "Failed login attempt 2/5; will try again in 1 second"
    assert_output --partial "Failed login attempt 3/5; will try again in 1 second"
    assert_output --partial "Failed login attempt 4/5; will try again in 1 second"
    assert_output --partial "Failed to login 5 times!"

    unstub docker
}

@test "Failure message respects a attempt count of 1" {
    # Waiting 5 seconds during tests sucks
    export BUILDKITE_PLUGIN_VAULT_LOGIN_ATTEMPT_WAIT_SECONDS=1
    export BUILDKITE_PLUGIN_VAULT_LOGIN_ATTEMPT_COUNT=1

    docker_vault_cmd="run --init --rm --env=SKIP_SETCAP=true --env=VAULT_ADDR=${VAULT_ADDR} --env=VAULT_NAMESPACE=${VAULT_NAMESPACE} -- ${DEFAULT_IMAGE}:${DEFAULT_TAG}"
    stub docker \
         "inspect ${DEFAULT_IMAGE}:${DEFAULT_TAG} --format='{{ index .RepoDigests 0 }}' : echo 'fake image ID'" \
         "${docker_vault_cmd} --version : echo 'Vault v6.6.6 (The Secrets Manager of the Beast)'" \
         "${docker_vault_cmd} login -method=aws -token-only role=default : exit 11"

    run "${PWD}/hooks/environment"
    assert_failure

    assert_output --partial "Failed to login!"

    unstub docker
}

@test "attempt count must be positive" {
    export BUILDKITE_PLUGIN_VAULT_LOGIN_ATTEMPT_COUNT=0

    run "${PWD}/hooks/environment"
    assert_failure

    assert_output --partial "Must provide a positive value for attempt_count!"
}

@test "attempt wait seconds must be positive" {
    export BUILDKITE_PLUGIN_VAULT_LOGIN_ATTEMPT_WAIT_SECONDS=0

    run "${PWD}/hooks/environment"
    assert_failure

    assert_output --partial "Must provide a positive value for attempt_wait_seconds!"
}

@test "always-pull will pull an image before running" {
    export BUILDKITE_PLUGIN_VAULT_LOGIN_ALWAYS_PULL=1

    docker_vault_cmd="run --init --rm --env=SKIP_SETCAP=true --env=VAULT_ADDR=${VAULT_ADDR} --env=VAULT_NAMESPACE=${VAULT_NAMESPACE} -- ${DEFAULT_IMAGE}:${DEFAULT_TAG}"
    stub docker \
         "pull ${DEFAULT_IMAGE}:${DEFAULT_TAG} : echo 'pulling image'" \
         "inspect ${DEFAULT_IMAGE}:${DEFAULT_TAG} --format='{{ index .RepoDigests 0 }}' : echo 'fake image ID'" \
         "${docker_vault_cmd} --version : echo 'Vault v6.6.6 (The Secrets Manager of the Beast)'" \
         "${docker_vault_cmd} login -method=aws -token-only role=default : echo 'THIS_IS_YOUR_VAULT_TOKEN'"

    run "${PWD}/hooks/environment"
    assert_success

    unstub docker
}
