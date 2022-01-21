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
      - grapl-security/vault-login#v0.1.1
```

You can override many of the built-in defaults, or be very explicit:

```yml
steps:
  - command: make test
    plugins:
      - grapl-security/vault-login#v0.1.1:
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
      - grapl-security/vault-login#v0.1.1:
        auth_role: super_special_auth_role
```

## Configuration

### address (optional, string)

The address of the Vault server to access. If not set, falls back to
`VAULT_ADDR` in the environment. If `VAULT_ADDR` is not set either,
the plugin fails with an error.

### auth_role (optional, string)

The name of the Vault AWS role to authenticate as. If not specified,
uses (Grapl-specific) logic to generate the role name from the
Buildkite agent queue name.

### image (optional, string)

The container image with the Codecov Uploader binary that the plugin
uses. Any container used should have the `codecov` binary as its
entrypoint.

Defaults to `hashicorp/vault`.

### namespace (optional, string)

The Vault namespace to access. If not set, falls back to
`VAULT_NAMESPACE` in the environment. If `VAULT_NAMESPACE` is not set
either, the plugin fails with an error.

### tag (optional, string)

The container image tag the plugin uses.

Defaults to `latest`.

## Building

Requires `make`, `docker`, and `docker-compose`.

`make all` will run all formatting, linting, and testing.
