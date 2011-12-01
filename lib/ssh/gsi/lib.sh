
# namespace notation
function ssh/gsi/update() {
  local _url="${1:-http://winnetou.sara.nl/deisa/certs/globuscerts.tar.gz}"
  local _out="c.tgz"
  local _dir="${gssh_globus_dir}/certificates"
  sp_f_mkdir "${_dir}"
  if test $? -gt 0 ; then
    exit 1
  fi
  sp_f_ptt "${sp_g_bn}"
  echo "Certificate directory: ${_dir}"
  sp_f_yesno "Download ${_url}? "
  if test $? -gt 0 ; then
    exit 1
  fi
  cd "${_dir}"
  wget -qO- "${_url}" > "${_out}"
  tar xzf "${_out}"
  local _ret=$?
  rm -f "${_out}"
  echo -n "Update "
  if test ${_ret} -gt 0 ; then
    echo "Failed"
    return ${_ret}
  fi
  echo "OK"
  chmod a-x *
  return ${_ret}
}

function sp_f_gssh_p_key() {
  echo "${sp_p_key}/${sp_p_gssh_key}${1}${sp_s_gkey}"
}

function sp_f_gssh_p_crt() {
  echo "${sp_p_key}/${sp_p_gssh_key}${1}${sp_s_gcrt}"
}

function sp_f_gsshkey() {
  local _host="${1:-default}"
  local _pk12="${2:-${_host}.p12}"
  local _pk12_bn=$(basename "${_pk12}")

  if ! test -r "${_pk12}" ; then
    return ${_FALSE_}
  fi
  cp "${_pk12}" "${sp_p_key}/${sp_p_gssh_key}${_pk12_bn}"

  sp_f_mid_init "${sp_p_gssh_key}${_host}"

  cd "${sp_p_key}/${sp_p_gssh_key}"

  local _key="${_host}.key.pem"
  local _key_lnk="${_host}${sp_s_gkey}"

  local _crt="${_host}.crt.pem"
  local _crt_lnk="${_host}${sp_s_gcrt}"

  if test -r "${_crt}" ; then
    sp_f_wrn "Delete cert ${_crt}"
    return ${_FALSE_}
  fi
  echo "Exporting certificate to ${_crt}"
  openssl pkcs12 -in "${_pk12_bn}" -out "${_crt}" -clcerts -nokeys
  if test $? -gt 0 ; then
    return ${_FALSE_}
  fi

  if test -r "${_key}" ; then
    sp_f_wrn "Delete key ${_key}"
    return ${_FALSE_}
  fi
  echo "Exporting private key to ${_key}"
  openssl pkcs12 -in "${_pk12_bn}" -out "${_key}" -nocerts

  local _r=$?

  if test ${_r} -eq 0 ; then
    chmod go-rwx "${_key}"
    sp_f_mklnk "${_key}" "${_key_lnk}"

    chmod go-rwx "${_crt}"
    sp_f_mklnk "${_crt}" "${_crt_lnk}"
  fi

  rm -f "${_pk12_bn}"
  echo ""
  return ${_r}
}


#/// \fn sp_f_sshto
#/// \brief ssh login
#///
#/// \param 1 CHARACTER(*) host MID
#/// \param 2 LOGICAL prevent lock checking
function sp_f_gsshto() {
  local _host="${1:-default}"
  local _force="${2:-false}"

  sp_f_mid_init "${sp_p_gssh_key}${_host}"

  # lock
  local _lck="${_host}.${sp_g_bn}"
  if ${_force} ; then
    sp_f_rmlck "${_lck}"
  fi

  # grid proxy init
  local _opts="-valid ${sp_g_gssh_valid}"
  local _p_key="$(sp_f_gssh_p_key ${_host})"
  if ! test -r "${_p_key}" ; then
    sp_f_wrn_fnf "${_p_key}"
    return ${_FALSE_}
  fi
  _opts="${_opts} -key ${_p_key}"

  local _p_crt="$(sp_f_gssh_p_crt ${_host})"
  if ! test -r "${_p_crt}" ; then
    sp_f_wrn_fnf "${_p_crt}"
    return ${_FALSE_}
  fi
  _opts="${_opts} -cert ${_p_crt}"

  local _p_out="${sp_p_lck}/${sp_g_bn}.proxy.${USER}.$$"
  _opts="${_opts} -out ${_p_out}"

  ${sp_b_gpxi} ${_opts}
  if test $? -gt 0 ; then
    return ${_FALSE_}
  fi
  # end grid proxy init

  # proxy
  local _proxy=false
  _opts="${sp_g_gssh_opts}"
  if ! test -z "${sp_g_gssh_proxy}" ; then
    if sp_f_mklck "${_lck}" ; then
      _proxy=true
      _opts="${_opts} ${sp_g_gssh_proxy}"
      sp_f_msg "Connect tunnels: ${sp_g_gssh_proxy}"
    else
      sp_f_wrn "Active tunnels: ${sp_g_gssh_proxy}"
    fi
  fi

  # login
  local _url="${sp_g_gssh_user}@${sp_g_gssh_fqdn}"
  sp_f_stt "Login to ${_url}"
  X509_USER_PROXY=${_p_out} ${sp_b_gssh} ${_opts} ${_url}

  local _r=$?
  if ${_proxy} ; then
    sp_f_rmlck "${_lck}"
  fi

  # grid proxy destroy
  if test -r "${_p_out}" ; then
    ${sp_b_gpxd} "${_p_out}"
  fi
  return ${_r}
}


function sp_f_gsshtx() {
  local _host="${1:-default}"
  local _m="${2:-1}"
  local _xd=${3:-false}
  local _rec=${4:-false}
  local _src="${5}"
  local _r=0
  local _dst="./"

  # mode select -------------------------
  local _push=true
  local _mode=$((_m%10))
  if test $((_m/10)) -gt 0 ; then
    _push=false
  fi

  # init --------------------------------
  sp_f_mid_init "${sp_p_gssh_key}${_host}"

  if ${_xd} ; then
    _dst="${sp_p_gscp_local}"
  fi
  local _src_url="${sp_g_gssh_user}@${sp_g_gssh_fqdn}:${sp_p_gscp_remote}"
  if ${_push} ; then
    if ! test -r "${_src}" ; then
      sp_f_err_fnf "${_src}"
      return 2
    fi
  else
    local _src_url="${_src_url}/${_src}"
    if ${_xd} ; then
      sp_f_mkdir "${sp_p_gscp_local}"
    fi
  fi

  # mode --------------------------------
  case ${_mode} in
    1)
      local _opts="${sp_g_gscp_opts}"
      local _url="${_src_url}"
      local _mtxt="scp"
      if ${_rec} ; then
        _opts="-r ${_opts}"
      fi
    ;;
    2)
      local _opts="-p ${sp_g_gssh_port}"
      local _url="${sp_g_gssh_user}@${sp_g_gssh_fqdn}"
      local _mtxt="tar/ssh"
    ;;
    3)
      local _opts="-p ${sp_g_gssh_port}"
      local _url="${_src_url}"
      local _mtxt="rsync/ssh"
    ;;
    *) sp_f_err "invalid mode"
       return ${_FALSE_}
    ;;
  esac

  # title -------------------------------
  local _dtxt="\n From: ${_src}\n   To: ${_url}"
  if ! ${_push} ; then
    _dtxt="\n From: ${_src_url}\n   To: ${_dst} ($(pwd ${_dst}))"
  fi
  sp_f_stt "Transfer (${_mtxt})\n${_dtxt}\n"

  echo ""
  sp_f_yesno "Start?"
  _r=$?
  echo ""
  sp_f_sln
  if test ${_r} -gt 0 ; then return ${_r}; fi

  # grid proxy init
  local _x_opts="-valid ${sp_g_gssh_valid}"
  local _p_key="$(sp_f_gssh_p_key ${_host})"
  if ! test -r "${_p_key}" ; then
    sp_f_wrn_fnf "${_p_key}"
    return ${_FALSE_}
  fi
  _x_opts="${_x_opts} -key ${_p_key}"

  local _p_crt="$(sp_f_gssh_p_crt ${_host})"
  if ! test -r "${_p_crt}" ; then
    sp_f_wrn_fnf "${_p_crt}"
    return ${_FALSE_}
  fi
  _x_opts="${_x_opts} -cert ${_p_crt}"

  local _p_out="${sp_p_lck}/${sp_g_bn}.proxy.${USER}.$$"
  _x_opts="${_x_opts} -out ${_p_out}"

  ${sp_b_gpxi} ${_x_opts}
  if test $? -gt 0 ; then
    return ${_FALSE_}
  fi
  # end grid proxy init

  # transfer ----------------------------
  case ${_mode} in
    1)
      if ${_push} ; then
        X509_USER_PROXY=${_p_out} ${sp_b_gscp} ${_opts} "${_src}" ${_url}
      else
        X509_USER_PROXY=${_p_out} ${sp_b_gscp} ${_opts} ${_url} "${_dst}"
      fi
      _r=$?
    ;;
    2)
      if ${_push} ; then
        ${sp_b_tar} cvf - "${_src}" | X509_USER_PROXY=${_p_out} ${sp_b_gssh} ${_opts} ${_url} "(cd \"${sp_p_gscp_remote}\";tar xvf -)"
      else
        X509_USER_PROXY=${_p_out} ${sp_b_gssh} ${_opts} ${_url} "(cd \"${sp_p_gscp_remote}\";tar cvf - \"${_src}\")" | (cd "${_dst}"; ${sp_b_tar} xvf -)
      fi
      _r=$?
    ;;
    3)
      export X509_USER_PROXY=${_p_out} 
      if ${_push} ; then
        ${sp_b_rsync} -a -z -v --partial --progress -e "${sp_b_gssh} ${_opts}" "${_src}" ${_url}
      else
        ${sp_b_rsync} -a -z -v --partial --progress -e "${sp_b_gssh} ${_opts}" ${_url} "${_dst}"
      fi
      _r=$?
      unset X509_USER_PROXY
    ;;
  esac
  sp_f_sln
  echo ""

  # grid proxy destroy
  if test -r "${_p_out}" ; then
    ${sp_b_gpxd} "${_p_out}"
  fi

  return ${_r}
} # end sp_f_sshtx


function sp_f_gsshpush() {
  local _h="${1:-default}"
  local _m="${2:-1}"
  local _x=${3:-false}
  local _r=${4:-false}
  local _s="${5}"
  _m=$((_m%10))
  sp_f_gsshtx "${_h}" ${_m} ${_x} ${_r} "${_s}"
}


function sp_f_gsshpull() {
  local _h="${1:-default}"
  local _m="${2:-1}"
  local _x=${3:-false}
  local _r=${4:-false}
  local _s="${5}"
  _m=$((_m%10+10))
  sp_f_gsshtx "${_h}" ${_m} ${_x} ${_r} "${_s}"
}


# ssh misc ----------------------------------------------------------------------
function sp_f_gsshchg() {
  return ${_FALSE_}
#  local _host="${1:-default}"
#  local _mode="${2:-rsa}"
#
#  sp_f_mid_init "${sp_p_ssh_key}${_host}"
#
#  cd "${sp_p_key}/${sp_p_ssh_key}"
#  local _key="${_host}.id_${_mode}"
#  if ! test -r "${_key}" ; then
#    return 1
#  fi
#  ${sp_b_sshkey} -p -f "${_key}"
}


function sp_f_gsshinf() {
  local _host="${1:-default}"

  sp_f_mid_init "${sp_p_gssh_key}${_host}"

  sp_f_stt "${_host} (${sp_g_gssh_fqdn})"
  echo "ssh url    : ${sp_g_gssh_user}@${sp_g_gssh_fqdn}"
  echo "ssh opts   : ${sp_g_gssh_opts}"
  if ! test -z "${sp_g_gssh_proxy}" ; then
    echo "ssh proxy  : ${sp_g_gssh_proxy}"
  fi
  echo ""
  echo "ssh local  : ${sp_p_gscp_local}"
  echo "ssh remote : ${sp_p_gscp_remote}"
  echo ""
  echo "sshfs mnt  : ${sp_p_gsshfs_local} -> ${sp_g_gssh_user}@${sp_g_gssh_fqdn}:${sp_p_gsshfs_remote}"
  echo "sshfs opts : ${sp_g_gsshfs_opts}"
  echo ""

# TODO
  # ssh key -----------------------------
#  local _p_key="$(sp_f_gssh_p_key ${_host})"
#
#  if test -r "${_p_pkey}" ; then
#    ${sp_b_sshkey} -v -l -f "${_p_pkey}"
#  else
#    sp_f_wrn_fnf "${_p_pkey}"
#  fi

  return ${_TRUE_}
}

function sp_f_gsshcmd() {
  local _host="${1:-default}"
  local _cmd="${2:-ls -lA ${sp_p_gscp_remote}}"
  local _int=${3:-false}
  local _tmp=""

  sp_f_mid_init "${sp_p_gssh_key}${_host}"

  # begin grid proxy init
  local _opts="-valid ${sp_g_gssh_valid}"
  local _p_key="$(sp_f_gssh_p_key ${_host})"
  if ! test -r "${_p_key}" ; then
    sp_f_wrn_fnf "${_p_key}"
    return ${_FALSE_}
  fi
  _opts="${_opts} -key ${_p_key}"

  local _p_crt="$(sp_f_gssh_p_crt ${_host})"
  if ! test -r "${_p_crt}" ; then
    sp_f_wrn_fnf "${_p_crt}"
    return ${_FALSE_}
  fi
  _opts="${_opts} -cert ${_p_crt}"

  local _p_out="${sp_p_lck}/${sp_g_bn}.proxy.${USER}.$$"
  _opts="${_opts} -out ${_p_out}"

  ${sp_b_gpxi} ${_opts}
  # end grid proxy init

  local _opts="${sp_g_gssh_opts}"

  # ssh interactive ---------------------
  if ${_int} ; then
    _opts="-t ${_opts}"
  fi

  local _url="${sp_g_gssh_user}@${sp_g_gssh_fqdn}"
  sp_f_stt "Run ${_cmd} on ${_url}"

  # ssh ---------------------------------
  if ! test -z "${sp_g_gssh_env}" ; then
    _tmp="source \${HOME}/${sp_g_gssh_env};"
    _tmp="${_tmp}echo ${sp_g_nruler};"
    _cmd="${_tmp}${_cmd}"
  fi
  X509_USER_PROXY=${_p_out} ${sp_b_gssh} ${_opts} ${_url} ${_cmd}

  # grid proxy destroy
  if test -r "${_p_out}" ; then
    ${sp_b_gpxd} "${_p_out}"
  fi
  return ${_r}
}
