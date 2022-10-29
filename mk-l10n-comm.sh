#!/bin/bash

set -eE

LC="l10n-central"

LANGS=$(cat all-locales)

FILEMAP="/tmp/filemap.txt"
FILEMAP_IN="/tmp/filemap.txt.in"
SPLICEMAP="/tmp/splicemap.txt"

L10N_COMM="l10n-comm"

get_first() {
  hg -R "$LC/$1" log -r 'first(date(">2021-05-31"))' --template '{node}\n'
}

get_next() {
  hg -R "$LC/$1" log -r "first(children($2))" --template '{node}\n'
}

get_tip() {
  hg -R $L10N_COMM log -r tip --template '{node}\n'
}


cat - > $FILEMAP_IN << _EOF_
include calendar
include chat
include mail
include suite
rename . @LANG@
_EOF_


hg init $L10N_COMM

for L in $LANGS; do
  sed -e "s/@LANG@/$L/" $FILEMAP_IN > $FILEMAP
  
  _first=$(get_first "$L")
  _second=$(get_next "$L" "$_first")
  _tip=$(get_tip)
  echo "$_first $_tip" > $SPLICEMAP

  hg convert \
    --config convert.hg.saverev=True \
    --config convert.hg.sourcename="l10n-central" \
    --config convert.hg.revs="$_first:$_first" \
    --filemap $FILEMAP \
    --splicemap $SPLICEMAP \
    "$LC/$L" $L10N_COMM

  _tip=$(get_tip)
  _lang=$(hg -R $L10N_COMM log -r tip --template "{sub('/.*$', '', min(file_adds))}")
  _newmsg="l10n-comm import from l10n-central: $_lang"
  hg -R $L10N_COMM metaedit -r $_tip -U -m "$_newmsg"
  
  _tip=$(get_tip)
  echo "$_second $_tip" > $SPLICEMAP

  hg convert \
    --config convert.hg.saverev=True \
    --config convert.hg.sourcename="l10n-central" \
    --config convert.hg.revs="$_second:tip" \
    --filemap $FILEMAP \
    --splicemap $SPLICEMAP \
    "$LC/$L" $L10N_COMM

  hg -R $L10N_COMM up tip
done


