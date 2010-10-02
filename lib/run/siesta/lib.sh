

function sp_f_siesta_prepare() {
  local _s_l=${1:-${sp_s_spsf}}
  local _inp=$(sp_f_inm "${MAININPUT}")
  local _dst=""
  local _p_if=""
  local _p_wdir=$(sp_f_inm "${WORKDIR}" "@")
  local _p_sdir="${STAGEDIR}"
  local _isd=false

  if sp_f_ird "${WORKDIR}" "@" ; then _isd=true; fi

  _inp=${_inp%%${sp_g_scntl}}

  # prepare inputs --------------------------------------------------------------
  _dst="${_inp}${sp_g_scntl}"
  _p_if="${INPUTDIR}/${_dst}"
  sp_f_run_bcast ${_isd} "${_p_wdir}" "${_p_sdir}" "${_p_if}"
  if test $? -gt 0 ; then
    return $?
  fi

  # prepare libs ----------------------------------------------------------------
  if ! test -d "${LIBDIR}" ; then
    sp_f_wrn "directory ${LIBDIR} doesn't exist"
  fi

  local _lib=""
  if ! test -z "${LIBS}" ; then
    for _lib in ${LIBS}; do
      _p_if="${LIBDIR}/${_lib}"
      if ! test -f "${_p_if}" ; then
        sp_f_err "library file ${_p_if} not found"
        return 31
      fi
      _dst=${_lib%%.*${_s_l##.}*}${_s_l}
      sp_f_run_bcast ${_isd} "${_p_wdir}" "${_p_sdir}" "${_p_if}" "${_dst}"
    done
  fi

  # prepare others --------------------------------------------------------------
  local _oin=""
  for _oin in ${OTHERINPUTS}; do
    _p_if="${INPUTDIR}/${_oin}"
    if ! test -f "${_p_if}" ; then
      sp_f_err "file ${_p_if} not found"
      return 35
    fi
    sp_f_run_bcast ${_isd} "${_p_wdir}" "${_p_sdir}" "${_p_if}"
  done
  return 0
}


function sp_f_siesta_finish() {
  return 0
}


function sp_f_siesta_collect() {
  sp_f_run_collect false
}
