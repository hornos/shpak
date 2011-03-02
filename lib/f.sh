#f3--&7-9-V13------21-------------------42--------------------64------72
# GLOBALS
sp_g_libs=()


#f3--&7-9-V13------21-------------------42--------------------64------72
# ERRORS
function sp_f_err() {
#D print error ($1)
  echo -e "$(basename "${0}") : Error : $*" >&2
}

function sp_f_wrn() {
#D print warning ($1)
  if ${sp_g_debug} ; then
    echo -e "$(basename "${0}") : Warning : $*" >&2
  fi
}

function sp_f_msg() {
#D print message ($1)
  echo -e "$(basename "${0}") : Message : $*" >&2
}

function sp_f_inarr() {
#D check key ($1) in array ($2)
  local _k
  for _k in ${2} ; do
    if test "${_k}" = "${1}" ; then return 0; fi
  done
  return 1
}


#f3--&7-9-V13------21-------------------42--------------------64------72
# LIBRARY
function sp_f_load() {
#D load library ($1), exit or return ($2)
  local _lib="${1}"
  local _isex=${2:-true}
  if test -z "${_lib}" ; then
    if ${_isex} ; then exit 1; else return 1; fi
  fi
  # check library path
  local _p_lib="${sp_p_lib}/${_lib}/lib${sp_s_lib}"
  if ! test -r "${_p_lib}" ; then
    sp_f_err "file ${_p_lib} not found";
    if ${_isex} ; then exit 2; else return 2; fi
  fi
  # check loaded libraries
  if sp_f_inarr "${_lib}" ${sp_g_libs} ; then
    sp_f_err "${_lib} is already loaded"
    if ${_isex} ; then exit 3; else return 3; fi
  fi
  # load the library config
  local _p_cfg="${sp_p_lib}/${_lib}/lib${sp_s_cfg}"
  if test -r ${_p_cfg} ; then
    . "${_p_cfg}"
  else
    sp_f_wrn "file ${_p_cfg} not found"
  fi
  # load OS specific library config
  _p_cfg="${sp_p_lib}/${_lib}/${OSTYPE}${sp_s_cfg}"
  if test -r ${_p_cfg} ; then
    . "${_p_cfg}"
  else
    sp_f_wrn "file ${_p_cfg} not found"
  fi
  # load the library
  . "${_p_lib}"
  local _nx=${#sp_g_libs[@]}
  sp_g_libs[${_nx}]="${_lib}"
  return 0
} # end sp_f_load


#f3--&7-9-V13------21-------------------42--------------------64------72
# LOCK
function sp_f_lck() {
#D check lock ($1)
# if sp_f_lck LOCK ; then
#   this part runs when LOCK is present
# fi

  if test -z "${1}" ; then return 1; fi

  local _lck="${1}"
  local _p_lck="${sp_p_lck}/${_lck}${sp_s_lck}"
  if test -w "${_p_lck}" ; then 
    return 0
  fi
  return 2
}

function sp_f_mklck() {
#D create lock ($1)
# if sp_f_mklck LOCK ; then
#   this part runs when LOCK is created
# fi

  if test -z "${1}" ; then return 1; fi

  local _lck="${1}"
  local _p_lck="${sp_p_lck}/${_lck}${sp_s_lck}"
  if sp_f_lck "${_lck}" ; then return 2; fi

  local _now=`date +"%Y-%m-%d[%H:%M:%S]"`
  echo "_lck=\"${_lck}\""   >  "${_p_lck}"
  echo "_date=\"${_now}\""  >> "${_p_lck}"
  return 0
}

function sp_f_rmlck() {
#D delete lock ($1)
# if sp_f_rmlck LOCK ; then
#   this part runs when LOCK is deleted
# fi

  if test -z "${1}" ; then return 1; fi

  local _lck="${1}"
  local _p_lck="${sp_p_lck}/${_lck}${sp_s_lck}"

  if sp_f_lck "${_lck}" ; then
    rm -f "${_p_lck}"
    return $?
  fi
  return 2
}


#f3--&7-9-V13------21-------------------42--------------------64------72
# DIRECTORY
function sp_f_mkdir() {
#D create directory ($1)
  if test -z "${1}" ; then return 1; fi

  local _dir="${1}"
  if ! test -d "${_dir}" ; then
    mkdir -p "${_dir}"
    local _r=$?
    if test ${_r} -gt 0 ; then
      sp_f_err "directory ${_dir} can't be created"
    fi
    return ${_r}
  fi
  return 0
}

function sp_f_rmdir() {
#D delete directory ($1)
  if test -z "${1}" ; then return 1; fi

  local _dir="${1}"
  if test -d "${_dir}" ; then
    rm -fR "${_dir}"
    local _r=$?
    if test ${_r} -gt 0 ; then
      sp_f_err "directory ${_dir} can't be deleted"
    fi
    return ${_r}
  fi
  return 0
}


#f3--&7-9-V13------21-------------------42--------------------64------72
# LINK
function sp_f_mklnk() {
#D create link ($1) with target ($2)
  if test -z "${1}" || test -z "${2}" ; then return 1; fi

  local _src="${1}"
  local _dst="${2}"
  if ! test -L "${_dst}" ; then
    ln -s "${_src}" "${_dst}"
    return $?
  fi
  return 0
}

function sp_f_rmlnk() {
#D delete link ($1)
  if test -z "${1}" ; then return 1; fi
  local _lnk="${1}"

  if test -L "${_lnk}" ; then
    rm -f "${_lnk}"
    return $?
  fi
  return 0
}


#f3--&7-9-V13------21-------------------42--------------------64------72
# HCI
function sp_f_yesno() {
#D ask yesno question ($1)
  local _msg="${1:-Answer}"
  local _ans
  echo -n "${_msg} (y - yes / n - no): "
  read _ans
  case "${_ans}" in
    "y" | "Y")
      return 0
    ;;
    "n" | "N")
      sp_f_err "abort"
      return 1
    ;;
    *)
      sp_f_err "invalid answer"
      return 2
    ;;
  esac
  return 3
}


#f3--&7-9-V13------21-------------------42--------------------64------72
# GUI
function sp_f_sln() {
  echo "${sp_g_nruler}"
}

function sp_f_dln() {
  echo "${sp_g_bruler}"
}

function sp_f_stt() {
  echo ""
  echo -e "${1}"
  sp_f_sln
}

function sp_f_dtt() {
  echo ""
  echo -e "${1}"
  sp_f_dln
}

function sp_f_ptt() {
  sp_f_dtt "shpak: ${*}"
}


#f3--&7-9-V13------21-------------------42--------------------64------72
# IO
function sp_f_ird() {
  # check first character ($2) of a string ($1)
  local _s="${1}"
  local _p="${2:-<}"
  if test "${_s:0:1}" = "${_p}" ; then return 0; fi

  return 1
}

function sp_f_inm() {
  # trim first character ($2) of a string ($1)
  local _s="${1}"
  local _p="${2:-<}"
  if sp_f_ird "${_s}" "${_p}" ; then
    echo "${_s:1}"
  else
    echo "${_s}"
  fi
  return 0
}


#f3--&7-9-V13------21-------------------42--------------------64------72
# PYTHON
function sp_f_aa() {
  local _aa=${1:-'{one:1,two:2,three:3}'}
  local _key=${2:-one}
  local _oby=${3:-1}
  local _ie=${4:-0}

  echo ${_aa} | awk -v key=${_key} -v oby=${_oby} -v ie=${_ie} \
  '{
    sub(/^[[:space:]]*{[[:space:]]*/,"")
    sub(/[[:space:]]*}[[:space:]]*/,"")
    split($0,va,"[[:space:]]*,[[:space:]]*")
    # print "->" $0 "<-"
    for( k in va ) {
      sub(/^[[:space:]]*/,"",va[v])
      sub(/[[:space:]]*$/,"",va[v])
      split(va[k],vva,"[[:space:]]*:[[:space:]]*")
      sub(/^'\''/,"",vva[1])
      sub(/'\''$/,"",vva[1])
      if(oby==1)
        aa[vva[1]]=vva[2]
      else
        aa[vva[2]]=vva[1]
    }
    # check key
    if(aa[key]=="") {
      print ie
      exit 1
    }
    print aa[key]
  }'
}
