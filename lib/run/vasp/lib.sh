
function sp_f_vasp_prepare() {
  local _inp=""
  _inp=$(sp_f_run_inm ${MAININPUT})
  local _p_if=""

  # prepare inputs --------------------------------------------------------------
  _p_if="${INPUTDIR}/${_inp}${sp_s_vcntl}"
  if test -f "${_p_if}" ; then
    sp_f_zcpumv "${_p_if}" "${WORKDIR}" INCAR
  else
    sp_f_err "file ${_p_if} not found"
    return 21
  fi

  _p_if="${INPUTDIR}/${_inp}${sp_s_vgeom}"
  if test -f "${_p_if}" ; then
    sp_f_zcpumv "${_p_if}" "${WORKDIR}" POSCAR
  else
    sp_f_err "file ${_p_if} not found"
    return 22
  fi

  _p_if="${INPUTDIR}/${_inp}${sp_s_vkpts}"
  if test -f "${_p_if}" ; then
    sp_f_zcpumv "${_p_if}" "${WORKDIR}" KPOINTS
  else
    sp_f_err "file ${_p_if} not found"
    return 23
  fi

  if test "${GW}" = "on" ; then
    _p_if="${INPUTDIR}/${_inp}${sp_s_vqpts}"
    if test -f "${_p_if}" ; then
      sp_f_zcpumv "${_p_if}" "${WORKDIR}" QPOINTS
    else
      sp_f_err "file ${_p_if} not found"
      return 24
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
      sp_f_zcpumv "${_p_lib}" "${WORKDIR}"
      _t_p_lib="${WORKDIR}/POTCAR"
      if ! test -f "${_t_p_lib}" ; then
        sp_f_err "projectorfile ${_t_p_lib} not found"
        return 32
      fi
      cat "${_t_p_lib}" >> "${WORKDIR}/tmpPOTCAR"
      rm -f "${_t_p_lib}"

      # build potsic for GW calcs
      if test "${GW}" = "on" ; then
        _p_lib="${LIBDIR}/${_lib}/POTSIC${sp_s_z}"
        if ! test -f "${_p_lib}" ; then
          sp_f_err "projectorfile ${_p_lib} not found"
          return 33
        fi
        sp_f_zcpumv "${_p_lib}" "${WORKDIR}"
        _t_p_lib="${WORKDIR}/POTSIC"
        if ! test -f "${_t_p_lib}" ; then
          sp_f_err "projectorfile ${_t_p_lib} not found"
          return 34
        fi
        cat "${_t_p_lib}" >> "${WORKDIR}/tmpPOTSIC"
        rm -f "${_t_p_lib}"
      fi
    done

    # finalize
    mv -f "${WORKDIR}/tmpPOTCAR" "${WORKDIR}/POTCAR"
    if test "${GW}" = "on" ; then
      mv -f "${WORKDIR}/tmpPOTSIC" "${WORKDIR}/POTSIC"
    fi
  fi # LIBS

  # prepare others --------------------------------------------------------------
  local _pfx=${MAININPUT}
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
    sp_f_zcpumv "${_p_oin}" "${WORKDIR}" "${_oout}"
  done

  return 0
}


function sp_f_vasp_finish() {
  return 0
}

function sp_f_vasp_collect() {
  local _inp=""
  local _pna=${1:-true}
  local _sfx="${2}"

  if ${_pna} ; then
    _inp=$(sp_f_run_inm ${MAININPUT})
    _inp=${_inp%%${_sfx}}
  fi

  sp_f_run_collect

  if test $? -gt 0 ; then
    return $?
  fi

  if test "${NEB}" = "on" ; then
    cd "${WORKDIR}"

    local _r=""
    local _rs=""
    for _rs in ${WORKDIR}/[01]*; do
      if test -f "${_rs}" ; then
        sp_f_run_fsave "${_rs}" "${_inp}"
        _r=$?
        if test ${_r} -gt 0 ; then
          return ${_r}
        fi
      fi
    done
  fi

  return 0
}
