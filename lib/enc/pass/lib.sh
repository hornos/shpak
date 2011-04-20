
function sp_f_passdb() {
  sp_f_load sql/ite
  echo -e "\nCreating database ${sp_g_accdb}\n"
  sp_f_slinit "${sp_g_accdb}"
}

function sp_f_passkey() {
  sp_f_load sql/ite
  sp_f_load gui

  local _p=${1:-s}
  local _a="${2}"
  local _l=${3:-60}
  local _er=""
  local _r=""
  local _q=""
  local _m=""
  local _date=$(date +%Y-%m-%d)

  if ! test -r "${sp_p_sql}/${sp_p_sqlite}${sp_g_accdb}${sp_s_sqlite}" ; then
    sp_f_err "database"
    return ${_FALSE_}
  fi

  if test -z "${_a}" ; then
    return ${_FALSE_}
  fi

  ### delete
  _m="Delete"
  if test "${_p}" = "d" ; then
    if ! sp_f_slqchk "${sp_g_accdb}" "${sp_g_acctab}" "${sp_g_acctab}" "${_a}" ; then
      return ${_FALSE_}
    fi

    # check
    echo -e "\n${_m} - Check old key password"
    _er=$(sp_f_slquery "${sp_g_accdb}" "SELECT pass FROM ${sp_g_acctab} WHERE ${sp_g_acctab}=\"${_a}\"")
    _r=$(gpgstr -d -s "${_er}")
    if test "${_r}" = "" ; then
      sp_f_err "password"
      return ${_FALSE_}
    fi

    sp_f_yesno "${_m} - Do you really want to delete?"
    if test $? -gt 0 ; then
      return ${_FALSE_}
    fi

    _q="DELETE FROM ${sp_g_acctab} WHERE ${sp_g_acctab}=\"${_a}\""

    # query
    sp_f_slquery "${sp_g_accdb}" "${_q}"
    if test $? -gt 0 ; then
      sp_f_err "delete"
      return ${_FALSE_}
    fi
    echo -e "\n${_m} - Key deleted"
    return ${_TRUE_}
  fi

  ### select
  _m="Select"
  if test "${_p}" = "s" ; then
    if ! sp_f_slqchk "${sp_g_accdb}" "${sp_g_acctab}" "${sp_g_acctab}" "${_a}" ; then
      return ${_FALSE_}
    fi

    _er=$(sp_f_slquery "${sp_g_accdb}" "SELECT pass FROM ${sp_g_acctab} WHERE ${sp_g_acctab}=\"${_a}\"")
    _r=$(gpgstr -d -s "${_er}")
    if test "${_r}" = "" ; then
      sp_f_err "password"
      return ${_FALSE_}
    fi
    echo -e "\n>>$(sp_f_ctxt "${_r}" "black" "black")<<\n"
    unset _r
    echo -n "Press Enter..."
    read
    clear
    return ${_TRUE_}
  fi

  ### update
  _m="Update"
  if sp_f_slqchk "${sp_g_accdb}" "${sp_g_acctab}" "${sp_g_acctab}" "${_a}" ; then
    # check
    echo -e "\n${_m} - Check old key password"
    _er=$(sp_f_slquery "${sp_g_accdb}" "SELECT pass FROM ${sp_g_acctab} WHERE ${sp_g_acctab}=\"${_a}\"")
    _r=$(gpgstr -d -s "${_er}")
    if test "${_r}" = "" ; then
      sp_f_err "password"
      return ${_FALSE_}
    fi

    sp_f_yesno "${_m} - Do you really want to update?"
    if test $? -gt 0 ; then
      return ${_FALSE_}
    fi

    echo -e "\n${_m} - Set new key password (${_l})"
    _er=$(gpgstr -s "$(rndstr -q -l ${_l})") #"
    _q="UPDATE ${sp_g_acctab} SET pass=\"${_er}\",mtime=\"${_date}\" WHERE ${sp_g_acctab}=\"${_a}\""

    # query
    sp_f_slquery "${sp_g_accdb}" "${_q}"
    if test $? -gt 0 ; then
      sp_f_err "update"
      return ${_FALSE_}
    fi
    echo -e "\n${_m} - Key updated"
    return ${_TRUE_}
  fi

  ### insert
  _m="Insert"
  sp_f_yesno "${_m} - Do you really want to insert?"
  if test $? -gt 0 ; then
    return ${_FALSE_}
  fi

  echo -e "\n${_m} - Set new key password (${_l})"
  _er=$(gpgstr -s "$(rndstr -q -l ${_l})") #"
  _q="INSERT INTO ${sp_g_acctab} (${sp_g_acctab},pass,ctime,mtime) VALUES (\"${_a}\",\"${_er}\",\"${_date}\",\"${_date}\")"

  sp_f_slquery "${sp_g_accdb}" "${_q}"
  if test $? -gt 0 ; then
    sp_f_err "update"
    return ${_FALSE_}
  fi
  echo -e "\n${_m} - Key inserted"
  return ${_TRUE_}
}
