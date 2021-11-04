#!/usr/bin/env bash

# This script is intended to run *after* the plugin's post-exit script
# (which we can do with the metahook plugin) to verify that the Vault
# token has indeed been revoked. If that's the case, we shouldn't be
# able to make a call.
#
# See https://github.com/improbable-eng/metahook-buildkite-plugin
set -euo pipefail

# shellcheck source-path=SCRIPTDIR
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/vault.sh"

if vault token lookup > /dev/null; then
    echo "Token should have been revoked, but we made a successful call to Vault!"
    exit 1
else
    echo "Failed to make a call to Vault with a revoked token, as expected"
fi
