# Cloudflare DNS — campixo.com

**Full walkthrough:** [`docs/D02-D04-cloudflare-campixo.com.md`](D02-D04-cloudflare-campixo.com.md) (D02 nameservers, D03 records, D04 SSL).

## Wildcard A records (D03)

| Type | Name | Content | Proxy |
|------|------|---------|-------|
| A | `*` | `<VM_IP>` | Proxied (orange cloud) |
| A | `@` | `<VM_IP>` | Proxied |

Replace `<VM_IP>` with your Oracle Cloud VM public IP (from D06). Add these **after the VM is created** — see [`D02-D04-cloudflare-campixo.com.md`](D02-D04-cloudflare-campixo.com.md).

## SSL (D04)

Cloudflare Dashboard → SSL/TLS:

- Encryption mode: **Full (strict)**
- Edge Certificates: **Always Use HTTPS** enabled

Edge SSL is handled by Cloudflare (no Certbot on server for public HTTPS). Origin: Cloudflare Origin Certificate or self-signed on Nginx (port 80 from Cloudflare).

## Verify

```bash
curl -I https://greenvalley.campixo.com/up
curl https://greenvalley.campixo.com/api/v1/school/current
```

Expected: HTTP 200 on `/up`; school JSON for `greenvalley` tenant on `/api/v1/school/current`.
