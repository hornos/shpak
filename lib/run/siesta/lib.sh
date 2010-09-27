

function __SP_siesta_prepare() {
  local _sfx=${1:-${sp_s_spsf}}
  local _inp=""
  _inp=$(sp_f_run_inm ${MAININPUT})
  _inp=${_inp%%${sp_g_scntl}}
  local _p_if=""

  # prepare inputs --------------------------------------------------------------
  _p_if="${INPUTDIR}/${_inp}${sp_g_scntl}"
  if test -f "${_p_if}" ; then
    sp_f_zcpzmv "${_p_if}" "${WORKDIR}"
  else
    sp_f_err "file ${_p_if} not found"
    return 21
  fi

  # prepare libs ----------------------------------------------------------------
  if ! test -d "${LIBDIR}" ; then
    sp_f_wrn "directory ${LIBDIR} doesn't exist"
  fi

  local _lib=""
  local _p_lib=""
  local _n_lib=""
  if ! test -z "${LIBS}" ; then
    for _lib in ${LIBS}; do
      _p_lib="${LIBDIR}/${_lib}"
      if ! test -f "${_p_lib}" ; then
        errmsg "library file ${_p_lib} not found"
        return 31
      fi

      _n_lib=${_lib%%.*${_sfx##.}*}${_sfx}
      sp_f_zcpzmv "${_p_lib}" "${WORKDIR}" "${_n_lib}"
    done
  fi # LIBS

  # prepare others --------------------------------------------------------------
  local _oin=""
  local _p_oin=""
  for _oin in ${OTHERINPUTS}; do
    _p_oin="${INPUTDIR}/${_oin}"
    if ! test -f "${_p_oin}" ; then
      errmsg "file ${_p_oin} not found"
      return 35
    fi
    sp_f_zcpzmv "${_p_oin}" "${WORKDIR}"
  done

  return 0
}


function sp_f_siesta_finish() {
  return 0
}

function sp_f_siesta_collect() {
  sp_f_run_collect false
  return $?
}
