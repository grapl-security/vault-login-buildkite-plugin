#!/usr/bin/env bash

# This script is to validate that the plugin's environment hook did
# the right thing; namely, drop a VAULT_TOKEN into the environment
# that we can use to do things with.

set -euo pipefail

# shellcheck source-path=SCRIPTDIR
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/vault.sh"

if [ -z "${VAULT_TOKEN}" ]; then
    echo "VAULT_TOKEN should be present in the environment after invoking the vault-login plugin, but it was not!"
    exit 1
fi

# Just do something that we know we can do with the Vault token we've got.
# TODO: Consider granting these tokens the ability to just run `vault
# token lookup`
# shellcheck disable=SC2034
if ! token=$(vault kv get -field=TOOLCHAIN_AUTH_TOKEN secret/buildkite/env/vault-login-buildkite-plugin/TOOLCHAIN_AUTH_TOKEN); then
    echo "Failed to use token to retrieve a secret!"
    exit 1
fi
