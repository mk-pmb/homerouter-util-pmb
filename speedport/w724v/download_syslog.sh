#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function download_syslog () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local SELFPATH="$(readlink -m "$BASH_SOURCE"/..)"

  source "$SELFPATH"/lib_sp_w724v.sh --lib || return $?

  local LOG_BFN="${SP_LOGSDIR:-.}/$(date +%Y-%m/%y%m%d.%H%M%S).$$."
  mkdir --parents -- "${LOG_BFN%/*}" || return $?
  sp_w724v__login || return $?

  local RFR='html/content/config/system_info.html'
  local URL="$RFR"
  local REPLY="$(sp_w724v__jsonapi "$RFR" "$URL")"
  local RGX='\s*var\s+_httoken\s*=\s*(\d+)\s*;\s*'
  local TOKEN="$(<<<"$REPLY" LANG=C grep -xPe "$RGX" -m 1 \
    | grep -oPe '\d+' -m 1)"
  [ -n "$TOKEN" ] || return 3$(echo "E: unable to get an _httoken" >&2)

  URL="data/SystemMessages.json?_tn=$TOKEN"
  REPLY="$(sp_w724v__jsonapi "$RFR" "$URL")" || return $?
  local SED_MSGS='
    /^addmessage\ttemplate\t\[/{
      : read_more
      N
      /\]$/!b read_more
      s~^[a-z\t]+\[~~
      s~\s*\]$~~
      s~\n\s*id\s+value\s+[0-9]+\n\s+timestamp\s+value\s+($\
        |[0-9]{2})\.([0-9]{2})\.([0-9]{4}) ~\3-\2-\1,~
      s~\s*\n\s+message\s+value\s+~ ~
      s~\&lt;~‹~g
      s~\&gt;~›~g
      s~\&#40;~\(~g
      s~\&#41;~\)~g
      s~\&#46;~\.~g
      s~\n~¶~g
    }'
  REPLY="$(<<<"$REPLY" sp_w724v__decode_varid_json | LANG=C sed -re "
    $SED_MSGS")"
  local META="${REPLY%%$'\n'20*}"
  <<<"$META" sort -V >"$LOG_BFN"meta.txt || return $?
  REPLY="${REPLY:${#META}}"
  REPLY="${REPLY#$'\n'}"
  <<<"$REPLY" tac >"$LOG_BFN"log.txt || return $?
  echo "D: saved as ${LOG_BFN}{meta,log}.txt"
  return 0
}










[ "$1" == --lib ] && return 0; download_syslog "$@"; exit $?
