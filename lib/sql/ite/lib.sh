
function sp_f_sl_p_db() {
  echo "${sp_p_sql}/${sp_p_sqlite}${_db}${sp_s_sqlite}"
}

function sp_f_slinit() {
  local _db="${1:-temp}"
  local _p_db="$(sp_f_sl_p_db)"
  local _p_si="${sp_p_db%%${sp_s_sqlite}}.sql"
  local _r
  if ! test -r "${_p_db}" ; then
    touch "${_p_db}"
    ${sp_b_sqlite} "${_p_db}" < "${_p_si}"
    _r=$?
    chmod 600 "${_p_db}"
    return ${_r}
  fi
  sp_f_err "delete ${_p_db}"
  return ${_FALSE_}
}

function sp_f_slquery() {
  local _db="${1:-temp}"
  local _q="${2:-SELECT time()}"
  local _p_db="$(sp_f_sl_p_db)"
  if ! test -r "${_p_db}" ; then
    return ${_FALSE_}
  fi
  ${sp_b_sqlite} "${_p_db}" "${_q}"
}

function sp_f_slqchk() {
  local _db="${1:-temp}"
  local _tab="${2}"
  local _pk="${3}"
  local _pv="${4}"
  local _r=""
  local _p_db="$(sp_f_sl_p_db)"
  if ! test -r "${_p_db}" ; then
    return ${_FALSE_}
  fi
  if test -z "${_tab}" || test -z "${_pk}" || test -z "${_pv}" ; then
    return ${_FALSE_}
  fi
  local _q="SELECT ${_pk} FROM ${_tab} WHERE ${_pk}=\"${_pv}\""
  _r=$(${sp_b_sqlite} "${_p_db}" "${_q}" 2>/dev/null)
  if ! test -z "${_r}" ; then
    return ${_TRUE_}
  fi
  return ${_FALSE_}
}
