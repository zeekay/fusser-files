# OSINT Investigation: MacSync Stealer / Fusser Infrastructure

## Attribution Summary

| Signal | Value | Implication |
|--------|-------|-------------|
| **Server timezone** | `Europe/Berlin` (CET) | Operator in Central Europe |
| **Business hours** | 12:00-21:00 CET | Consistent with European operator |
| **Malware family** | MacSync Stealer (ex-Mac.c) | Known MaaS, operator alias "mentalpositive" |
| **Build tag** | N3 | Third campaign build / affiliate package |
| **Registrar** | NiceNIC (HK) — bulletproof registrar | Deliberate OPSEC choice |
| **C2 panel** | PHP/Laravel, cookie: `paneli_session` | Custom stealer panel |
| **C2 backend** | sorvensorven.com (registered 2025-10-08) | Deliberate un-googleable name |
| **Spearphishing persona** | "Daniel Beaumont" at "Cyrus Global Holding" | Impersonating dissolved UK crypto company |
| **Email infra** | AWS SES ap-northeast-1 (Tokyo/Seoul) | Email sent from Asia-Pacific AWS region |
| **Hardcoded IP** | 67.188.129.26 — Comcast residential, Martinez CA | Victim or test machine, NOT attacker |

## The Operator: "mentalpositive" / MacSync

MacSync Stealer is a documented MaaS (Malware-as-a-Service) operation:

- **First seen:** April 2025 as "Mac.c" stealer
- **Operator alias:** "mentalpositive", later rebranded to "MacSync"
- **September 2025:** Published interview — claims ~36 active users (affiliates), refuses CIS country targeting
- **October 2025:** sorvensorven.com registered (this campaign's C2)
- **December 2025:** Jamf Threat Labs publishes analysis of code-signed Swift variant
- **February 2026:** Microsoft Security Blog covers macOS infostealer expansion
- **February 2026:** This fusser.ai campaign goes live

The operator sells access to the stealer panel to affiliates who run their own campaigns. "Build N3" is likely the third affiliate package or campaign variant.

## Domain Infrastructure

### fusser.ai (Landing Page)
- **IPs:** 172.67.177.76, 104.21.80.103 (Cloudflare)
- **Registrar:** NameCheap (privacy protected)
- **SSL issued:** 2026-02-11
- **MX:** AWS SES ap-northeast-1 (sends phishing emails)

### fusser.io (Primary Brand Domain)
- **IPs:** 104.21.85.104, 172.67.204.156 (Cloudflare)
- **Registrar:** NiceNIC (bulletproof, HK)
- **Registered:** 2026-01-28
- **Registrant org:** "Global Enterprises Group" (London, GB)
- **Canonical domain** — fusser.ai links here in meta tags

### fusser-api.com (C2 API)
- **IPs:** 104.21.21.252, 172.67.201.166 (Cloudflare)
- **Registrar:** NiceNIC (bulletproof, HK)
- **Registered:** 2026-02-05
- **Server:** nginx behind Cloudflare

### sorvensorven.com (Primary C2 Backend / Panel)
- **IPs:** 172.67.185.196, 104.21.19.104 (Cloudflare)
- **Registrar:** Dominet (HK) / Alibaba Cloud DNS
- **Registered:** 2025-10-08
- **Address:** Wilayah Persekutuan, Malaysia (privacy protected)
- **Stack:** PHP/Laravel + nginx behind Cloudflare
- **Timezone:** Europe/Berlin

### fusser.app (Variant)
- **Registrar:** NiceNIC
- **Status:** Blacklisted by Fortinet, flagged by BitDefender

## Live C2 Endpoints Confirmed

```
GET  /api/calendar/config           → Returns Europe/Berlin timezone, business hours
GET  /api/calendar/slots            → Booking slots (requires uuid)
POST /api/calendar/book             → Booking submission
GET  /api/calendar/lead             → Victim data capture
GET  /api/download                  → Malware delivery (DMG/MSI or ClickFix commands)
POST /api/validate-download-code    → Access code validation gate
```

The `/api/download` endpoint returns EITHER:
1. `{"download_url": "https://..."}` — direct DMG/MSI file
2. `{"mode": "commands", "commands": "..."}` — ClickFix terminal injection

When mode is "commands", the frontend copies malicious shell commands to clipboard
and instructs the victim to paste into Terminal.

## "Cyrus Global Holding" — Dissolved UK Shell Company

- **UK Companies House:** 13432556
- **Incorporated:** 1 June 2021
- **Dissolved:** 20 December 2022
- **Address:** 128 City Road, London, EC1V 2NX (formation agent — 22,000+ companies registered there)
- **Director:** MOAZENI, Mohammad Hossein (Iranian national, residing in Canada, born May 1995)
- **SIC codes:** Investment trusts, venture capital, open-ended investment
- **Linked site:** cyruscoin.io (DeFi/crypto exchange)

The attacker deliberately chose a dissolved UK crypto company as the spearphishing persona
to target crypto/DeFi professionals who would find the name plausible.

## 67.188.129.26 — Likely Victim

- **ISP:** Comcast Cable (residential)
- **Location:** Martinez, California (Contra Costa County)
- **ASN:** AS7922
- **Assessment:** Residential IP, not hosting infrastructure. Likely a victim's IP
  hardcoded during development/testing, or the attacker's own home IP leaked by accident.

## Registration Timeline

```
2025-10-08  sorvensorven.com      C2 backend created
2026-01-28  fusser.io             Primary lure domain
2026-02-02  fusser.io SSL         Lure goes live
2026-02-05  fusser-api.com        API domain registered
2026-02-05  fusser.ai modified    Secondary lure updated
2026-02-11  fusser.ai SSL         Secondary lure active
2026-02-24  ALL CONFIRMED LIVE    This investigation
```

## Key OPSEC Failures

1. **Calendar config endpoint is unauthenticated** — leaked Europe/Berlin timezone
2. **Business hours 12:00-21:00 CET** — narrows operator location
3. **Session cookie named `paneli_session`** — reveals Laravel panel purpose
4. **og:url says fusser.io but site is fusser.ai** — copy-paste from template
5. **"Global Enterprises Group" in WHOIS** — reused across registrations
6. **Hardcoded IP 67.188.129.26** — either victim IP or operator's own residential IP

## Published Research

- [Jamf Threat Labs: MacSync Stealer Evolution](https://www.jamf.com/blog/macsync-stealer-evolution-code-signed-swift-malware-analysis/)
- [The Hacker News: MacSync Uses Signed App](https://thehackernews.com/2025/12/new-macsync-macos-stealer-uses-signed.html)
- [Moonlock: Mac.c → MacSync with Backdoor](https://moonlock.com/macsync-stealer-notarized-app)
- [Infostealers.com: Interview with MacSync Developer](https://www.infostealers.com/article/approaching-infostealers-devs-a-brief-interview-with-macsync-ex-mentalpositive/)
- [Microsoft: macOS Infostealers Expansion (Feb 2026)](https://www.microsoft.com/en-us/security/blog/2026/02/02/infostealers-without-borders-macos-python-stealers-and-platform-abuse/)
- [CloudSEK: MacSync Script-Driven Stealer](https://www.cloudsek.com/blog/inside-macsyncs-script-driven-stealer-and-hardware-wallet-app-trojanization)
