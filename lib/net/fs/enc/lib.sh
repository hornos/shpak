#f3--&7-9-V13------21-------------------42--------------------64------72

# encfs -------------------------------------------------------------------------
function sp_f_efskey() {
  local _host="${1:-default}"
  local _force="${2:-false}"

  sp_f_mid_init "${_host}"

  local _r=$?
  local _key="${_host}${sp_s_ekey}"
  local _p_key="${sp_p_keys}/${_key}"

  echo ""

  if ${_force} ; then
    if test -r "${_p_key}" ; then
      echo "${_p_key}"
      sp_f_yesno "Delete key?"
      _r=$?
      if test ${_r} -gt 0 ; then
        return ${_r}
      else
        rm -f "${_p_key}"
      fi
    fi
  fi

  if test -r "${_p_key}" ; then
    sp_f_err_fnf "${_p_key}"
    return ${_FALSE_}
  fi
  local _etmp="${sp_p_encfs}/.__etmp"
  local _utmp="${sp_p_encfs}/.__utmp"
  for _d in  "{_etmp}" "${_utmp}" ; do
    if test -d "{_d}" ; then
      sp_f_err_fnf "${_d}"
      return ${_FALSE_}
    fi
  done
  mkdir -p "${_etmp}" "${_utmp}"

  ${sp_b_encfs} ${sp_g_efs_opts} "${_etmp}" "${_utmp}"
  _r=$?
  if test ${_r} -gt 0 ; then
    rm -fR "${_etmp}"
    rm -fR "${_utmp}"
    return ${_r}
  fi

  echo "Generating key..."
  sleep 2
  ${sp_b_fsumnt} "${_utmp}"
  _r=$?
  if test ${_r} -gt 0 ; then
    return ${_r}
  fi

  mv "${_etmp}/${sp_s_ekey}" "${_p_key}"
  rm -fR "${_etmp}"
  rm -fR "${_utmp}"

  echo ""
  return ${_r}
}


function sp_f_efsmnt() {
  local _host="${1:-default}"
  local _force="${2:-false}"
  local _mnt="${3:-true}"
  local _r=0

  sp_f_mid_init "${_host}"

  # lock --------------------------------
  local _lck="${_host}.efsmnt"
  if ${_force} ; then
    sp_f_rmlck "${_lck}"
  fi

  local _dst="${sp_p_efs_udir}"
  local _url="${sp_p_efs_edir}"
  local _pre=""

  if ${_mnt} ; then
    if ! sp_f_mklck "${_lck}" ; then
      sp_f_err "${_host} is already mounted"
      return ${_FALSE_}
    fi
    local _opts="${sp_g_efs_opts}"
    # key -----------------------------
    local _p_key="${sp_p_keys}/${_host}${sp_s_ekey}"
    if ! test -r "${_p_key}" ; then
      sp_f_err_fnf "${_p_key}"
      return ${_FALSE_}
    fi

    sp_f_mkdir "${_dst}"
    sp_f_mkdir "${_url}"

    sp_f_stt "${_dst} -> ${_url}"
    if ${sp_g_debug} ; then
      sp_f_deb "ENCFS5_CONFIG=\"${_p_key}\" ${sp_b_encfs} ${_opts} ${_url} ${_dst}"
      ENCFS5_CONFIG="${_p_key}" ${sp_b_encfs} ${_opts} ${_url} ${_dst}
    else
      ENCFS5_CONFIG="${_p_key}" ${sp_b_encfs} ${_opts} ${_url} ${_dst} 2>/dev/null
    fi
    _r=$?
    if test ${_r} -gt 0 ; then
      sp_f_rmlck "${_lck}"
    else
      sp_f_msg "encfs mounted"
    fi
  else
    # unmount
    sp_f_stt "${_dst}"
    if ! sp_f_lck "${_lck}" && ! ${_force}; then
      sp_f_err "${_host} is not mounted"
      return ${_FALSE_}
    fi
    if ${sp_g_debug} ; then
      sp_f_deb "${sp_b_fsumnt} ${_dst}"
      ${sp_b_fsumnt} ${_dst}
    else
      ${sp_b_fsumnt} ${_dst} 2>/dev/null
    fi
    _r=$?
    if ! test ${_r} -gt 0 ; then
      sp_f_rmlck "${_lck}"
      sp_f_msg "encfs unmounted"
    fi
  fi

  return ${_r}
}

function sp_f_efsumnt() {
  local _host="${1:-default}"
  local _force="${2:-false}"
  sp_f_efsmnt "${_host}" "${_force}" false
}


function sp_f_efslmnt() {
  sp_f_ptt "${sp_g_bn}: encfs volumes"
  mount | grep fusefs | grep encfs | awk '{printf "%-32s\n",$3}'
  return ${_TRUE_}
}
