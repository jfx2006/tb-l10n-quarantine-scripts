#!/bin/bash

set -eE

QUARANTINE_PATH="comm-strings-quarantine"
STRINGS_PATH="comm-l10n"

QUARANTINE_URL="https://hg.mozilla.org/projects/comm-strings-quarantine"
STRINGS_URL="https://hg.mozilla.org/projects/comm-l10n"

FILEMAP="/tmp/filemap.txt"
SPLICEMAP="/tmp/splicemap.txt"


die() {
  if [[ -n "$1" ]]; then
    exit $1
  fi
  exit 1
}

hack_hgrc() {
  _rc="$1"
python - "${_rc}" << _EOF_
import sys
import configparser
file = sys.argv[1]
config = configparser.ConfigParser(delimiters=("=",))
config.read(file)
config["paths"]["default:pushurl"] = config["paths"]["default"].replace("https", "ssh")
with open(file, "w") as fp:
    config.write(fp)
_EOF_
}

write_filemap() {
  cat - > $FILEMAP << _EOF_
exclude _configs
rename . en-US
_EOF_
}

write_splicemap() {
  _first_to_convert="$1"
  _tip_of_prev_history="$2"
  if [[ -z "${_first_to_convert}" || -z "${_tip_of_prev_history}" ]]; then
    echo "write_splicemap() didn't receive the right arguments."
    die 6
  fi
  echo "${_first_to_convert} ${_tip_of_prev_history}" > $SPLICEMAP
}

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

update_string_from_quarantine() {
  _qtine="$1"
  _strings="$2"
  
  echo "Updating to strings tip"
  hg up -R "${STRINGS_PATH}" -r tip
  _current_tip=$(hg log -R "${STRINGS_PATH}" \
    -r . \
    --template '{node}\n')


  _last_convert_rev=$(hg log -R "${STRINGS_PATH}" \
    -r 'last(extra("convert_source", "comm-strings-quarantine"))' \
    --template '{get(extras,"convert_revision")}\n')
  if [[ -z "$_last_convert_rev" ]]; then
    _last_convert_rev="-1"
    _first_convert_rev=$(hg log -R "${QUARANTINE_PATH}" \
      -r 0 \
      --template '{node}\n')
  else
    echo "here"
    _first_convert_rev=$(hg log -R "${QUARANTINE_PATH}" \
      -r "first(children(${_last_convert_rev}))" \
      --template '{node}\n')
  fi
  echo "last converted: ${_last_convert_rev}"
  echo "first to convert: ${_first_convert_rev}"

  write_splicemap "${_first_convert_rev}" "${_current_tip}"

  hg convert \
    --config convert.hg.saverev=True \
    --config convert.hg.sourcename="comm-strings-quarantine" \
    --config convert.hg.revs="${_first_convert_rev}:tip" \
    --filemap $FILEMAP \
    --splicemap $SPLICEMAP \
    --datesort \
    "${_qtine}" "${_strings}"

  hg up -R "${STRINGS_PATH}" -r tip
}


clone_repo "$QUARANTINE_URL" "$QUARANTINE_PATH"
clone_repo "$STRINGS_URL" "$STRINGS_PATH"

write_filemap

update_string_from_quarantine "$QUARANTINE_PATH" "$STRINGS_PATH"

# vim: set ts=2 sw=2 sts=2 et tw=80: #
