#!/bin/bash

set -eE

cat - > /tmp/filemap.txt << _EOF_
include calendar
include chat
include mail
include suite
include _configs/calendar.toml
include _configs/mail.toml
include _configs/suite.toml
include _configs/suite-chatzilla.toml
_EOF_

hg convert \
    --config convert.hg.saverev=True \
    --config convert.hg.sourcename="gecko-strings-quarantine" \
    --config convert.hg.revs="28badc57c567d634c4cd45a0f8dc0a30fe8716ed:tip" \
    --filemap /tmp/filemap.txt \
    --datesort \
    gecko-strings-quarantine comm-strings-quarantine
