#!/bin/bash


set -eE

QUARANTINE_PATH="comm-strings-quarantine"

QUARANTINE_URL="https://hg.mozilla.org/projects/comm-strings-quarantine"

M_C="/home/rob/moz/m-c"
L10N=$(realpath $(dirname $0))

QUARANTINE="$L10N/$QUARANTINE_PATH"
CONFIGS="$QUARANTINE/_configs"


clone_repo() {
  _url="$1"
  _path="$2"

  _pushurl="${_url/https/ssh/}"

  if [[ -d "${_path}" && -d "${_path}/.hg" ]]; then
    hg -R "${_path}" pull -u
  else
    hg clone "${_url}" "${_path}"
    hack_hgrc "${_path}/.hg/hgrc"
  fi
}

clone_repo "$QUARANTINE_URL" "$QUARANTINE_PATH"

source "$L10N/venv/bin/activate"

compare-locales \
	--verbose \
	--full \
	--json /tmp/out.json \
	no_gecko.toml \
	$CONFIGS/mail.toml \
	$CONFIGS/calendar.toml \
	"$L10N" \
	"$QUARANTINE_PATH"
