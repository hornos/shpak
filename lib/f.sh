#/// \file f.sh
#/// \brief shpak kernel functions
#///
#/// Defines common kernel functions

#f3--&7-9-V13------21-------------------42--------------------64------72
#/// \var sp_g_libs
#/// \brief internal array for loaded libraries
sp_g_libs=()


#f3--&7-9-V13------21-------------------42--------------------64------72
#/// \fn sp_f_err
#/// \brief print error message
#///
#/// \param * CHARACTER(*) error text
function sp_f_err() {
  echo -e "ERROR ($(basename "${0}")) $*" >&2
}

function sp_f_err_fnf() {
  sp_f_err "Not found $*"
}

function sp_f_err_cac() {
  sp_f_err "Cannot create $*"
}

#/// \fn sp_f_wrn
#/// \brief print warning message
#///
#/// \param * CHARACTER(*) warning text
function sp_f_wrn() {
  if ${sp_g_debug} ; then
    echo -e "WARN ($(basename "${0}")) $*" >&2
  fi
}

function sp_f_wrn_fnf() {
  sp_f_wrn "Not found $*"
}

#/// \fn sp_f_msg
#/// \brief print message
#///
#/// \param * CHARACTER(*) text
function sp_f_msg() {
  echo -e "$*" >&2
}

#/// \fn sp_f_inarr
#/// \brief check if key is in the array
#///
#/// \param 1 CHARACTER(*) key
#/// \param 2 ARRAY
function sp_f_inarr() {
  local _k
  for _k in ${2} ; do
    if test "${_k}" = "${1}" ; then return 0; fi
  done
  return 1
}


#f3--&7-9-V13------21-------------------42--------------------64------72
# LIBRARY
#/// \fn sp_f_load
#/// \brief load a function library
#///
#/// \param 1 CHARACTER(*) library relative path in $sp_p_lib
#/// \param 2 LOGICAL if not found exit (true) or return (false)
function sp_f_load() {
  local _lib="${1}"
  local _isex=${2:-true}
  if test -z "${_lib}" ; then
    if ${_isex} ; then exit 1; else return 1; fi
  fi
  # check library path
  local _p_lib="${sp_p_lib}/${_lib}/lib${sp_s_lib}"
  if ! test -r "${_p_lib}" ; then
    sp_f_err_fnf "${_p_lib}";
    if ${_isex} ; then exit 2; else return 2; fi
  fi
  # check loaded libraries
  if sp_f_inarr "${_lib}" ${sp_g_libs} ; then
    sp_f_err "loaded ${_lib}"
    if ${_isex} ; then exit 3; else return 3; fi
  fi
  # load the library config
  local _p_cfg="${sp_p_lib}/${_lib}/lib${sp_s_cfg}"
  if test -r ${_p_cfg} ; then
    . "${_p_cfg}"
  else
    sp_f_wrn_fnf "${_p_cfg}"
  fi
  # load OS specific library config
  _p_cfg="${sp_p_lib}/${_lib}/${OSTYPE}${sp_s_cfg}"
  if test -r ${_p_cfg} ; then
    . "${_p_cfg}"
  else
    sp_f_wrn_fnf "${_p_cfg}"
  fi
  # load the library
  . "${_p_lib}"
  local _nx=${#sp_g_libs[@]}
  sp_g_libs[${_nx}]="${_lib}"
  return 0
} # end sp_f_load


#f3--&7-9-V13------21-------------------42--------------------64------72
# LOCK
#/// \fn sp_f_lck
#/// \brief check the lock file in sp_p_lck
#///
#/// \param 1 CHARACTER(*) name of the lock
#///
#/// Example:
#/// if sp_f_lck LOCK ; then
#///   this part runs when the LOCK is there
#/// fi
function sp_f_lck() {
  if test -z "${1}" ; then return 1; fi

  local _lck="${1}"
  local _p_lck="${sp_p_lck}/${_lck}${sp_s_lck}"
  if test -w "${_p_lck}" ; then 
    return 0
  fi
  return 2
}

#/// \fn sp_f_mklck
#/// \brief create the lock file in sp_p_lck
#///
#/// \param 1 CHARACTER(*) name of the lock
#///
#/// Example:
#/// if sp_f_mklck LOCK ; then
#///   this part runs when LOCK is created
#/// fi
function sp_f_mklck() {
  if test -z "${1}" ; then return 1; fi

  local _lck="${1}"
  local _p_lck="${sp_p_lck}/${_lck}${sp_s_lck}"
  if sp_f_lck "${_lck}" ; then return 2; fi

  local _now=`date +"%Y-%m-%d[%H:%M:%S]"`
  echo "_lck=\"${_lck}\""   >  "${_p_lck}"
  echo "_date=\"${_now}\""  >> "${_p_lck}"
  return 0
}

#/// \fn sp_f_rmlck
#/// \brief delete the lock file in sp_p_lck
#///
#/// \param 1 CHARACTER(*) name of the lock
#///
#/// Example:
#/// if sp_f_mklck LOCK ; then
#///   this part runs when LOCK is deleted
#/// fi
function sp_f_rmlck() {
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
#/// \fn sp_f_mkdir
#/// \brief creates a directory
#///
#/// \param 1 CHARACTER(*) name of the directory
function sp_f_mkdir() {
  if test -z "${1}" ; then return 1; fi

  local _dir="${1}"
  if ! test -d "${_dir}" ; then
    mkdir -p "${_dir}"
    local _r=$?
    if test ${_r} -gt 0 ; then
      sp_f_err_cac "${_dir}"
    fi
    return ${_r}
  fi
  return 0
}

#/// \fn sp_f_rmdir
#/// \brief deletes a directory
#///
#/// \param 1 CHARACTER(*) name of the directory
function sp_f_rmdir() {
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
#/// \fn sp_f_mklnk
#/// \brief creates a symbolic link
#///
#/// \param 1 CHARACTER(*) name of the link (what)
#/// \param 2 CHARACTER(*) target (where)
function sp_f_mklnk() {
  if test -z "${1}" || test -z "${2}" ; then return 1; fi

  local _src="${1}"
  local _dst="${2}"
  if ! test -L "${_dst}" ; then
    ln -s "${_src}" "${_dst}"
    return $?
  fi
  return 0
}

#/// \fn sp_f_rmlnk
#/// \brief deletes a symbolic link
#///
#/// \param 1 CHARACTER(*) name of the link
function sp_f_rmlnk() {
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
#/// \fn sp_f_yesno
#/// \brief asks a yes no question with retry
#///
#/// \param 1 CHARACTER(*) question
#/// \param 2 INTEGER retry
function sp_f_yesno() {
  local _msg="${1:-Answer}"
  local _flt=${2:-3}
  local _ans

  while true ; do
    echo -en "\n${_msg} (y / n / q) [${_flt}]: "
    read _ans
    _ans=$(sp_f_lc ${_ans})
    case "${_ans}" in
      "y" )
        return 0
      ;;
      "n" | "q" )
        sp_f_err "abort"
        return 1
      ;;
      *)
        sp_f_err "invalid answer"
        _flt=$((_flt-1))
      ;;
    esac
    if test ${_flt} -lt 1 ; then
      return 2
    fi
  done
}


#f3--&7-9-V13------21-------------------42--------------------64------72
# GUI
#/// \fn sp_f_sln
#/// \brief draw a normal line
function sp_f_sln() {
  echo "${sp_g_nruler}"
}

#/// \fn sp_f_dln
#/// \brief draw a double line
function sp_f_dln() {
  echo "${sp_g_bruler}"
}

#/// \fn sp_f_stt
#/// \brief print title with a single line
#///
#/// \param 1 CHARACTER(*) title text
function sp_f_stt() {
  echo ""
  echo -e "${1}"
  sp_f_sln
}

#/// \fn sp_f_dtt
#/// \brief print title with a double line
#///
#/// \param 1 CHARACTER(*) title text
function sp_f_dtt() {
  echo ""
  echo -e "${1}"
  sp_f_dln
}

#/// \fn sp_f_ptt
#/// \brief print program title
#///
#/// \param 1 CHARACTER(*) program name
function sp_f_ptt() {
  sp_f_dtt "shpak: ${*}"
}


#f3--&7-9-V13------21-------------------42--------------------64------72
# IO
#/// \fn sp_f_ird
#/// \brief check the first character
#///
#/// \param 1 CHARACTER(*) string
#/// \param 2 CHARACTER first character
#///
#/// Example:
#/// if sp_f_ird 1 2 ; then
#///   this part runs when 1 contains 2 as the first character
#/// else
function sp_f_ird() {
  local _s="${1}"
  local _p="${2:-<}"
  if test "${_s:0:1}" = "${_p}" ; then return 0; fi

  return 1
}

#/// \fn sp_f_inm
#/// \brief trim the first character
#///
#/// \param 1 CHARACTER(*) string
#/// \param 2 CHARACTER first character
function sp_f_inm() {
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
#/// \fn sp_f_aa
#/// \brief python / json (level 1) dictionary api
#///
#/// \param 1 CHARACTER(*) dictionary string
#/// \param 2 CHARACTER(*) key to search
#/// \param 3 INTEGER order by (1: key->value, 2: value->key)
#/// \param 4 INTEGER not found value
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

#/// \fn sp_f_ini
#/// \brief ini file to dictionary
#///
#/// \param 1 CHARACTER(*) section header
#/// \param 2 CHARACTER(*) path of the in file
#///
#/// http://docs.python.org/library/configparser.html
#/// only single line entries are supported without % resolving
function sp_f_ini() {
  local _h="${1:-${sp_g_bn}}"
  local _p="${2:-./${sp_g_bn%%sh}ini}"
  cat "${_p}" | \
  awk -v h="${_h}" '
  BEGIN {
    inh = 0;
    aas = "{";
    fir = 1;
    kc = 0;
  }
  {
    # section header
    if( match( $0, "^[[:space:]]*\\[[[:space:]]*[[:alnum:]._-]+[[:space:]]*\\][[:space:]]*$" ) ) {
      # trim
      gsub("^[[:space:]]*\\[[[:space:]]*", "" )
      gsub("[[:space:]]*\\][[:space:]]*$", "" )
      # match
      if( match( $0, "^" h "$" ) ) {
        inh = 1;
      }
      else {
        inh = 0;
      }
    }
    # in section
    if( inh ) {
      # match key :/= val pairs
      if( match( $0, "[=:]") ) {
        # split
        split( $0, a, "[[:space:]]*[:|=][[:space:]]*" )
        # trim
        gsub("^[[:space:]]*","",a[1])
        gsub("^[[:space:]]*","",a[2])
        # store
        if( ! fir ) {
          aas = aas "," a[1] ":" a[2];
        }
        else {
          aas = aas a[1] ":" a[2];
        }
        fir = 0;
        ++kc;
      }
    }
  }
  END {
    aas = aas "}";
    print aas;
    if( kc )
      exit 0;
    exit 1;
  }'
}

function sp_f_init() {
  local _f="${sp_p_home}/shpak.ini"
  local _v=""
  if ! test -r "${_f}" ; then
    return 0
  fi
  sp_g_ini=$(sp_f_ini "shpak" "${_f}")
  _v=$(sp_f_aa "${sp_g_ini}" "sp_g_debug")
  if test $? -eq 0 ; then
    _v=$(sp_f_lc "${_v}")
    if test "${_v}" == "true" ; then
      sp_g_debug = true
      return 0
    fi
    sp_g_debug = false;
    return 0
  fi
  return 1
}

#f3--&7-9-V13------21-------------------42--------------------64------72
# CHARACTER
#/// \fn sp_f_btxt
#/// \brief print the backslash / escaped character
#///
#/// \param 1 INTEGER character code
#/// \param 2 LOGICAL without backslash?
function sp_f_btxt() {
  local _oe=${1:-140}
  local _o=${2:-true}
  if ${_o} ; then
    _oe="\\0${_oe}"
  fi
  echo -ne "${sp_g_esc}(0${_oe}${sp_g_esc}(B"
}

#/// \fn sp_f__c
#/// \brief case converter (internal)
function sp_f__c() {
  local _s=${1:-case}
  local _d=${2:-false}
  if ${_d} ; then
    echo "${_s}" | tr '[:upper:]' '[:lower:]'
  else
    echo "${_s}" | tr '[:lower:]' '[:upper:]'
  fi
}

#/// \fn sp_f_lc
#/// \brief convert to lowercase
#///
#/// \param CHARACTER(*) text to convert
function sp_f_lc() {
  sp_f__c "${1}" true
}

#/// \fn sp_f_uc
#/// \brief convert to uppercase
#///
#/// \param CHARACTER(*) text to convert
function sp_f_uc() {
  sp_f__c "${1}"
}
