#!/bin/bash

# Ping RPC servers and determine number of GPU layers
#
# It is recommended to use LLAMA_ARG_HOST and LLAMA_ARG_PORT instead of --host and --port due to `llama-cli` (test run) not using them

set -euo pipefail

IFS=',' read -r -a servers <<< "${RPC_SERVERS:-}"

active_servers=()
for server in "${servers[@]}"; do
  if /bin/nc -z -w 1 "${server%:*}" "${server#*:}"; then
    echo "Server $server is active, adding it to RPC backend"
    active_servers+=("$server")
  else
    echo "Server $server does not respond, skipping"
  fi
done

llama_args=("$@")

if [[ ${#active_servers[@]} -gt 0 ]]; then
  llama_args+=("--rpc" "$(IFS=, ; echo "${active_servers[*]}")")
fi

test_binary=/bin/llama-cli
for elem in "${llama_args[@]}"; do
  if [[ "$elem" = "--mmproj" ]]; then
    test_binary="/bin/llama-mtmd-cli"
    break
  fi
done

# "/quit" is for llama-mtmd-cli which __cannot__ be run without chat mode, and falls into a loop on EOF
echo "Doing a test run with $test_binary ${llama_args[*]}"
if ! output="$("$test_binary" "${llama_args[@]}" -n 1 2>&1 <<< "/quit" | tee /dev/stderr)"; then
  echo "Test run failed"
  if echo "$output" | grep -q "cudaMalloc failed"; then
    echo "Out of CUDA memory, calculating ngl"
    ngl_high="$(echo "$output" | grep -Po '(?<=print_info: n_layer\s{0,64}=\s{0,64})(\d+)')"
    ngl_low=0
    # -1 prevents cases like short by 1 repeating
    # also skips last cycle if result is 0
    while (( ngl_low < (ngl_high-1) )); do
      ngl_mid=$(((ngl_low + ngl_high) / 2))
      echo "Trying ngl=$ngl_mid"
      if output="$("$test_binary" "${llama_args[@]}" -n 1 2>&1 <<< "/quit" | tee /dev/stderr)"; then
        ngl_low=$ngl_mid
      else
        if ! echo "$output" | grep -q "cudaMalloc failed"; then
          echo "Unknown failure, dumping output of last run"
          echo "$output"
          exit 2
        fi
        ngl_high=$ngl_mid
      fi
    done
    llama_args+=("-ngl" "$ngl_low")
  else
    echo "Unknown failure, dumping output"
    echo "$output"
    exit 2
  fi
else
  echo "Test run successful, full GPU offload is possible"
fi

if [[ -n "${LLAMA_SERVER_ADD_SPECIAL:-}" ]]; then
  llama_args+=("--special")
fi

echo "Calling llama-server with arguments ${llama_args[*]}"

exec /bin/llama-server "${llama_args[@]}"
