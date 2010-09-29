
function sp_f_zcpumv() {
 local _src="${1}"
 local _dir="${2}"
 local _dst="${3}"
 local _src_bn=""
 _src_bn=$(basename ${_src})
 local _src_ne=${_src_bn%%${sp_s_z}}

 # copy ---------------------------------
 cp "${_src}" "${_dir}"
 if test $? -gt 0 ; then
   sp_f_err "file $src can't be copied"
   return 10
 fi

 # uncompress ---------------------------
 if test "${_src_bn}" != "${_src_ne}" ; then
   ${sp_b_uz} "${_dir}/${_src_bn}"
 fi

 # rename -------------------------------
 local _p_src_ne="${_dir}/${_src_ne}"
 local _p_dst="${_dir}/${_dst}"
 if ! test -z "${_dst}" && ! test -f "${_p_dst}" ; then
   mv "${_p_src_ne}" "${_p_dst}"
   if test $? -gt 0 ; then
     sp_f_err "file ${_p_src_ne} can't be renamed"
     return 11
   fi
   chmod u+w "${_p_dst}"
 else
   chmod u+w "${_p_src_ne}"
 fi
 return 0
}


function sp_f_svzmv() {
  local _rs="${1}"
  local _p_dst="${2}"
  local _p_sav="${_p_dst%%${sp_s_z}}${sp_s_oz}"

  if test -f "${_p_dst}" ; then
    mv -f "${_p_dst}" "${_p_sav}"
    if test $? -gt 0 ; then
      sp_f_err "file ${_p_dst} can't be renamed"
      return 20
    fi
  fi

  local _zrs="${_rs}${sp_s_z}"
  ${sp_b_z} "${_rs}"
  cp -f "${_zrs}" "${_p_dst}"
  if test $? -gt 0 ; then
    sp_f_err "file ${_zrs} can't be copied"
    return 21
  fi
  chmod u-w "${_p_dst}"
  rm -f "${_zrs}"
  if test $? -gt 0 ; then
    sp_f_err "file ${_zrs} can't be deleted"
    return 22
  fi

  return 0
}


function sp_f_zutbc() {
 sp_f_zcpumv "${1}" "${sp_z_tmp}" "${3}"
}
