

function sp_f_mail() {
  local _sub="${1}"
  local _msg="${2}"
  local _mto="${3}"

  if test -z "${_sub}" || test -z "${_msg}" || test -z "${_mto}" ; then
    return 1
  fi

  sp_f_stt "Sending mail:"
  echo "${_mto}"
  echo -e "${_msg}" | ${sp_b_mail} -s "${_sub}" "${_mto}"
  sleep 5
}
