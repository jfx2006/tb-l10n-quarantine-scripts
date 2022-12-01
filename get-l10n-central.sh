#!/bin/bash

set -e

# all-locales file comes from this plus additional locales below
# curl --retry 3 --output all-locales \
#  https://hg.mozilla.org/comm-central/raw-file/tip/mail/locales/all-locales
#for _l in bs hye ia km xcl; do
#  echo $_l >> all-locales
#done
#sort -o all-locales.tmp all-locales
#mv -f all-locales.tmp all-locales

LANGS=$(cat all-locales)

# These are used in the function called by parallel and must be exported as
# a subprocess is used
export L10N="l10n-central"
export L10N_CENTRAL="https://hg.mozilla.org/l10n-central"

if [[ ! -d "$L10N" ]]; then
  echo "$L10N directory not present. mkdir one first."
  exit 67
fi

update_lang() {
  pwd
  L="$1"
  echo "Updating lang $L"
  if [[ ! -d "$L10N/$L" ]]; then
    rm -rf "$L10N/$L"
    hg clone "$L10N_CENTRAL/$L" "$L10N/$L"
  else
    hg -R "$L10N/$L" pull
    hg -R "$L10N/$L" up tip
  fi
  echo "Finished $L"
}
export -f update_lang

test_lang() {
  L="$1"
  echo "Updating lang $L"
  sleep 4
  echo "Finished $L"
}
export -f test_lang

parallel -j 8 --color --linebuffer update_lang ::: $LANGS

