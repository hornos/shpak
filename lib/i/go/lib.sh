
sp_g_gtu="http://ajax.googleapis.com/ajax/services/language/translate?v=1.0"

sp_f_gt() {
  # http://www.devharb.com/a-handy-bash-function-leveraging-google-api-to-do-translation-job-in-terminal/
  local _s="${1:-hello world}"
  local _f=${2:-en}
  local _t=${3:-hu}
  local _r=""
  _r=$(wget -qO- "${sp_g_gtu}&q=\"${_s}\"&langpair=${_f}|${_t}" \
  | sed -E -n 's/[[:alnum:]": {}]+"translatedText":"([^"]+)".*/\1/p' \
  | sed s/\u0026//g | sed s/\\\\quot\;//g )
  if test "${_r}" = "" ; then
    return 1
  fi
  echo ${_r}
  return 0
}
