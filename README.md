# Thunderbird L10n Quarantine Scripts

This repository is a collection of scripts used for the creation and ongoing
maintenance of the comm-strings-quarantine and l10n-comm Mercurial repositories
for Thunderbird.
These repositories are used for localized builds of Mozilla Thunderbird. This
repository is not needed to build Thunderbird in any language, and the scripts
are meant to be run by Thunderbird build or localization engineers.

## Requirements

A Python interpreter is needed as well as Mercurial. Some scripts also need
GNU Parallel installed. https://www.gnu.org/software/parallel/

## Quick note about how these work

The `hg convert` commands all record the converted changeset revision and
source data. This information is then used by `update-from-l10n-central.sh` and
`quarantine-to-strings.sh` to find the next revision to convert when updating
`l10n-comm` later.

## The scripts

#### mk-quarantine.sh

Used once to populate "comm-strings-quarantine". It's just a simple `hg convert`
command. There is a hardcoded starting revision that is the first commit to
"gecko-strings-quarantine" with relevant strings on 2021-06-01. It's assumed
that a clone of "gecko-strings-quarantine" and an empty "comm-strings-quarantine"
repository are in the current directory.

#### get-l10n-central.sh

Just a script to clone and update the necessary repositories from l10n-central.
It assumes the l10n-central repositories are destined for a directory named
"l10n-central" in the current directory. It must already exist, even if it's
empty.

#### mk-l10n-comm.sh

This one starts to get fun. It creates the l10n-comm monorepository that is
all supported locales plus the en-US source language. To do this, it converts
the l10n-central repositories for each language, putting each into a subdirectory,
only including what's needed. Like `mk-quarantine.sh`, it starts with the first
relevant revision on 2021-06-01.

Before running, you need to run "get-l10n-central.sh". When done, you will have
a "comm-l10n" repository. **It will not have the source en-US locale yet.**

There's some crazy splicemap stuff going on and some light commit message
rewriting. The result is a single branch with everything nice and linear, but
not in date order. That could be done, but was sort of a pain to make work
and took forever so I decided to live with the initial imports not being in
proper date order.

#### update-from-l10n-central.sh

Since there was to be a period of time between initializing l10n-comm on hg.m.o
and when Pontoon would start using it, this script was written to update l10n-comm
from new commits to the l10n-central repositories.

Obviously, you've run `mk-l10n-comm.sh` already. Before running this script every
few days to bring in updated strings, run `get-l10n-central.sh` so the local
copies of the l10n-central repositories are up to date.

This script is nuts with some of the `hg log` revision queries and templates,
but it works great.

#### quarantine-to-strings.sh

This is the one script meant to run indefinitely every day or two or whatever.
Once the l10n-cross-channel cron task runs on comm-central and updates 
comm-strings-quarantine with new strings, the responsible person reviews those
changes and then updates `l10n-comm`'s "en-US" directory. As mentioned above,
"en-US" won't exist after running `mk-l10n-comm.sh`, and `update-from-l10n-central.sh`
won't create it either. The first time this script runs, it should create
the "en-US" subdirectory and convert the entire history.
Subsequent runs will convert new commits that are not in `l10n-comm` yet.

