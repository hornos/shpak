#f3--&7-9-V13------21-------------------42--------------------64------72

#/// \fn sp_f_mail
#/// \brief send e-mail
#///
#/// \param 1 CHARACTER(*) recepient address
#/// \param 2 CHARACTER(*) subject
#/// \param 3 CHARACTER(*) mail body
function sp_f_mail() {
  local _mto="${1}"
  local _sub="${2}"
  local _msg="${3}"

  if test -z "${_sub}" || test -z "${_msg}" || test -z "${_mto}" ; then
    return ${_FALSE_}
  fi

  sp_f_stt "Sending mail:"
  echo "${_mto}"
  echo -e "${_msg}" | ${sp_b_mail} -s "${_sub}" "${_mto}"
  sleep 5
}
