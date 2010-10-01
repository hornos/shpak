
sp_f_load z
sp_f_load mail


function sp_f_run_clean() {
  cd "${INPUTDIR}"

  local _p_wdir=$(sp_f_inm "${WORKDIR}" "@")
  sp_f_rmdir "${_p_wdir}"
  sp_f_rmdir "${STAGEDIR}"
  sp_f_rmlnk "${WORKDIRLINK}"

  return 0
}


function sp_f_run_fsv() {
  local _rs="${1}"
  local _inp="${2}"
  if ! test -z "${_inp}" ; then
    _inp="${_inp}."
  fi

  local _p_dst="${RESULTDIR}/${_inp}${_rs}${sp_s_z}"

  sp_f_svzmv "${_rs}" "${_p_dst}"
}


function sp_f_run_collect() {
  local _inp=""
  local _irs=${1:-true}
  local _sfx="${2}"
  local _r=0
  local _rs=""
  local _p_wdir=$(sp_f_inm "${WORKDIR}" "@")

  if ${_irs} ; then
    _inp=$(sp_f_inm "${MAININPUT}")
    _inp=${_inp%%${_sfx}}
  fi

  cd "${_p_wdir}"

  #
  for _rs in ${RESULTS}; do
    if test -f "${_rs}" ; then
      sp_f_run_fsv "${_rs}" "${_inp}"
      _r=$?
      if test ${_r} -gt 0 ; then
        return ${_r}
      fi
    elif test -d "${_rs}" ; then
      sp_f_wrn "directory copy is not implemented"
    else
      sp_f_wrn "unknown file ${_rs} skipped"
    fi
  done

  return 0
}


function sp_f_runprg() {
  # options ---------------------------------------------------------------------
  local _prg=${1:-vasp}
  local _guide=${2:-vasp.guide}
  _sched=${3}

  if ! test -z "${_sched}" ; then
    sp_f_load queue/${_sched}
  fi

  # load program library --------------------------------------------------------
  sp_f_load run/${_prg}

  # read guide ------------------------------------------------------------------
  if ! test -f "${_guide}" ; then
    sp_f_err "file ${_guide} not found"
    return 10
  fi
  . "${_guide}"

  # checks ----------------------------------------------------------------------
  if ! test -x "${PRGBIN}" ; then
    sp_f_err "executable ${PRGBIN} not found"
    return 11
  fi

  # create directories ----------------------------------------------------------
  if ! test -d "${INPUTDIR}" ; then
    sp_f_err "directory ${INPUTDIR} doesn't exist"
    return 12
  fi

  cd "${INPUTDIR}"

  # workdir
  local _p_wdir=$(sp_f_inm "${WORKDIR}" "@")
  sp_f_mkdir "${_p_wdir}"
  if test $? -gt 0 ; then
    return 13
  fi

  # resultdir
  sp_f_mkdir "${RESULTDIR}"
  if test $? -gt 0 ; then
    sp_f_run_clean
    return 14
  fi

  # stage dir for broadcast
  STAGEDIR=""
  local _t_dir="${_prg}-${USER}-${HOSTNAME}-${$}"
  sp_f_ird "${WORKDIR}" "@"
  if test $? -gt 0 ; then
    local _p_sdir="${sp_p_tmp}/tmp-${_t_dir}"
    sp_f_mkdir "${_p_sdir}"
    if test $? -gt 0 ; then
      sp_f_run_clean
      return 15
    fi
    STAGEDIR="${_p_sdir}"
    sp_f_stt "Input broadcast:"
    echo "${STAGEDIR}"
  fi

  WORKDIRLINK="${INPUTDIR}/${_prg}-${USER}-${HOSTNAME}-${$}"
  _p_wdir=$(readlink "${_p_wdir}")
  if test $? -gt 0 ; then
    _p_wdir=$(sp_f_inm "${WORKDIR}" "@")
  fi

  sp_f_ird "${WORKDIR}" "@"
  if test $? -gt 0 ; then
    sp_f_mklnk "." "${WORKDIRLINK}"
  else
    sp_f_mklnk "${_p_wdir}" "${WORKDIRLINK}"
  fi

  if test $? -gt 0 ; then
    sp_f_wrn "link ${_p_wdir} can't be created"
  fi


  # preapre ---------------------------------------------------------------------
  sp_f_${_prg}_prepare
  local _r=$?
  if test ${_r} -gt 0 ; then
    if test "${ONERR}" = "clean" ; then
      sp_f_run_clean
    fi
    sp_f_err "program ${_prg} prepare exited with error code ${_r}"
    return ${_r}
  fi

  # rm stage dir
  sp_f_rmdir "${STAGEDIR}"


  # run program -----------------------------------------------------------------
  cd "${_p_wdir}"

  sp_f_stt "Input files in ${_p_wdir}:"
  ls

  local _out=${_prg}.output
  local _program="${PRGBIN}"

  if ! test -z "${PRERUN}" ; then
    _program="${PRERUN} ${_program}"
  fi

  if ! test -z "${PARAMS}" ; then
    _program="${_program} ${PARAMS}"
  fi

# start program -----------------------------------------------------------------
  sp_f_run_mail "Started"

  sp_f_stt "Running: ${_prg}"
  echo "${_program}"

  sp_f_ird "${MAININPUT}"
  _r=$?
  local _inp=$(sp_f_inm "${MAININPUT}")
  if test ${_r} -gt 0 ; then
    ${_program} < "${_inp}" >& "${_out}"
  else
    ${_program} >& "${_out}"
  fi
  _r=$?

  sp_f_stt "Output files in ${_p_wdir}:"
  ls

  # check exit status -----------------------------------------------------------
  if test ${_r} -gt 0 ; then
    if test "${ONERR}" = "clean" ; then
      sp_f_run_clean
    fi
    sp_f_err "program ${_program} exited with error ${_r}"
    sp_f_run_mail "Failed (${_r})"
    return ${_r}
  fi

  # finish ----------------------------------------------------------------------
  sp_f_${_prg}_finish
  _r=$?
  if test ${_r} -gt 0 ; then
    if test "${ONERR}" = "clean" ; then
      sp_f_run_clean
    fi
    sp_f_err "program ${_prg} finish exited with error code ${_r}"
    sp_f_run__mail "Failed (finish)"
    return ${_r}
  fi

  # collect ---------------------------------------------------------------------
  sp_f_stt "Saved output files:"
  ls ${RESULTS}

  sp_f_${_prg}_collect
  _r=$?
  if test ${_r} -gt 0 ; then
    if test "${ONERR}" = "clean" ; then
      sp_f_run_clean
    fi
    sp_f_err "program ${_prg} collect exited with error code ${_r}"
    sp_f_run_mail "Failed (collect)"
    return ${_r}
  fi

  sp_f_run_clean
  sp_f_run_mail "Completed"
  echo ""
  sp_f_dln
  echo ""
}

function sp_f_run_mail() {
  # remark: _sched is global
  local _act=${1:-Started}

  if ! test -z "${QUEUE_MAIL_TO}" ; then
    local _sub="${_act}"
    local _msg="${_act}"
    if ! test -z "${_sched}" ; then
      _sub=$(sp_f_qmail_sub)
      _msg=$(sp_f_qmail_msg)
      _sub="${_sub} ${_act}"
    fi
    sp_f_mail "${_sub}" "${_msg}" "${QUEUE_MAIL_TO}"
  fi
}

function sp_f_run_bcast() {
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
