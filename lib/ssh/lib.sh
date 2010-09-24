# common ------------------------------------------------------------------------
function sp_f_sshinit() {
  local _p_host="${sp_p_hosts}/${_host}"

  if ! test -r "${_p_host}" ; then
    sp_f_err "file ${_p_host} not found"
    exit 1
  fi

  # read info file
  . "${_p_host}"
} # end sp_f_sshinit


# login -------------------------------------------------------------------------
function sp_f_sshlogin() {
  local _host="${1:-default}"
  local _force="${2:-false}"

  sp_f_sshinit "${_host}"

  # lock --------------------------------
  local _lck="${_host}.${sp_g_bn}"
  if ${_force} ; then
    sp_f_lck_delete "${_lck}"
  fi

  # proxy -------------------------------
  local _proxy=false
  local _opts="${sp_g_ssh_opts}"
  if ! test -z "${sp_g_ssh_proxy}" ; then
    if sp_f_lck_create "${_lck}" ; then
      _proxy=true
      _opts="${_opts} ${sp_g_ssh_proxy}"
    else
      sp_f_warn "active proxies: ${sp_g_ssh_proxy}"
    fi
  fi

  # ssh key -----------------------------
  local _p_key="${sp_p_keys}/${_host}${sp_g_key_ext}"
  if test -r "${_p_key}" ; then
    _opts="${_opts} -i ${_p_key}"
  else
    sp_f_warn "key ${_p_key} not found"
  fi

  local _url="${sp_g_ssh_user}@${sp_g_ssh_fqdn}"
  sp_f_stt "Login to ${_url}"

  # ssh ---------------------------------
  ${sp_p_ssh} ${_opts} ${_url}
  local _r=$?
  if ${_proxy} ; then
    sp_f_lck_delete "${_lck}"
  fi
  return ${_r}
} # end sp_f_sshlogin


function sp_f_sshtx() {
  local _host="${1:-default}"
  local _m="${2:-1}"
  local _src="${3}"

  # mode select -------------------------
  local _push=true
  local _mode=$((_m%10))
  if test $((_m/10)) -gt 0 ; then
    _push=false
  fi

  # init --------------------------------
  sp_f_sshinit "${_host}"

  local _dst="${sp_p_scp_local}"
  local _src_url="${sp_g_ssh_user}@${sp_g_ssh_fqdn}:${sp_p_scp_remote}"
  if ${_push} ; then
    if ! test -r "${_src}" ; then
      sp_f_err "source ${_src} not found"
      return 2
    fi
  else
    local _src_url="${_src_url}/${_src}"
    sp_f_dir_create "${sp_p_scp_local}"
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
  local _p_key="${sp_p_keys}/${_host}${sp_g_key_ext}"
  if test -r "${_p_key}" ; then
    _opts="${_opts} -i ${_p_key}"
  else
    sp_f_warn "key ${_p_key} not found"
  fi

  # title -------------------------------
  local _dtxt="\n From: ${_src}\n   To: ${_url}"
  if ! ${_push} ; then
    _dtxt="\n From: ${_url}\n   To: ${_dst}"
  fi
  sp_f_stt "Transfer (${_mtxt}) ${_dtxt}"

  sp_f_yesno "Start?"
  if test $? -gt 0 ; then return $?; fi

  # transfer ----------------------------
  case ${_mode} in
    1)
      if ${_push} ; then
        ${sp_p_scp} ${_opts} "${_src}" ${_url}
      else
        ${sp_p_scp} ${_opts} ${_url} "${_dst}"
      fi
    ;;
    2)
      if ${_push} ; then
        ${sp_p_tar} cvf - "${_src}" | ${sp_p_ssh} ${_opts} ${_url} "(cd \"${sp_p_scp_remote}\";tar xvf -)"
      else
        ${sp_p_ssh} ${_opts} ${_url} "(cd \"${sp_p_scp_remote}\";tar cvf - \"${_src}\")" | (cd "${_dst}"; ${sp_p_tar} xvf -)
      fi
    ;;
    3)
      if ${_push} ; then
        ${sp_p_rsync} -a -z -v --partial --progress -e "${sp_p_ssh} ${_opts}" "${_src}" ${_url}
      else
        ${sp_p_rsync} -a -z -v --partial --progress -e "${sp_p_ssh} ${_opts}" ${_url} "${_dst}"
      fi
    ;;
  esac

  return $?
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
  _m=$((_m%10+10))
  sp_f_sshtx "${_h}" ${_m} "${_s}"
}


# ssh misc ----------------------------------------------------------------------
function sp_f_sshkeygen() {
  local _host="${1:-default}"
  local _mode="${2:-rsa}"
  local _size="${3:-2048}"

  sp_f_sshinit "${_host}"

  cd "${sp_p_keys}"
  local _key="${_host}.id_${_mode}"
  local _lnk="${_host}${sp_g_key_ext}"

  ${sp_p_sshkey} -b ${_size} -t "${_mode}" -f "${_key}"
  local _r=$?

  if test ${_r} -eq 0 ; then
    chmod go-rwx "${_key}"
    chmod go-rwx "${_key}.pub"
    sp_f_lnk_create "${_key}" "${_lnk}"
  fi

  return ${_r}
} # end sp_f_sshkeygen


function sp_f_sshinfo() {
  local _host="${1:-default}"

  sp_f_sshinit "${_host}"

  sp_f_stt "${_host} (${sp_g_ssh_fqdn})"
  echo "ssh url    : ${sp_g_ssh_user}@${sp_g_ssh_fqdn}"
  echo "ssh opts   : ${sp_g_ssh_opts}"
  if ! test -z "${sp_g_ssh_proxy}" ; then
    echo "ssh proxy  : ${sp_g_ssh_proxy}"
  fi
  echo ""
  echo "ssh tx loc : ${sp_p_scp_local}"
  echo "ssh tx rem : ${sp_p_scp_remote}"
  echo ""
  echo "sshfs mnt  : ${sp_p_sshfs_local} -> ${sp_g_ssh_user}@${sp_g_ssh_fqdn}:${sp_p_sshfs_remote}"
  echo "sshfs opts : ${sp_g_sshfs_opts}"
  echo ""
  return 0
}


# mount -------------------------------------------------------------------------
function sp_f_sshmnt() {
  local _host="${1:-default}"
  local _force="${2:-false}"
  local _mnt="${3:-true}"

  sp_f_sshinit "${_host}"

  local _dst="${sp_p_sshfs_local}"

  if ${_mnt} ; then
    local _opts="${sp_g_sshfs_opts}"
    # ssh key -----------------------------
    local _p_key="${sp_p_keys}/${_host}${sp_g_key_ext}"
    if test -r "${_p_key}" ; then
      _opts="${_opts} -o IdentityFile=${_p_key}"
    else
      sp_f_warn "key ${_p_key} not found"
    fi
    local _url="${sp_g_ssh_user}@${sp_g_ssh_fqdn}:${sp_p_sshfs_remote}"

    sp_f_dir_create "${_dst}"

    sp_f_stt "${_dst} -> ${_url}"
    ${sp_p_sshmnt} ${_url} ${_dst} ${_opts}
  else
    sp_f_stt "${_dst}"
    ${sp_p_sshumnt} ${_dst}
  fi

  return $?
}


function sp_f_sshumnt() {
  local _host="${1:-default}"
  local _force="${2:-false}"
  sp_f_sshmnt "${_host}" "${_force}" false
}
