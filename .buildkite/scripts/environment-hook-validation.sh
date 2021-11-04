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
if ! vault token lookup > /dev/null; then
    echo "Failed to interact with Vault using VAULT_TOKEN!"
    exit 1
else
    echo "Successfully interacted with Vault using VAULT_TOKEN"
fi
