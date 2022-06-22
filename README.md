# Vault Login Buildkite Plugin

Logs into a Hashicorp Vault server.

The login occurs in an `environment` hook and exports the following
variables to the environment:
- VAULT_ADDR
- VAULT_NAMESPACE
- VAULT_TOKEN

The token is revoked in the `pre-exit` hook. Tokens should thus have
the following policy:

```hcl
path "auth/token/revoke-self" {
    capabilities = ["update"]
}
```
This is included in the `default` Vault policy.

Any failures in either hook will cause the affected Buildkite job to
fail.

At the moment, this plugin is chiefly concerned with Grapl's needs,
and may not be sufficiently generalized or flexible enough for all
uses. For instance, it assumes the use of AWS, and also makes some
assumptions about the name of the role to authenticate with.

## Example

In general, this will be how you'll interact with the plugin the
majority of the time (here, the `address` and `namespace` have been
set in the environment already, since those will generally be the same
across your pipelines):

```yml
steps:
  - command: make test
    plugins:
      - grapl-security/vault-login#v0.1.3
```

You can override many of the built-in defaults, or be very explicit:

```yml
steps:
  - command: make test
    plugins:
      - grapl-security/vault-login#v0.1.3:
          image: vault
          tag: 1.8.4
          address: https://vault.mycompany.com:8200
          namespace: admin/buildkite
```

You can sidestep the internal logic for determining the authentication
role name from the Buildkite queue name if you really need to:

```yml
steps:
  - command: make test
    plugins:
      - grapl-security/vault-login#v0.1.3:
          auth_role: super_special_auth_role
```

Failed attempts to login can be retried, which comes in handy if you
experience transient network issues. By default, the plugin attempts 3
times, waiting 5 seconds between each attempt, but these values are
both configurable:

```yml
steps:
  - command: make test
    plugins:
      - grapl-security/vault-login#v0.1.3:
          attempt_count: 5
          attempt_wait_seconds: 10
```

Setting `attempt_count` to `1` effectively disables the retry logic.

## Configuration

### `vault` Flags

#### `address` (optional, string)

The address of the Vault server to access. If not set, falls back to
`VAULT_ADDR` in the environment. If `VAULT_ADDR` is not set either,
the plugin fails with an error.

#### `auth_role` (optional, string)

The name of the Vault AWS role to authenticate as. If not specified,
uses (Grapl-specific) logic to generate the role name from the
Buildkite agent queue name.

#### `namespace` (optional, string)

The Vault namespace to access. If not set, falls back to
`VAULT_NAMESPACE` in the environment. If `VAULT_NAMESPACE` is not set
either, the plugin fails with an error.

### Retry Configuration

#### `attempt_count` (optional, integer)

The number of times to attempt to login to Vault before giving
up.

Defaults to `3`.

You can disable retries by setting this to `1`.

#### `attempt_wait_seconds` (optional, integer)

The number of seconds to wait between each retry attempt.

Defaults to `5`.

### Container Image Configuration

#### `image` (optional, string)

The container image with the `vault` binary that the plugin uses. Any
container used should have the `vault` binary as its entrypoint.

Defaults to `hashicorp/vault`.

#### `tag` (optional, string)

The container image tag the plugin uses.

Defaults to `latest`.

#### `always_pull` (optional, boolean)

Whether or not to perform an explicit `docker pull` of the configured
image before running. Useful when using the `latest` tag to ensure you
are always using the _actual_ latest image.

Defaults to `false`.

## Building

Requires `make`, `docker`, and Docker Compose v2.

`make all` will run all formatting, linting, and testing.
