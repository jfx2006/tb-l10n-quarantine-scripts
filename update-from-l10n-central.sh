#!/bin/bash -xv

set -eE

STRINGS_PATH="comm-l10n"

export LC="l10n-central"
LANGS=$(cat all-locales)

FILEMAP="/tmp/filemap.txt"
SPLICEMAP="/tmp/splicemap.txt"


get_next() {
  _rv=$(hg --cwd "$LC/$1" log \
    -r "first( \
      descendants($2) and \
        (file(\"calendar/**\") or \
         file(\"mail/**\") or \
         file(\"chat/**\") or \
         file(\"suite/**\")), \
        1,1)" \
        --template '{node}\n') || return $?
  if [[ -z "$_rv" ]]; then
    return 4
  fi
  echo "$_rv" && return 0
}

get_tip() {
  hg -R "$STRINGS_PATH" log -r tip --template '{node}\n'
}

last_converted_lang() {
  L="$1"
  /usr/bin/hg --cwd "$STRINGS_PATH" log \
    -r "last(file(\"$L/**\"))" \
    --template '{get(extras, "convert_revision")}\n' \
    "$L"
}


update_lang() {
  L="$1"
  _last_converted=$(last_converted_lang "$L")
  echo "Lang: $L Last converted: $_last_converted"
  if _first_to_convert=$(get_next "$L" "$_last_converted") ; then
    echo "First to convert: $_first_to_convert"
  else
    echo "Nothing to convert for $L"
    return
  fi
  _tip_of_strings=$(get_tip)
  echo "$_first_to_convert $_tip_of_strings" > $SPLICEMAP
  sed -e "s/@LANG@/$L/" filemap.txt.in > $FILEMAP

  hg convert \
    --config convert.hg.saverev=True \
    --config convert.hg.sourcename="l10n-central" \
    --config convert.hg.revs="$_first_to_convert:tip" \
    --filemap $FILEMAP \
    --splicemap $SPLICEMAP \
    "$LC/$L" "${STRINGS_PATH}"

  hg -R "${STRINGS_PATH}" up tip
}

for _L in $LANGS; do
 update_lang "$_L"
done 

# vim: set ts=2 sw=2 sts=2 et tw=80: #
