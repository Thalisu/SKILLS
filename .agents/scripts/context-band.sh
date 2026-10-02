#!/usr/bin/env bash
# context-band.sh: the band a context figure falls in, at the thresholds ADR 0016 gives a ticket.
# It is the one executable form of the rule, so every script that prints a band calls it instead
# of restating the thresholds (ADR 0068). Run from anywhere.
#
#   context-band.sh <tokens>    a figure in tokens, a plain non-negative integer
#
# Prints band=<small|medium|large>: small under 150k, medium up to 200k, large beyond.
# Exit codes: 0 · 2 usage: no figure, more than one, or one that is not a non-negative integer;
# nothing is printed on stdout then
set -uo pipefail

usage() { echo "usage: context-band.sh <tokens>" >&2; exit 2; }

# ADR 0016: a ticket fits a session up to 200k, and under 150k leaves room to fold a neighbour in.
small_below=150000
medium_up_to=200000

[ "$#" = 1 ] || usage
case "$1" in "" | *[!0-9]*) usage ;; esac
tokens="$1"
if [ "$tokens" -lt "$small_below" ]; then band=small; elif [ "$tokens" -le "$medium_up_to" ]; then band=medium; else band=large; fi
echo "band=$band"
