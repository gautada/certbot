# certbot
Not sure I need something as complex as cert-manager.  This is an 
opionated certbot implementation. This should conned to LEt's Encrypt
ACME and generate a signed certificate set via DNS validation. Then finally,
update the k8s cluster with the updated `tls-crts`.

## Certbot Authentication Hooks

### Cloudflare
The auth hook for Cloudflare is provided by the `cloudflare-auth-hook`
script. This script requires four parameters to run, documented below.
The variables can be provided from the CLI or as environment variables.

- **Token**: This Cloudflare API Token has to be created in the Cloudflare site
(via: Manage Account/Account API Tokens) with permissons set to `Zone.DNS`.
- Zone: The Cloudflare Zone ID Can be found on the domain overview it
identifies the domain name to update.
- **Record**: This is the DNS record to update. For the Cloudflare API this should
be in the format `key.domain.tld` the key required is `_acme-challenge`.
- **Value**: The value to set the record to.  This is provided by certbot and
passed via environment variable `$CERTBOT_VALIDATION`

**NOTE**: To load a .env file to environment variables
`export $(grep -v '^#' _env | xargs)`