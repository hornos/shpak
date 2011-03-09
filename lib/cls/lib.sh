#f3--&7-9-V13------21-------------------42--------------------64------72

#/// \fn sp_f_clscmd
#/// \brief run a shell command on a cluster
#///
#/// \param 1 CHARACTER(*) cluster id
#/// \param 2 CHARACTER(*) command
#///
#/// hosts can be divided into disjoint sets by setting the 
#/// sp_g_cluster variable
function sp_f_clscmd() {
  local _c="${1:-default}"
  local _cmd="${2:-ls}"
  local _hi
  local _hibn
  for _hi in ${sp_p_hosts}/* ; do
    _hibn=$(basename ${_hi})
    sp_g_cluster=""
    . ${_hi}
    if test "${sp_g_cluster}" = "${_c}" ; then
      sshcmd -m ${_hibn} -x"${_cmd}" 2> /dev/null | awk "${sp_g_awkprn}"
      echo
      echo
    fi
  done
}

#/// \fn sp_f_clspush
#/// \brief sshpush to a cluster
#///
#/// \param 1 CHARACTER(*) cluster id
#/// \param 2 CHARACTER(*) source (what)
#/// \param 3 INTEGER sshpush xfer mode
function sp_f_clspush() {
  local _c="${1:-default}"
  local _s="${2}"
  local _t=${3:-3}
  local _hi
  local _hibn
  if ! test -r "${_s}" ; then
    sp_f_err "missing: ${_s}"
    return 10
  fi
  for _hi in ${sp_p_hosts}/* ; do
    _hibn=$(basename ${_hi})
    sp_g_cluster=""
    . ${_hi}
    if test "${sp_g_cluster}" = "${_c}" ; then
      sshpush -m "${_hibn}" -s "${_s}" -t ${_t}
    fi
  done
}
