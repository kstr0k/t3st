#!/bin/sh
set -u
. "${0%/*}"/../k9s0ke_t3st_lib.sh


k9s0ke_t3st_begin

k9s0ke_t3st_one rc=2 out='X' -- \
eval '(echo X; exit 2)'
k9s0ke_t3st_one rc=2 out='X' nl=false -- \
eval '(printf X; exit 2)'
k9s0ke_t3st_one rc=3 out='X' pp='echo "$2"; return $(( $1 + 1 ))' -- \
eval '(printf X; exit 2)'

k9s0ke_t3st_end
