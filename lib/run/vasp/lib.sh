function sp_f_vasp_check() {
  local _inp=$(sp_f_inm "${MAININPUT}")
  local _p_if=""
  local _lib=""
  local _p_lib=""
  local _s
  local _sarr="${sp_s_vcntl} ${sp_s_vgeom} ${sp_s_vkpts}"
  local _r

  if test "${GW}" = "on" ; then
    _sarr="${_sarr} ${sp_s_qkpts}"
  fi
      
  # check main inputs  
  for _s in  ${_sarr}; do
    _p_if="${INPUTDIR}/${_inp}${_s}"
    if ! test -r "${_p_if}" ; then
      sp_f_err "missing: ${_p_if}"
      return 35
    fi
  done

  # check libs
  for _lib in ${LIBS}; do
    _p_lib="${LIBDIR}/${_lib}/POTCAR${sp_s_z}"
    if ! test -f "${_p_lib}" ; then
      sp_f_err "missing: ${_p_lib}"
      return 31
    fi
    if test "${GW}" = "on" ; then
      _p_lib="${LIBDIR}/${_lib}/POTSIC${sp_s_z}"
      if ! test -f "${_p_lib}" ; then
        sp_f_err "missing: ${_p_lib}"
        return 31
      fi
    fi
  done

  # check others
  sp_f_run_check_others
  _r=$?
  if test ${_r} -gt 0 ; then
    return ${_r}
  fi
  
  return 0
}

function sp_f_vasp_prepare() {
  local _inp=$(sp_f_inm "${MAININPUT}")
  local _p_if=""
  local _dst=""
  local _p_wdir=$(sp_f_inm "${WORKDIR}" "@")
  local _p_sdir="${STAGEDIR}"
  local _isd=false

  if sp_f_ird "${WORKDIR}" "@" ; then _isd=true; fi

  # prepare inputs --------------------------------------------------------------
  _p_if="${INPUTDIR}/${_inp}${sp_s_vcntl}"
  _dst="INCAR"
  sp_f_run_bcast ${_isd} "${_p_wdir}" "${_p_sdir}" "${_p_if}" "${_dst}"
  if test $? -gt 0 ; then
    return $?
  fi

  _p_if="${INPUTDIR}/${_inp}${sp_s_vgeom}"
  _dst="POSCAR"
  sp_f_run_bcast ${_isd} "${_p_wdir}" "${_p_sdir}" "${_p_if}" "${_dst}"
  if test $? -gt 0 ; then
    return $?
  fi

  _p_if="${INPUTDIR}/${_inp}${sp_s_vkpts}"
  _dst="KPOINTS"
  sp_f_run_bcast ${_isd} "${_p_wdir}" "${_p_sdir}" "${_p_if}" "${_dst}"
  if test $? -gt 0 ; then
    return $?
  fi

  if test "${GW}" = "on" ; then
    _p_if="${INPUTDIR}/${_inp}${sp_s_vqpts}"
    _dst="QPOINTS"
    sp_f_run_bcast ${_isd} "${_p_wdir}" "${_p_sdir}" "${_p_if}" "${_dst}"
    if test $? -gt 0 ; then
      return $?
    fi
  fi

  # prepare libs ----------------------------------------------------------------
  if ! test -d "${LIBDIR}" ; then
    sp_f_wrn "directory ${LIBDIR} doesn't exist"
  fi

  # begin bcast -------------------------
  local _lib=""
  local _p_lib=""
  local _p_dst=""
  local _p_idir="${INPUTDIR}"
  if ! test -z "${LIBS}" ; then
    # begin POTCAR ----------------------
    _p_if="${_p_idir}/input.POTCAR"
    # clean
    if test -f "${_p_if}" ; then
      rm -f "${_p_if}"
    fi
    # concate libraries
    for _lib in ${LIBS}; do
      # build potcar
      _p_lib="${LIBDIR}/${_lib}/POTCAR${sp_s_z}"
      if ! test -f "${_p_lib}" ; then
        sp_f_err "projectorfile ${_p_lib} not found"
        return 31
      fi
      _dst="${_lib}.POTCAR"
      sp_f_zcpumv "${_p_lib}" "${_p_idir}" "${_dst}"
      _p_dst="${_p_idir}/${_dst}"
      if ! test -f "${_p_dst}" ; then
        sp_f_err "projectorfile ${_p_dst} not found"
        return 32
      fi
      cat "${_p_dst}" >> "${_p_if}"
      rm -f "${_p_dst}"
    done
    # finalize
    _dst="POTCAR"
    sp_f_run_bcast ${_isd} "${_p_wdir}" "${_p_sdir}" "${_p_if}" "${_dst}"
    if test $? -gt 0 ; then
      return $?
    fi
    # clean
    rm -f "${_p_if}"
    # end POTCAR ------------------------

    # build potsic for GW calcs
    # begin POTSIC ----------------------
    if test "${GW}" = "on" ; then
      _p_if="${_p_idir}/input.POTSIC"
      # clean
      if test -f "${_p_if}" ; then
        rm -f "${_p_if}"
      fi
      # concate libraries
      for _lib in ${LIBS}; do
        _p_lib="${LIBDIR}/${_lib}/POTSIC${sp_s_z}"
        if ! test -f "${_p_lib}" ; then
          sp_f_err "projectorfile ${_p_lib} not found"
          return 33
        fi
        _dst="${_lib}.POTSIC"
        sp_f_zcpumv "${_p_lib}" "${_p_idir}" "${_dst}"
        _p_dst="${_p_idir}/${_dst}"
        if ! test -f "${_p_dst}" ; then
          sp_f_err "projectorfile ${_p_dst} not found"
          return 34
        fi
        cat "${_p_dst}" >> "${_p_if}"
        rm -f "${_p_dst}"
      done
      # finalize
      _dst="POTSIC"
      sp_f_run_bcast ${_isd} "${_p_wdir}" "${_p_sdir}" "${_p_if}" "${_dst}"
      if test $? -gt 0 ; then
        return $?
      fi
      # clean
      rm -f "${_p_if}"
    fi # end GW
    # end POTSIC ------------------------
  fi # end LIBS
  # end bcast ---------------------------

  # prepare others --------------------------------------------------------------
  local _pfx="${MAININPUT}."
  local _oin=""
  for _oin in ${OTHERINPUTS}; do
    _p_if="${INPUTDIR}/${_oin}"
    if ! test -f "${_p_if}" ; then
      sp_f_err "file ${_p_if} not found"
      return 35
    fi
    _dst=${_oin##${_pfx}}
    _dst=${_dst%%${sp_s_z}}
     sp_f_run_bcast ${_isd} "${_p_wdir}" "${_p_sdir}" "${_p_if}" "${_dst}"
  done
  return 0
}


function sp_f_vasp_finish() {
  return 0
}


function sp_f_vasp_collect() {
  local _inp=$(sp_f_inm "${MAININPUT}")
  local _sfx="${1}"
  local _p_wdir=$(sp_f_inm "${WORKDIR}")

  _inp=${_inp%%${_sfx}}

  sp_f_run_collect
  if test $? -gt 0 ; then
    return $?
  fi

  if test "${NEB}" = "on" ; then
    cd "${_p_wdir}"

    local _r=""
    local _rs=""
    for _rs in ${_p_wdir}/[01]*; do
      if test -f "${_rs}" ; then
        sp_f_run_fsv "${_rs}" "${_inp}"
        _r=$?
        if test ${_r} -gt 0 ; then
          return ${_r}
        fi
      fi
    done
  fi

  return 0
}

function sp_f_vasp_summary() {
  sp_f_load z

  local _pb_bn=$(basename "${PRGBIN}")
  local _ld_bn=$(basename "${LIBDIR}")
  local _inp="${MAININPUT}"

  local _p_out="${_inp}.OSZICAR${sp_s_z}"
  if ! test -r "${_p_out}" ; then
    sp_f_err "missing: ${_p_out}"
    return 10
  fi
  local _etot=$(${sp_b_zc} "${_p_out}" | \
                awk 'BEGIN{etot=0.0}
                /^ *[0-9]+ *F=/{gsub(/=/,"",$8);etot=$3}
                END{printf "%12.9f", etot}')


  local _p_out="${_inp}.OUTCAR${sp_s_z}"
  if ! test -r "${_p_out}" ; then
    sp_f_err "missing: ${_p_out}"
    return 10
  fi
  local _tcpu=$(${sp_b_zc} "${_p_out}" | \
                awk -F: '/Total CPU time used/{gsub(" ","",$2);print $2}')

  local _tpc=$(((${_tcpu%%.*})/60))

  echo "${QUEUE} ${_pb_bn} ${_inp} ${_ld_bn} ${_etot} ${_tpc}"
}
