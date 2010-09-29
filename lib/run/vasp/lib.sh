
function sp_f_vasp_bcast() {
  local _isd=${1}
  local _p_if="${2}"
  local _dst="${3}"
  local _p_wdir="${4}"
  local _p_sdir="${5}"

  if test -f "${_p_if}" ; then
    if ${_isd} ; then
      sp_f_zcpumv "${_p_if}" "${_p_sdir}" "${_dst}"
      ${sp_b_qbca} "${_p_sdir}/${_dst}" "${_p_wdir}/${_dst}"
    else
      sp_f_zcpumv "${_p_if}" "${_p_wdir}" "${_dst}"
    fi
  else
    sp_f_err "file ${_p_if} not found"
    return 21
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

  sp_f_ird "${WORKDIR}" "@"
  if test $? -gt 0 ; then
    _isd=true
  fi

  # prepare inputs --------------------------------------------------------------
  _p_if="${INPUTDIR}/${_inp}${sp_s_vcntl}"
  _dst="INCAR"
  sp_f_vasp_bcast ${_isd} "${_p_if}" "${_dst}" "${_p_wdir}" "${_p_sdir}"
  if test $? -gt 0 ; then
    return $?
  fi

  _p_if="${INPUTDIR}/${_inp}${sp_s_vgeom}"
  _dst="POSCAR"
  sp_f_vasp_bcast ${_isd} "${_p_if}" "${_dst}" "${_p_wdir}" "${_p_sdir}"
  if test $? -gt 0 ; then
    return $?
  fi

  _p_if="${INPUTDIR}/${_inp}${sp_s_vkpts}"
  _dst="KPOINTS"
  sp_f_vasp_bcast ${_isd} "${_p_if}" "${_dst}" "${_p_wdir}" "${_p_sdir}"
  if test $? -gt 0 ; then
    return $?
  fi

  if test "${GW}" = "on" ; then
    _p_if="${INPUTDIR}/${_inp}${sp_s_vqpts}"
    _dst="QPOINTS"
    sp_f_vasp_bcast ${_isd} "${_p_if}" "${_dst}" "${_p_wdir}" "${_p_sdir}"
    if test $? -gt 0 ; then
      return $?
    fi
  fi

  # prepare libs ----------------------------------------------------------------
  if ! test -d "${LIBDIR}" ; then
    sp_f_wrn "directory ${LIBDIR} doesn't exist"
  fi

  local _lib=""
  local _p_lib=""
  local _t_p_lib=""
  if ! test -z "${LIBS}" ; then
    for _lib in ${LIBS}; do
      # build potcar
      _p_lib="${LIBDIR}/${_lib}/POTCAR${sp_s_z}"
      if ! test -f "${_p_lib}" ; then
        sp_f_err "projectorfile ${_p_lib} not found"
        return 31
      fi
      sp_f_zcpumv "${_p_lib}" "${_p_wdir}"
      _t_p_lib="${_p_wdir}/POTCAR"
      if ! test -f "${_t_p_lib}" ; then
        sp_f_err "projectorfile ${_t_p_lib} not found"
        return 32
      fi
      cat "${_t_p_lib}" >> "${_p_wdir}/tmpPOTCAR"
      rm -f "${_t_p_lib}"

      # build potsic for GW calcs
      if test "${GW}" = "on" ; then
        _p_lib="${LIBDIR}/${_lib}/POTSIC${sp_s_z}"
        if ! test -f "${_p_lib}" ; then
          sp_f_err "projectorfile ${_p_lib} not found"
          return 33
        fi
        sp_f_zcpumv "${_p_lib}" "${_p_wdir}"
        _t_p_lib="${_p_wdir}/POTSIC"
        if ! test -f "${_t_p_lib}" ; then
          sp_f_err "projectorfile ${_t_p_lib} not found"
          return 34
        fi
        cat "${_t_p_lib}" >> "${_p_wdir}/tmpPOTSIC"
        rm -f "${_t_p_lib}"
      fi
    done

    # finalize
    mv -f "${_p_wdir}/tmpPOTCAR" "${_p_wdir}/POTCAR"
    if test "${GW}" = "on" ; then
      mv -f "${_p_wdir}/tmpPOTSIC" "${_p_wdir}/POTSIC"
    fi
  fi # LIBS

  # prepare others --------------------------------------------------------------
  local _pfx="${MAININPUT}"
  local _oin=""
  local _p_oin=""
  local _oout=""
  for _oin in ${OTHERINPUTS}; do
    _p_oin="${INPUTDIR}/${_oin}"
    if ! test -f "${_p_oin}" ; then
      sp_f_err "file ${_p_oin} not found"
      return 35
    fi
    _oout=${_oin##${_pfx}.}
    _oout=${_oout%%${sp_s_z}}
    sp_f_zcpumv "${_p_oin}" "${_p_wdir}" "${_oout}"
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
