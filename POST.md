Someone tried to hack me with the most polished attack I've seen yet.

An email landed offering a "Founding CTO" role at "Cyrus Global Holding." Professional meeting request from "Daniel Beaumont." 30-minute call. "Select Time Slot" button. Sent "via Fusser" — looks like a Calendly clone.

Except Fusser doesn't exist. The video calls don't work. The 4.9-star rating and 2,847 reviews are fake. The polished React landing page with Slack, Notion, and Figma integration logos is window dressing for a three-stage macOS infostealer called "MacSync Stealer."

I downloaded the source and tore it apart.

Here's what it does in 30 seconds:
- Shows a fake "System Preferences" password dialog (no Cancel button, loops forever until you type the right one)
- Steals all passwords from 13 Chromium browsers + 4 Firefox variants
- Raids 60+ crypto wallet browser extensions (MetaMask, Phantom, Coinbase, Rabby...)
- Loots 21+ desktop wallets (Exodus, Electrum, Ledger, Bitcoin Core...)
- Clones your Telegram session
- Copies your macOS Keychains, SSH keys, AWS creds, Kubernetes configs
- Grabs seed files, .pem keys, KeePass databases, VPN configs from your Desktop/Documents/Downloads
- Backdoors your Ledger Wallet and Ledger Live apps with trojanized versions
- Packages everything into a zip and uploads it in 10MB chunks
- Shows a fake "Your Mac does not support this application" error as cover

The C2 infrastructure:
- fusser.ai (landing page)
- fusser-api.com (payload delivery + exfiltration)
- sorvensorven.com (backend API for gated downloads)

I fully defanged and annotated every stage for educational analysis. The full forensic writeup is on GitHub with an interactive demo site that mimics the real attack page but teaches you what would have happened at each step:

https://github.com/zeekay/fusser-files
https://zeekay.github.io/fusser-files/

If you get a meeting request from a tool you've never heard of asking you to download software to "join a call" — don't. Zoom, Google Meet, and Teams don't need invite codes or custom installers.

Stay safe out there.
