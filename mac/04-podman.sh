#!/bin/bash
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"
parse_args "$@"
require_mac
[ -z "$CONFIG_DIR" ] || die '--config-dir is only valid for stage 3.'
require_brew
bundle Brewfile.podman
log 'Podman installed. No virtual machine has been created or started.'
log 'When ready: podman machine init; podman machine start; podman info; podman run --rm quay.io/podman/hello'
