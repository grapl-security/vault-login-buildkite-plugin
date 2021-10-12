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
uses.

## Example

```yml
steps:
  - command: make test
    plugins:
      - grapl-security/vault-login#v0.1.0
```

```yml
steps:
  - command: make test
    plugins:
      - grapl-security/vault-login#v0.1.0:
        image: vault
        tag: 1.8.4
        address: https://vault.mycompany.com:8200
        namespace: admin/buildkite
```
## Configuration

### image (optional, string)

The container image with the Codecov Uploader binary that the plugin
uses. Any container used should have the `codecov` binary as its
entrypoint.

Defaults to `hashicorp/vault`.

### tag (optional, string)

The container image tag the plugin uses.

Defaults to `latest`.

### address (optional, string)

The address of the Vault server to access. If not set, falls back to
`VAULT_ADDR` in the environment. If `VAULT_ADDR` is not set either,
the plugin fails with an error.

### namespace (optional, string)

The Vault namespace to access. If not set, falls back to
`VAULT_NAMESPACE` in the environment. If `VAULT_NAMESPACE` is not set
either, the plugin fails with an error.

## Building

Requires `make`, `docker`, and `docker-compose`.

`make all` will run all formatting, linting, and testing.
