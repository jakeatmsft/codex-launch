#!/usr/bin/env bash
# shellcheck shell=bash

# shellcheck source=./_common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh"

load_codex_local_env

export AZURE_CONFIG_DIR="${AZURE_CONFIG_DIR:-$HOME/.azure-for-codex}"
