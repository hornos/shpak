
function sp_f_pg() {
  local _url="${1}"
  local _f="${2}"
  local _usr=${_url%%@*}
  local _host=${_url##*@}
  _host=${_host%%:*}
  local _port=${_url##*:}
  _port=${_port%%/*}
  local _db=${_url##*/}

  if test "${_f}" == "" ; then
    ${sp_b_pgsql} -U "${_usr}" -h "${_host}" -p "${_port}" -d "${_db}"
    return $?
  fi

  if ! test -r "${_f}" ; then
    sp_f_err_fnf "${_f}"
    return 1
  fi

  ${sp_b_pgsql} -U "${_usr}" -h "${_host}" -p "${_port}" -d "${_db}" -f "${_f}"
}