#f3--&7-9-V13------21-------------------42--------------------64------72
#/// Credit to B. A. for the original versions

#/// \fn sp_f_zbn
#/// \brief basename with or without z suffix
#///
#/// \param 1 CHARACTER(*) binary name
#/// \param 2 LOGICAL true: strip off z suffix
function sp_f_zbn() {
  local _bn=$(basename "${1}")
  local _zn=${2:-true}
  if ${_zn} ; then 
    _bn=${_bn%%${sp_s_z}}
  fi
  echo "${_bn}"
}


#/// \fn sp_f_zcpumv
#/// \brief copy, uncompress, move
#///
#/// \param 1 CHARACTER(*) source path
#/// \param 2 CHARACTER(*) destination directory
#/// \param 3 CHARACTER(*) destination name
function sp_f_zcpumv() {
 local _src="${1}"
 local _dir="${2}"
 local _dst="${3}"
 local _src_n=$(sp_f_zbn "${_src}")
 local _src_bn=$(sp_f_zbn "${_src}" false)

 if test -z "${_src}" || test -z "${_dst}" ; then
   return ${_FALSE_}
 fi
 # copy
 cp "${_src}" "${_dir}"
 if test $? -gt 0 ; then
   sp_f_err "cannot copy $src"
   return ${_FALSE_}
 fi

 # uncompress
 if test "${_src_bn}" != "${_src_n}" ; then
   ${sp_b_uz} "${_dir}/${_src_bn}"
 fi

 # rename
 local _p_src_n="${_dir}/${_src_n}"
 local _p_dst="${_dir}/${_dst}"
 if ! test -z "${_dst}" && ! test -f "${_p_dst}" ; then
   mv "${_p_src_n}" "${_p_dst}"
   if test $? -gt 0 ; then
     sp_f_err "cannot rename ${_p_src_n}"
     return ${_FALSE_}
   fi
   chmod u+w "${_p_dst}"
 else
   chmod u+w "${_p_src_n}"
 fi
 return ${_TRUE_}
}

function sp_f_zcput() {
  sp_f_zcpumv "${1}" "${sp_z_tmp}" "${2}"
}

function sp_f__d() {
  local _dir=${1}
  local _u=${2:-false}
  cd "${_dir}"
  for i in * ; do
    if test -d "${i}" ; then
      (sp_f__d "${i}" ${_u})
    elif test -f "${i}" ; then
      if ! test "${i%%${sp_s_z}}" = "${i}" ; then
        if ${_u} ; then
          ${sp_b_uz} "${i}"
        else
          ${sp_b_z} "${i}"
        fi
      fi
    fi
  done
}

function sp_f_zd() {
  local _pwd=$(pwd)
  sp_f__d "${1}" false
  cd "${_pwd}"
}

function sp_f_uzd() {
  local _pwd=$(pwd)
  sp_f__d "${1}" true
  cd "${_pwd}"
}

#/// \fn sp_f_svzmv
#/// \brief save, compress, move
#///
#/// \param 1 CHARACTER(*) source path
#/// \param 2 CHARACTER(*) destination path
#/// if destination exist make a backup copy (save)
function sp_f_svzmv() {
  local _rs="${1}"
  local _p_dst="${2}"
  local _p_sav="${_p_dst%%${sp_s_z}}${sp_s_oz}"

  if test -z "${_rs}" || test -z "${_p_dst}" ; then
    return ${_FALSE_}
  fi

  if test -d "${_rs}" ; then
    _p_dst=${_p_dst%%${sp_s_z}}
    if test -d "${_p_dst}" ; then
      _p_sav="${_p_dst}.old"
      if test -d "${_p_sav}" ; then
        rm -fR "${_p_sav}"
      fi
      mv -f "${_p_dst}" "${_p_sav}"
      if test $? -gt 0 ; then
        sp_f_err "cannot rename ${_p_dst}"
        return ${_FALSE_}
      fi
    fi
    sp_f_zd "${_rs}"
    cp -fR "${_rs}" "${_p_dst}"
    if test $? -gt 0 ; then
      sp_f_err "cannot copy ${_rs}"
      return ${_FALSE_}
    fi
    chmod -R u+w "${_p_dst}"
    rm -Rf "${_rs}"
    if test $? -gt 0 ; then
      sp_f_err_cad "${_rs}"
      return ${_FALSE_}
    fi
    return ${_TRUE_}
  fi

  if test -f "${_p_dst}" ; then
    mv -f "${_p_dst}" "${_p_sav}"
    if test $? -gt 0 ; then
      sp_f_err "cannot rename ${_p_dst}"
      return ${_FALSE_}
    fi
  fi

  local _zrs="${_rs}${sp_s_z}"
  ${sp_b_z} "${_rs}"
  cp -f "${_zrs}" "${_p_dst}"
  if test $? -gt 0 ; then
    sp_f_err "cannot copy ${_zrs}"
    return ${_FALSE_}
  fi
  chmod u+w "${_p_dst}"
  rm -f "${_zrs}"
  if test $? -gt 0 ; then
    sp_f_err_cad "${_zrs}"
    return ${_FALSE_}
  fi
  return ${_TRUE_}
}

function sp_f_zcat() {
  local _zsrc="${1}"
  local _src=${_zsrc%%${sp_s_z}}
  if test "${_zsrc}" = "${_src}" ; then
    cat "${_zsrc}"
  else
    zcat "${_zsrc}"
  fi
}
