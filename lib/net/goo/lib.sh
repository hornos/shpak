#f3--&7-9-V13------21-------------------42--------------------64------72
### GLOBALS

#/// \var sp_g_gtu
#/// \brief Google translate api url
sp_g_gtu="http://ajax.googleapis.com/ajax/services/language/translate?v=1.0"


#f3--&7-9-V13------21-------------------42--------------------64------72
### FUNCTIONS

#/// \fn sp_f_wbb
#/// \brief call Google translate api
#///
#/// Calls Google translate api by wget
#/// URL http://ajax.googleapis.com/ajax/services/language/translate?v=1.0
#///
#/// \param _s CHARACTER(*) text to translate
#/// \param _f CHARACTER(2) from language
#/// \param _t CHARACTER(3) to language
#/// \param _x INTEGER wget timeout
sp_f_wbb() {
  # http://www.devharb.com/a-handy-bash-function-leveraging-google-api-to-do-translation-job-in-terminal/
  local _s="${1:-sok alma}"
  local _f=${2:-hu}
  local _t=${3:-tr}
  local _x=${4:-3}
  local _r=""
  _r=$(wget -T ${_x} -qO- "${sp_g_gtu}&q=\"${_s}\"&langpair=${_f}|${_t}" \
  | ${sp_b_sede} -n 's/[[:alnum:]": {}]+"translatedText":"([^"]+)".*/\1/p' \
  | sed s/\u0026//g | sed s/\\\\quot\;//g )
  if test "${_r}" = "" ; then
    return ${_FALSE_}
  fi
  echo $(sp_f_lc "${_r}")
  return ${_TRUE_}
}
