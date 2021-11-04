#!/usr/bin/env bash

set -euo pipefail

readonly default_image="hashicorp/vault"
readonly default_tag="latest"
# TODO: add a "debug" mode where we spit out the specific image and
# commands being used
readonly image="${BUILDKITE_PLUGIN_VAULT_LOGIN_IMAGE:-${default_image}}:${BUILDKITE_PLUGIN_VAULT_LOGIN_TAG:-${default_tag}}"

# Wrap up the invocation of a Vault container image to alleviate the
# need to have a Vault binary installed on the Buildkite agent machine
# already. Scripts can just source this file and then call `vault`
# like normal.
vault() {
    # We're passing our environment variables like this to make
    # testing a bit easier. In particular, having visibility into the
    # values used for VAULT_ADDR and VAULT_NAMESPACE makes it easy to
    # confirm that the proper values are being used (taking into
    # account default values, overrides, etc.)
    #
    # Conditionally adding them also facilitates some unit testing.
    env_args=()

    if [ -n "${VAULT_ADDR:-}" ]; then
        env_args+=("--env=VAULT_ADDR=${VAULT_ADDR}")
    fi

    if [ -n "${VAULT_NAMESPACE:-}" ]; then
        env_args+=("--env=VAULT_NAMESPACE=${VAULT_NAMESPACE}")
    fi

    # We don't need to pass the VAULT_TOKEN by value (it should also
    # be treated like a secret, whereas VAULT_ADDR and VAULT_NAMESPACE
    # don't).
    if [ -n "${VAULT_TOKEN:-}" ]; then
        env_args+=("--env=VAULT_TOKEN")
    fi

    # It is important to not use `--interactive` and `--tty` in this
    # Docker invocation (particularly `--tty`), as that can result in
    # getting stdout and stderr streams mixed in the output of this
    # command, as well as getting embedded ANSI codes, which can cause
    # subsequent Vault commands to fail (Vault doesn't like ANSI codes
    # in its tokens, for instance).

    # NOTE: The particularly ugly expansion of `env_args` here is to work
    # around the fact that we currently have Bash 4.2 on our Buildkite
    # agents, where expanding empty arrays in the presence of `set -u`
    # will raise an unbound variable error. With Bash 4.4+, this is no
    # longer the case, allowing us to use the more sensible
    # "${env_args[@]}"
    #
    # See the following for further background (most concretely, the
    # final link):
    # - https://stackoverflow.com/a/61551944
    # - https://gist.github.com/dimo414/2fb052d230654cc0c25e9e41a9651ebe
    # - https://git.savannah.gnu.org/cgit/bash.git/tree/CHANGES?id=3ba697465bc74fab513a26dea700cc82e9f4724e#n878
    docker run \
        --init \
        --rm \
        --cap-add IPC_LOCK \
        ${env_args[@]+"${env_args[@]}"} \
        -- \
        "${image}" "$@"
}
