#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


local -A SP_SESS=()


function sp_w724v__jsonapi () {
  local RQ_RFRSUB="$1"; shift
  local RQ_SUBURL="$1"; shift
  local RQ_DATA="$1"; shift

  local COOKIE_JAR="${SP_COOKIEJAR:-$HOME/.cache/sp_w724v.cookies.txt}"
  >>"$COOKIE_JAR" || return $?

  local SP_HOST="${SP_HOSTNAME:-speedport.ip}"
  local WGET_BASICS=(
    wget
    --load-cookies "$COOKIE_JAR"
    --save-cookies "$COOKIE_JAR"
    --keep-session-cookies
    --no-proxy
    --quiet
    --output-document=-
    --tries=1
    --timeout=10
    --user-agent="$FUNCNAME"
    )
  local RQ_OPT=(
    --referer="http://$SP_HOST/$RQ_RFRSUB"
    )
  local DEST_URL="http://$SP_HOST/$RQ_SUBURL"
  case "$RQ_URL" in
    data/* )
      RQ_OPT+=(
        --header 'Accept: application/json, text/javascript, */*'
        --header 'X-Requested-With: XMLHttpRequest'
      );;
  esac
  [ -n "$RQ_DATA" ] && RQ_OPT+=( --post-data="$RQ_DATA" )
  RQ_OPT+=( "$DEST_URL" )
  # echo "D: wget: ${RQ_OPT[*]}" >&2
  local REPLY="$( "${WGET_BASICS[@]}" "${RQ_OPT[@]}" )"
  echo "$REPLY"
  return 0
}


function sp_w724v__decode_varid_json () {
  LANG=C sed -re '
    s~\s*\]$~,~
    s~\{\s*"vartype":\s*"([A-Za-z0-9_-]+)",\s*"varid":\s*"($\
      |[A-Za-z0-9_-]+)",\s*"varvalue":\s*"?~\n\2\t\1\t~g
    s~(,)("[a-z]+":)\s*~\1\t\2 ~g
    s~^\[\s*~~
    ' | LANG=C sed -re '
    s~(\}?)(\])(\},?)$~\1\n\2\n\3~
    ' | LANG=C sed -re '
    /\[$/{
      : read_array
      N
      /\]$/!b read_array
      s~\n~&    ~g
    }
    s~"?\},?(\n|$)~\1~g
    s~\s+$~~
    /^$/d
    '
}


function sp_w724v__jsonapi_parabar () {
  local REPLY=
  REPLY="$(sp_w724v__jsonapi "$@")" || return $?
  REPLY="$(<<<"$REPLY" sp_w724v__decode_varid_json)"
  REPLY="${REPLY//$'\t'/ ¦ }"
  REPLY="${REPLY//$'\n'/ ¶ }"
  echo "¶ $REPLY ¶"
}


function sp_w724v__login () {
  local PW_MD5="$SP_PASSWD_MD5"
  [ -n "$PW_MD5" ] || return 4$(
    echo "E: $FUNCNAME requires SP_PASSWD_MD5 be set" >&2)

  local RFR='html/login/index.html'
  local URL='data/Login.json'
  local PARABAR="$(sp_w724v__jsonapi_parabar "$RFR" "$URL")"
  case "$PARABAR" in
    *'¶ login ¦ status ¦ true ¶'* )
      echo "D: $FUNCNAME: already logged in."
      return 0;;
    *'¶ login ¦ status ¦ false ¶'* ) ;;
    * )
      echo "E: $FUNCNAME: unable to determine session status." >&2
      return 8;;
  esac

  local TOKEN="$(date +%s)+$RANDOM"
  let TOKEN="$TOKEN"
  local POSTDATA="password=$SP_PASSWD_MD5&showpw=0&httoken=$TOKEN"
  PARABAR="$(sp_w724v__jsonapi_parabar "$RFR" "$URL" "$POSTDATA")"

  case "$PARABAR" in
    *'¶ login ¦ status ¦ success ¶'* )
      echo "D: $FUNCNAME: login: success."
      return 0;;
  esac
  echo "E: $FUNCNAME: failed to login." >&2
  return 8
}










[ "$1" == --lib ] && return 0; sp_w724v__"$@"; exit $?
