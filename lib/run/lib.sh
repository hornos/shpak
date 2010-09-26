
sp_f_load z
sp_f_load mail



function sp_f_run_ird() {
  if test "${1:0:1}" = "<" ; then return 1; fi

  return 0
}


function sp_f_run_inm() {
  sp_f_run_ird "${1}"
  if test $? -gt 0 ; then
    echo "${1:1}"
  else
    echo "${1}"
  fi
  return 0
}


function sp_f_run_clean() {
  cd "${INPUTDIR}"

  sp_f_rmdir "${WORKDIR}"
  sp_f_rmlnk "${WORKDIRLINK}"

  return 0
}


function sp_f_run_fsave() {
  local _rs="${1}"
  local _inp="${2}"
  if ! test -z "${_inp}" ; then
    _inp="${_inp}."
  fi

  local _p_dst="${RESULTDIR}/${_inp}${_rs}${sp_s_z}"
  local _p_sav="${RESULTDIR}/${_inp}${_rs}.old${sp_s_z}"

  if test -f "${_p_dst}" ; then
    mv -f "${_p_dst}" "${_p_sav}"
    if test $? -gt 0 ; then
      sp_f_err "file ${_p_dst} can't be renamed"
      return 20
    fi
  fi

  local _crs="${_rs}${sp_s_z}"
  ${sp_b_z} "${_rs}"
  cp -f "${_crs}" "${_p_dst}"
  if test $? -gt 0 ; then
    sp_f_err "file ${_crs} can't be copied"
    return 21
  fi
  chmod u-w "${_p_dst}"
  rm -f "${_crs}"
  if test $? -gt 0 ; then
    sp_f_err "file ${_crs} can't be deleted"
    return 22
  fi

  return 0
}


function sp_f_run_collect() {
  local _inp=""
  local _pna=${1:-true}
  local _sfx="${2}"
  local _r=0
  local _rs=""

  if ${_pna} ; then
    _inp=$(sp_f_run_inm ${MAININPUT})
    _inp=${_inp%%${_sfx}}
  fi

  cd "${WORKDIR}"

  #
  for _rs in ${RESULTS}; do
    if test -f "${_rs}" ; then
      sp_f_run_fsave "${_rs}" "${_inp}"
      _r=$?
      if test ${_r} -gt 0 ; then
        return ${_r}
      fi
    elif test -d "${_rs}" ; then
      sp_f_wrn "directory copy is not implemented"
    else
      sp_f_wrn "file ${_rs} skipped"
    fi
  done

  return 0
}


function sp_f_runprg() {
  # options ---------------------------------------------------------------------
  local _prg=${1:-vasp}
  local _guide=${2:-vasp.guide}
  local _sched=${3}

  if ! test -z ${QUEUE_MAIL_TO} && ! test -z "${_sched}" ; then
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

  sp_f_mkdir "${WORKDIR}"
  if test $? -gt 0 ; then
    return 13
  fi

  sp_f_mkdir "${RESULTDIR}"
  if test $? -gt 0 ; then
    sp_f_run_clean
    return 14
  fi

  WORKDIRLINK=${INPUTDIR}/${_prg}-${USER}-${HOSTNAME}-${$}
  local _p_wdir=""
  _p_wdir=$(readlink ${WORKDIR})
  if test $? -gt 0 ; then
    _p_wdir="${WORKDIR}"
  fi

  sp_f_mklnk "${_p_wdir}" "${WORKDIRLINK}"

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

  # run program -----------------------------------------------------------------
  cd "${WORKDIR}"

  sp_f_stt "Input files in ${WORKDIR}:"
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

  sp_f_run_ird ${MAININPUT}
  _r=$?
  local _inp=""
  _inp=$(sp_f_run_inm ${MAININPUT})
  if test ${_r} -gt 0 ; then
    ${_program} < ${_inp} >& ${_out}
  else
    ${_program} >& ${_out}
  fi
  _r=$?

  sp_f_stt "Output files in ${WORKDIR}:"
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
  local _act=${1:-Started}
  # send mail
#  if ! test -z "${QUEUE_MAIL_TO}" && ! test -z "${sched}"; then
  if ! test -z "${QUEUE_MAIL_TO}" ; then
    local _sub="${_act}"
    local _msg="${_act}"
#    _sub=$(sp_f_run_mail_sub)
#    _msg=$(sp_f_run_mail_msg)
#    _sub="${_sub} ${_act}"
    sp_f_mail "${_sub}" "${_msg}" "${QUEUE_MAIL_TO}"
  fi
}
