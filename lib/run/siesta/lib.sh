

function sp_f_siesta_prepare() {
  local _s_l=${1:-${sp_s_spsf}}
  local _inp=$(sp_f_inm "${MAININPUT}")
  local _dst=""
  local _p_if=""
  local _p_wdir=$(sp_f_inm "${WORKDIR}" "@")
  local _p_sdir="${STAGEDIR}"
  local _isd=false

  if sp_f_ird "${WORKDIR}" "@" ; then _isd=true; fi

  _inp=${_inp%%${sp_s_scntl}}

  # prepare inputs --------------------------------------------------------------
  _dst="${_inp}${sp_s_scntl}"
  _p_if="${INPUTDIR}/${_dst}"
  sp_f_run_bcast ${_isd} "${_p_wdir}" "${_p_sdir}" "${_p_if}" "${_dst}"
  if test $? -gt 0 ; then
    return $?
  fi

  # prepare libs ----------------------------------------------------------------
  if ! test -d "${LIBDIR}" ; then
    sp_f_wrn "directory ${LIBDIR} doesn't exist"
  fi
  sp_f_run_prepare_libs ${_isd} "${_p_wdir}" "${_p_sdir}"

  # prepare others --------------------------------------------------------------
  sp_f_run_prepare_others ${_isd} "${_p_wdir}" "${_p_sdir}"

  return 0
}


function sp_f_siesta_finish() {
  return 0
}


function sp_f_siesta_collect() {
  sp_f_run_collect false
}
