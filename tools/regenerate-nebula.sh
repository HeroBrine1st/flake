#!/usr/bin/env bash

set -euo pipefail
nebula-cert ca -duration 87600h0m0s -name ca
nebula-cert sign -name alfa -networks 10.168.88.72/24 -groups server
nebula-cert sign -name bravo -networks 10.168.88.57/24 -groups server,cloud
nebula-cert sign -name charlie -networks 10.168.88.25/24 -groups server,cloud
nebula-cert sign -name foxtrot -networks 10.168.88.10/24 -groups server
nebula-cert sign -name DESKTOP-IJK2GUG -networks 10.168.88.254/24 -groups entryhost
nebula-cert sign -name MOBILE-DCV5AQD -networks 10.168.88.96/24 -groups entryhost
