#!/usr/bin/env bash

# Build and collect on trusted machine, then boot from usb and verify on untrusted machine
# Does not include /boot and /efi checks
# Assumes reproducible build, where "build" includes copying from trusted cache

set -eo pipefail

# Default values
hash="sha256"
mode="collect"
system_root="/"

pos=()

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --hash)
      hash="$2"
      shift 2
      ;;
    --mode)
      mode="$2"
      shift 2
      ;;
    --root)
      system_root="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    --*)
      echo "Unknown option: $1"
      exit 1
      ;;
    *)
      pos+=("$1")
      shift
      ;;
  esac
done

while [[ $# -gt 0 ]]; do
  pos+=("$1")
  shift
done

if [[ $mode == "collect" ]]; then
  output_path="${pos[0]}"
  hash_path="${pos[1]}"

  if [[ -e $hash_path ]]; then
    echo "File $hash_path already exists, refusting to overwrite" >&2
    exit 1
  fi

  closure=$(nix-store --query --requisites "$output_path")

  declare -A narhash_by_output

  declare -i total
  declare -i counter

  total=$(echo "$closure" | wc -l)
  counter=0

  echo ""

  for output in $closure; do
    tput cuu1
    tput el
    echo "Hashing progress: $counter/$total (calculating $(basename "$output"))"

    narhash_by_output[$output]="$(nix --extra-experimental-features nix-command hash path --type "$hash" --base32 "$output")"
    counter+=1
  done

  tput cuu1
  tput el

  echo "Hashing complete"

  res_path="$hash_path"

  if [[ $mode == "verify" ]]; then
    res_path="$(mktemp)"
  fi

  touch "$res_path"
  for output in $(printf "%s\n" "${!narhash_by_output[@]}" | sort); do
    echo "$output ${narhash_by_output[$output]}" >> "$res_path"
  done

  echo "Hashes are stored in $res_path"
  exit 0
elif [[ $mode == "verify" ]]; then
  hash_path="${pos[0]}"

  declare -i total
  declare -i counter

  total=$(wc -l "$hash_path" | awk '{print $1}')
  counter=0
  failed=false

  echo ""

  while IFS= read -r line; do
    output_path="$system_root/$(echo "$line" | awk '{print $1}')"

    tput cuu1
    tput el
    echo "Checking progress: $counter/$total (calculating $(basename "$output_path"))"

    valid_hash="$(echo "$line" | awk '{print $2}')"

    current_hash="$(nix --extra-experimental-features nix-command hash path --type "$hash" --base32 "$output_path")"
    if [[ "$valid_hash" != "$current_hash" ]]; then
      echo "Output $output_path is not valid! Provided hash is '$valid_hash', actual hash is '$current_hash'"
      failed=true
    fi
    counter+=1

  done < "$hash_path"

  tput cuu1
  tput el

  if [[ $failed == true ]]; then
    echo "Found differences"
    exit 1
  else
    echo "Found no differences"
  fi
else
  echo "Mode $mode is invalid! Valid modes: collect, verify"
  exit 1
fi
