function sp_f_paw_check() {
  local _inp=$(sp_f_inm "${MAININPUT}")
  local _p_if=""
  local _lib=""
  local _p_lib=""
  local _s
  local _sarr="${sp_s_pcntl} ${sp_s_pgeom}"
  local _r

  _inp=${_inp%%${sp_s_pcntl}}
  # check main inputs
  for _s in  ${_sarr}; do
    _p_if="${INPUTDIR}/${_inp}${_s}"
    if ! test -r "${_p_if}" ; then
      sp_f_err_fnf "${_p_if}"
      return ${_FALSE_}
    fi
  done

  sp_f_run_check_libs
  _r=$?
  if test ${_r} -gt 0 ; then
    return ${_r}
  fi

  # check others
  sp_f_run_check_others
  _r=$?
  if test ${_r} -gt 0 ; then
    return ${_r}
  fi

  return ${_TRUE_}
}

function sp_f_paw_prepare() {
  local _inp=$(sp_f_inm "${MAININPUT}")
  local _p_if=""
  local _dst=""
  local _p_wdir=$(sp_f_inm "${WORKDIR}" "@")
  local _p_sdir="${STAGEDIR}"
  local _isd=false

  _inp=${_inp%%${sp_s_pcntl}}

  if sp_f_ird "${WORKDIR}" "@" ; then 
    _isd=true
  fi

  # prepare inputs
  _dst="${_inp}${sp_s_pcntl}"
  _p_if="${INPUTDIR}/${_dst}"
  sp_f_run_bcast ${_isd} "${_p_wdir}" "${_p_sdir}" "${_p_if}" "${_dst}"
  if test $? -gt 0 ; then
    return $?
  fi

  _dst="${_inp}${sp_s_pgeom}"
  _p_if="${INPUTDIR}/${_dst}"
  sp_f_run_bcast ${_isd} "${_p_wdir}" "${_p_sdir}" "${_p_if}" "${_dst}"
  if test $? -gt 0 ; then
    return $?
  fi

  # prepare libs
  if ! test -d "${LIBDIR}" ; then
    sp_f_wrn "does not exist ${LIBDIR}"
  fi
  sp_f_run_prepare_libs ${_isd} "${_p_wdir}" "${_p_sdir}" "${sp_s_pproj}"

  # prepare others
  sp_f_run_prepare_others ${_isd} "${_p_wdir}" "${_p_sdir}"

  return ${_TRUE_}
}

function sp_f_paw_finish() {
  return ${_TRUE_}
}

function sp_f_paw_collect() {
  local _inp=$(sp_f_inm "${MAININPUT}")
  _inp=${_inp%%${sp_s_pcntl}}

  local _sfx="${1}"
  local _p_wdir=$(sp_f_inm "${WORKDIR}")

  _inp=${_inp%%${_sfx}}

  sp_f_run_collect false
  if test $? -gt 0 ; then
    return $?
  fi

  return ${_TRUE_}
}
