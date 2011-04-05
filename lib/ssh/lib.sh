#f3--&7-9-V13------21-------------------42--------------------64------72

#/// \fn sp_f_ssh_init
#/// \brief common init for ssh functions
function sp_f_ssh_init() {
  local _p_host="${sp_p_hosts}/${_host}"

  if ! test -r "${_p_host}" ; then
    sp_f_err "file ${_p_host} not found"
    exit 1
  fi

  # read info file
  . "${_p_host}"
} # end sp_f_sshinit


#/// \fn sp_f_sshto
#/// \brief ssh login
#///
#/// \param 1 CHARACTER(*) host MID
#/// \param 2 LOGICAL prevent lock checking
function sp_f_sshto() {
  local _host="${1:-default}"
  local _force="${2:-false}"
  local _scrsel="${3}"

  sp_f_ssh_init "${_host}"

  # lock
  local _lck="${_host}.${sp_g_bn}"
  if ${_force} ; then
    sp_f_rmlck "${_lck}"
  fi

  # proxy
  local _proxy=false
  local _opts="${sp_g_ssh_opts}"
  if ! test -z "${sp_g_ssh_proxy}" ; then
    if sp_f_mklck "${_lck}" ; then
      _proxy=true
      _opts="${_opts} ${sp_g_ssh_proxy}"
      sp_f_msg "connect proxies: ${sp_g_ssh_proxy}"
    else
      sp_f_wrn "active proxies: ${sp_g_ssh_proxy}"
    fi
  fi

  # ssh key -----------------------------
  local _p_key="${sp_p_keys}/${_host}${sp_s_key}"
  if test -r "${_p_key}" ; then
    _opts="${_opts} -i ${_p_key}"
  else
    sp_f_wrn "key ${_p_key} not found"
  fi

  local _url="${sp_g_ssh_user}@${sp_g_ssh_fqdn}"
  sp_f_stt "Login to ${_url}"

  # ssh ---------------------------------
  if test "${_scrsel}" != "" ; then
    ${sp_b_ssh} ${_opts} ${_url} ${_scrsel}
  else
    ${sp_b_ssh} ${_opts} ${_url}
  fi
  local _r=$?
  if ${_proxy} ; then
    sp_f_rmlck "${_lck}"
  fi
  return ${_r}
}


function sp_f_sshtx() {
  local _host="${1:-default}"
  local _m="${2:-1}"
  local _src="${3}"
  local _xd=${4:-false}
  local _r=0
  local _dst="./"

  # mode select -------------------------
  local _push=true
  local _mode=$((_m%10))
  if test $((_m/10)) -gt 0 ; then
    _push=false
  fi

  # init --------------------------------
  sp_f_ssh_init "${_host}"

  if ${_xd} ; then
    _dst="${sp_p_scp_local}"
  fi
  local _src_url="${sp_g_ssh_user}@${sp_g_ssh_fqdn}:${sp_p_scp_remote}"
  if ${_push} ; then
    if ! test -r "${_src}" ; then
      sp_f_err "source ${_src} not found"
      return 2
    fi
  else
    local _src_url="${_src_url}/${_src}"
    if ${_xd} ; then
      sp_f_mkdir "${sp_p_scp_local}"
    fi
  fi

  # mode --------------------------------
  case ${_mode} in
    1)
      local _opts="${sp_g_scp_opts}"
      local _url="${_src_url}"
      local _mtxt="scp"
    ;;
    2)
      local _opts="-p ${sp_g_ssh_port}"
      local _url="${sp_g_ssh_user}@${sp_g_ssh_fqdn}"
      local _mtxt="tar/ssh"
    ;;
    3)
      local _opts="-p ${sp_g_ssh_port}"
      local _url="${_src_url}"
      local _mtxt="rsync/ssh"
    ;;
    *) sp_f_err "invalid mode"
       return 3
    ;;
  esac

  # ssh key -----------------------------
  local _p_key="${sp_p_keys}/${_host}${sp_s_key}"
  if test -r "${_p_key}" ; then
    _opts="${_opts} -i ${_p_key}"
  else
    sp_f_wrn "key ${_p_key} not found"
  fi

  # title -------------------------------
  local _dtxt="\n From: ${_src}\n   To: ${_url}"
  if ! ${_push} ; then
    _dtxt="\n From: ${_src_url}\n   To: ${_dst}"
  fi
  sp_f_stt "Transfer (${_mtxt})\n${_dtxt}\n"

  echo ""
  sp_f_yesno "Start?"
  _r=$?
  echo ""
  sp_f_sln
  if test ${_r} -gt 0 ; then return ${_r}; fi

  # transfer ----------------------------
  case ${_mode} in
    1)
      if ${_push} ; then
        ${sp_b_scp} ${_opts} "${_src}" ${_url}
      else
        ${sp_b_scp} ${_opts} ${_url} "${_dst}"
      fi
    ;;
    2)
      if ${_push} ; then
        ${sp_b_tar} cvf - "${_src}" | ${sp_b_ssh} ${_opts} ${_url} "(cd \"${sp_p_scp_remote}\";tar xvf -)"
      else
        ${sp_b_ssh} ${_opts} ${_url} "(cd \"${sp_p_scp_remote}\";tar cvf - \"${_src}\")" | (cd "${_dst}"; ${sp_b_tar} xvf -)
      fi
    ;;
    3)
      if ${_push} ; then
        ${sp_b_rsync} -a -z -v --partial --progress -e "${sp_b_ssh} ${_opts}" "${_src}" ${_url}
      else
        ${sp_b_rsync} -a -z -v --partial --progress -e "${sp_b_ssh} ${_opts}" ${_url} "${_dst}"
      fi
    ;;
  esac
  _r=$?
  sp_f_sln
  echo ""

  return ${_r}
} # end sp_f_sshtx


function sp_f_sshpush() {
  local _h="${1:-default}"
  local _m="${2:-1}"
  local _s="${3}"
  _m=$((_m%10))
  sp_f_sshtx "${_h}" ${_m} "${_s}"
}


function sp_f_sshpull() {
  local _h="${1:-default}"
  local _m="${2:-1}"
  local _s="${3}"
  local _x=${4:-false}
  _m=$((_m%10+10))
  sp_f_sshtx "${_h}" ${_m} "${_s}" ${_x}
}


# ssh misc ----------------------------------------------------------------------
function sp_f_sshchg() {
  local _host="${1:-default}"
  local _mode="${2:-rsa}"

  sp_f_ssh_init "${_host}"

  cd "${sp_p_keys}"
  local _key="${_host}.id_${_mode}"
  if ! test -r "${_key}" ; then
    return 1
  fi
  ${sp_b_sshkey} -p -f "${_key}"
}

function sp_f_sshkey() {
  local _host="${1:-default}"
  local _mode="${2:-rsa}"
  local _size="${3:-2048}"

  sp_f_ssh_init "${_host}"

  cd "${sp_p_keys}"
  local _key="${_host}.id_${_mode}"
  local _key_lnk="${_host}${sp_s_key}"

  local _pkey="${_key}.pub"
  local _pkey_lnk="${_host}${sp_s_pkey}"

  echo ""
  ${sp_b_sshkey} -b ${_size} -t "${_mode}" -f "${_key}"
  local _r=$?

  if test ${_r} -eq 0 ; then
    chmod go-rwx "${_key}"
    sp_f_mklnk "${_key}" "${_key_lnk}"

    chmod go-rwx "${_pkey}"
    sp_f_mklnk "${_pkey}" "${_pkey_lnk}"
  fi

  echo ""
  return ${_r}
}


function sp_f_sshinf() {
  local _host="${1:-default}"

  sp_f_ssh_init "${_host}"

  sp_f_stt "${_host} (${sp_g_ssh_fqdn})"
  echo "ssh url    : ${sp_g_ssh_user}@${sp_g_ssh_fqdn}"
  echo "ssh opts   : ${sp_g_ssh_opts}"
  if ! test -z "${sp_g_ssh_proxy}" ; then
    echo "ssh proxy  : ${sp_g_ssh_proxy}"
  fi
  echo ""
  echo "ssh local  : ${sp_p_scp_local}"
  echo "ssh remote : ${sp_p_scp_remote}"
  echo ""
  echo "sshfs mnt  : ${sp_p_sshfs_local} -> ${sp_g_ssh_user}@${sp_g_ssh_fqdn}:${sp_p_sshfs_remote}"
  echo "sshfs opts : ${sp_g_sshfs_opts}"
  echo ""

  # ssh key -----------------------------
  local _p_pkey="${sp_p_keys}/${_host}${sp_s_pkey}"

  if test -r "${_p_pkey}" ; then
    ${sp_b_sshkey} -v -l -f "${_p_pkey}"
  else
    sp_f_wrn "key ${_p_pkey} not found"
  fi

  return 0
}


# mount -------------------------------------------------------------------------
function sp_f_sshmnt() {
  local _host="${1:-default}"
  local _force="${2:-false}"
  local _mnt="${3:-true}"
  local _r=0

  sp_f_ssh_init "${_host}"

  # lock --------------------------------
  local _lck="${_host}.sshmnt"
  if ${_force} ; then
    sp_f_rmlck "${_lck}"
  fi

  local _dst="${sp_p_sshfs_local}"

  if ${_mnt} ; then
    if ! sp_f_mklck "${_lck}" ; then
      sp_f_err "${_host} is already mounted"
      return 1
    fi
    local _opts="${sp_g_sshfs_opts}"
    # ssh key -----------------------------
    local _p_key="${sp_p_keys}/${_host}${sp_s_key}"
    if test -r "${_p_key}" ; then
      _opts="${_opts} -o IdentityFile=${_p_key}"
    else
      sp_f_wrn "key ${_p_key} not found"
    fi
    local _url="${sp_g_ssh_user}@${sp_g_ssh_fqdn}:${sp_p_sshfs_remote}"

    sp_f_mkdir "${_dst}"

    sp_f_stt "${_dst} -> ${_url}"
    ${sp_b_sshmnt} ${_url} ${_dst} ${_opts} 2>/dev/null
    _r=$?
    if test ${_r} -gt 0 ; then
      sp_f_err "sshfs failure (might run sshreset)"
      sp_f_rmlck "${_lck}"
    else
      sp_f_msg "host mounted"
    fi
  else
    # unmount
    sp_f_stt "${_dst}"
    if ! sp_f_lck "${_lck}" && ! ${_force}; then
      sp_f_err "${_host} is not mounted"
      return 2
    fi
    if ! ${sp_g_debug} ; then
      ${sp_b_sshumnt} ${_dst} 2>/dev/null
    else
      ${sp_b_sshumnt} ${_dst}
    fi
    _r=$?
    if ! test ${_r} -gt 0 ; then
      sp_f_rmlck "${_lck}"
      sp_f_msg "host unmounted"
    fi
  fi
  return ${_r}
}


function sp_f_sshumnt() {
  local _host="${1:-default}"
  local _force="${2:-false}"
  sp_f_sshmnt "${_host}" "${_force}" false
}


function sp_f_sshlmnt() {
  sp_f_ptt "${sp_g_bn}: remote volumes"

  if test -z "${OSTYPE#darwin}"; then
    mount | grep sshfs | awk '{printf "%-32s => %s\n",$3,$1}'
  else
    mount | grep fusefs | awk '{printf "%-32s => %s\n",$3,$1}'
  fi
  return 0
}


function sp_f_sshcmd() {
  local _host="${1:-default}"
  local _cmd="${2:-ls -lA ${sp_p_scp_remote}}"
  local _int=${3:-false}
  local _tmp=""

  sp_f_ssh_init "${_host}"

  local _opts="${sp_g_ssh_opts}"

  # ssh interactive ---------------------
  if ${_int} ; then
    _opts="-t ${_opts}"
  fi

  # ssh key -----------------------------
  local _p_key="${sp_p_keys}/${_host}${sp_s_key}"
  if test -r "${_p_key}" ; then
    _opts="${_opts} -i ${_p_key}"
  else
    sp_f_wrn "key ${_p_key} not found"
  fi

  local _url="${sp_g_ssh_user}@${sp_g_ssh_fqdn}"
  sp_f_stt "Run ${_cmd} on ${_url}"

  # ssh ---------------------------------
  if ! test -z "${sp_g_ssh_env}" ; then
    _tmp="source \${HOME}/${sp_g_ssh_env};"
    _tmp="${_tmp}echo ${sp_g_nruler};"
    _cmd="${_tmp}${_cmd}"
  fi
  ${sp_b_ssh} ${_opts} ${_url} ${_cmd}
}

# encfs -------------------------------------------------------------------------
function sp_f_efskey() {
  local _host="${1:-default}"
  local _force="${2:-false}"

  sp_f_ssh_init "${_host}"

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
    sp_f_err "found ${_p_key}"
    return 1
  fi
  local _etmp="${sp_p_encfs}/.__etmp"
  local _utmp="${sp_p_encfs}/.__utmp"
  for _d in  "{_etmp}" "${_utmp}" ; do
    if test -d "{_d}" ; then
      sp_f_err "found ${_d}"
      return 2
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
  ${sp_b_sshumnt} "${_utmp}"
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

  sp_f_ssh_init "${_host}"

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
      return 1
    fi
    local _opts="${sp_g_efs_opts}"
    # ssh key -----------------------------
    local _p_key="${sp_p_keys}/${_host}${sp_s_ekey}"
    if ! test -r "${_p_key}" ; then
      sp_f_err "${_p_key} not found"
      return 1
    fi

    sp_f_mkdir "${_dst}"
    sp_f_mkdir "${_url}"

    sp_f_stt "${_dst} -> ${_url}"
    if ! ${sp_g_debug} ; then
      ENCFS5_CONFIG="${_p_key}" ${sp_b_encfs} ${_opts} ${_url} ${_dst} # 2>/dev/null
    else
      ENCFS5_CONFIG="${_p_key}" ${sp_b_encfs} ${_opts} ${_url} ${_dst}
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
      return 2
    fi
    if ! ${sp_g_debug} ; then
      ${sp_b_sshumnt} ${_dst} 2>/dev/null
    else
      ${sp_b_sshumnt} ${_dst}
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
