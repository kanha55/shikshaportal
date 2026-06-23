# Cloudflare DNS (T03)

## Wildcard A record

| Type | Name | Content | Proxy |
|------|------|---------|-------|
| A | `*` | `<ORACLE_VM_IP>` | Proxied (orange cloud) |
| A | `@` | `<ORACLE_VM_IP>` | Proxied |

## SSL mode

Cloudflare Dashboard → SSL/TLS → **Full (strict)**

- Edge SSL handled by Cloudflare (no Certbot on server for public HTTPS)
- Origin: self-signed or Cloudflare Origin Certificate on Nginx (port 80 only if Cloudflare terminates HTTPS)

## Verify

```bash
curl -I https://greenvalley.shikshaportal.in/up
curl https://greenvalley.shikshaportal.in/api/v1/school/current
```

Expected: school JSON for `greenvalley` tenant.
