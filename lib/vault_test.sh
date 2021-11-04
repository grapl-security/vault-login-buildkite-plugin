#!/usr/bin/env bash

oneTimeSetUp() {
    # shellcheck source-path=SCRIPTDIR
    source "$(dirname "${BASH_SOURCE[0]}")/vault.sh"
}

test_vault_stdout_is_clean() {
    # This command will fail, which is expected. It will emit a
    # combination of stderr and stdout, however. If the Docker run is
    # not configured properly w/r/t interactivity, TTY, and
    # capabilities, the standard output stream *of the container run*
    # will contain a mixture of the standard output and standard error
    # streams of the *vault process* within the container. We do not
    # want this.
    #
    # The standard error stream would look like this, FYI:
    #    [INFO]  proxy environment: http_proxy="" https_proxy="" no_proxy=""
    output="$(vault server)"
    assertEquals "The output should only contain stdout, not stderr" \
        "A storage backend must be specified" \
        "${output}"
}

test_vault_stdout_contains_no_ANSI_codes() {
    # This command will fail, which is expected. If the container is
    # run with a TTY (i.e., `--tty`) attached, however, it will
    # contain ANSI codes in the output, which we do not want. *That*
    # is the main focus of this test.
    output="$(vault server)"
    expanded_output="$(cat --show-nonprinting --show-tabs <<< "${output}")"

    # These will be different if the output contains ANSI characters
    # (or anything else it shouldn't!)
    assertEquals "The output of the vault command should not contain ANSI control characters" \
        "${output}" \
        "${expanded_output}"
}
