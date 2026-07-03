# D02–D04: Cloudflare DNS for campixo.com

Step-by-step guide for **Deployment checklist D02–D04**. Domain: **campixo.com** (multi-vertical SaaS — schools, health, finance). Each school gets a subdomain like `greenvalley.campixo.com`.

**Prerequisites:** D01 done — you own `campixo.com`. Oracle VM IP from D05–D06 is needed for D03 A records.

---

## D02 — Two paths (pick one)

| Path | When to use | Nameserver change? |
|------|-------------|-------------------|
| **[A) Cloudflare Registrar](#d02a--register-at-cloudflare-registrar-recommended)** | Buy `campixo.com` at Cloudflare (recommended) | **No** — DNS is in the same account |
| **[B) External registrar (GoDaddy, etc.)](#d02b--add-an-externally-purchased-domain)** | Domain already bought elsewhere | **Yes** — point registrar NS to Cloudflare |

---

## What to do today (before the VM exists)

You can complete **D02** and **D04** now. **D03** DNS A records should wait until you have the Oracle VM public IP (D06), or add them with a temporary placeholder and update later.

| Step | Do now? | Action |
|------|---------|--------|
| **D02** | ✅ Yes | Register or add `campixo.com` in Cloudflare (see path A or B below) |
| **D03** | ⏸ After D06 | Add A `@` and A `*` → `<VM_IP>` (Proxied) |
| **D04** | ✅ Yes | SSL **Full (strict)** + **Always Use HTTPS** |

### Cloudflare Registrar path (path A — no nameserver step)

1. [dash.cloudflare.com](https://dash.cloudflare.com) → **Domain Registration** → search **campixo.com** → complete purchase
2. Domain appears under **Websites** automatically — DNS is already in your account (**Active**, no NS change)
3. **SSL/TLS** → **Overview** → **Full (strict)**
4. **SSL/TLS** → **Edge Certificates** → turn on **Always Use HTTPS** and **Automatic HTTPS Rewrites**
5. **Skip DNS A records for now** — return after D06 with your VM IPv4

Optional prep (no VM needed): **SSL/TLS** → **Origin Server** → **Create Certificate** for `campixo.com` and `*.campixo.com` — save the cert/key for Nginx install (D11).

### External registrar path (path B — GoDaddy, etc.)

1. [dash.cloudflare.com](https://dash.cloudflare.com) → **Add a site** → enter `campixo.com` → Free plan
2. Copy the two nameservers Cloudflare assigns → paste them at your registrar for `campixo.com`
3. Wait until Cloudflare shows **Active** (usually 15 min–24 h)
4. **SSL/TLS** → **Overview** → **Full (strict)**
5. **SSL/TLS** → **Edge Certificates** → turn on **Always Use HTTPS** and **Automatic HTTPS Rewrites**
6. **Skip DNS A records for now** — return after D06 with your VM IPv4

---

## D02A — Register at Cloudflare Registrar (recommended)

Use this path when purchasing **campixo.com** directly from Cloudflare.

### 1. Create a Cloudflare account (if needed)

1. Go to [https://dash.cloudflare.com/sign-up](https://dash.cloudflare.com/sign-up)
2. Verify your email

### 2. Register the domain

1. Cloudflare Dashboard → **Domain Registration** (or **Register Domains**)
2. Search for **campixo.com** → add to cart → complete checkout
3. After payment, the domain is added to your account automatically

### 3. Confirm the site is Active

1. Dashboard → **Websites** → select **campixo.com**
2. Overview should show **Active** — no nameserver change is required because registration and DNS live in the same Cloudflare account
3. **DNS** → **Records** is ready for D03 when you have the VM IP

If you already registered elsewhere and want to transfer to Cloudflare later, use [Cloudflare domain transfer](https://developers.cloudflare.com/registrar/get-started/transfer-domain-to-cloudflare/) — transfer is optional; path B works without it.

---

## D02B — Add an externally purchased domain

Use this path when **campixo.com** was bought at GoDaddy or another registrar (alternative to path A).

### 1. Create a Cloudflare account (if needed)

1. Go to [https://dash.cloudflare.com/sign-up](https://dash.cloudflare.com/sign-up)
2. Verify your email

### 2. Add the site

1. Cloudflare Dashboard → **Add a site**
2. Enter `campixo.com` → **Continue**
3. Select the **Free** plan → **Continue**
4. Cloudflare scans existing DNS records from your registrar — review and **Continue**

### 3. Copy Cloudflare nameservers

Cloudflare shows two nameservers, for example:

```
ada.ns.cloudflare.com
bob.ns.cloudflare.com
```

(Your assigned pair will differ — use the values Cloudflare shows.)

### 4. Change nameservers at GoDaddy (or your registrar)

1. Log in to [GoDaddy Domain Portfolio](https://dcc.godaddy.com/domains) (or your registrar's DNS/nameserver panel)
2. Select **campixo.com** → **DNS** or **Manage DNS**
3. Scroll to **Nameservers** → **Change**
4. Choose **Enter my own nameservers (Advanced)**
5. Replace registrar defaults with the two Cloudflare nameservers
6. **Save**

Propagation usually takes **15 minutes to 48 hours**. Cloudflare emails you when the site is **Active**.

### 5. Confirm in Cloudflare

Dashboard → **campixo.com** → overview should show **Active** (green) once nameservers propagate.

---

## D03 — Wildcard A records → Oracle VM

> **When:** After D06 — you need the Oracle Cloud VM **public IPv4**. Do not point production DNS at a placeholder unless you plan to edit both records again within minutes of VM creation.

Replace `<VM_IP>` with your Oracle Cloud VM public IPv4 (from D06).

### DNS records

Cloudflare → **campixo.com** → **DNS** → **Records** → **Add record**:

| Type | Name | Content | Proxy status | TTL |
|------|------|---------|--------------|-----|
| A | `@` | `<VM_IP>` | **Proxied** (orange cloud) | Auto |
| A | `*` | `<VM_IP>` | **Proxied** (orange cloud) | Auto |

- **Name `@`** = apex `campixo.com`
- **Name `*`** = any subdomain (`greenvalley.campixo.com`, `demo.campixo.com`, …)
- **Proxied** = traffic goes through Cloudflare (DDoS, SSL edge, caching)

Optional (email later): add MX/TXT for Resend (D14) — do not add yet unless you have mail provider values.

### Nginx on the VM

After D10–D11, deploy wildcard config from [`docs/nginx-wildcard.conf`](nginx-wildcard.conf) and set on the server:

```bash
# backend/.env on Oracle VM
APP_HOST=campixo.com
FRONTEND_ORIGIN=https://campixo.com
```

---

## D04 — SSL Full (strict) + Always Use HTTPS

### SSL/TLS mode

1. Cloudflare → **campixo.com** → **SSL/TLS** → **Overview**
2. Set encryption mode to **Full (strict)**

Why: Cloudflare terminates HTTPS at the edge. Origin (Nginx on port 80) receives HTTP from Cloudflare; no Certbot on the VM for public HTTPS.

For **Full (strict)**, the origin must present a valid certificate. Options:

- **Recommended:** Cloudflare **Origin Certificate** (15-year, free) on Nginx, or
- Self-signed cert on Nginx (Cloudflare trusts its own origin certs)

Generate origin cert: **SSL/TLS** → **Origin Server** → **Create Certificate** → hostnames `campixo.com`, `*.campixo.com` → install on VM when Nginx is ready.

### Always Use HTTPS

1. **SSL/TLS** → **Edge Certificates**
2. Enable **Always Use HTTPS**
3. Enable **Automatic HTTPS Rewrites** (recommended)

### Minimum TLS (optional)

**SSL/TLS** → **Edge Certificates** → **Minimum TLS Version** → **TLS 1.2** (default is fine).

---

## Verification

After the site is **Active**, DNS records point to `<VM_IP>`, and the app is deployed (D08–D18):

```bash
# Health check (expect HTTP 200)
curl -I https://greenvalley.campixo.com/up

# Tenant resolution (expect JSON for greenvalley school)
curl https://greenvalley.campixo.com/api/v1/school/current
```

Before the VM is live, `curl` may fail with connection or 521/522 from Cloudflare — that is expected until D05–D11.

### DNS-only checks (before VM)

```bash
# Should resolve to Cloudflare anycast IPs (proxied)
dig +short greenvalley.campixo.com
dig +short campixo.com
```

---

## Manual checklist (you do these)

| Step | Where | Action |
|------|--------|--------|
| D01 | Cloudflare Registrar | Register **campixo.com** (path A) — *or* buy elsewhere and use path B |
| D02 | Cloudflare | Confirm **campixo.com** is **Active** (Registrar: automatic; external: after NS change) |
| D03 | Cloudflare DNS | A `@` and A `*` → `<VM_IP>`, Proxied — **after D06 VM IP** |
| D04 | Cloudflare SSL/TLS | **Full (strict)** |
| D04 | Cloudflare SSL/TLS | **Always Use HTTPS** on |
| Later | Oracle VM | `APP_HOST=campixo.com`, Nginx wildcard, origin cert |

---

## Related docs

- Quick reference: [`docs/cloudflare-dns.md`](cloudflare-dns.md)
- Nginx: [`docs/nginx-wildcard.conf`](nginx-wildcard.conf)
- Deploy runbook: [`deploy/README.md`](../deploy/README.md)
- Full checklist: [`docs/DEPLOYMENT_TASKS.md`](DEPLOYMENT_TASKS.md)
