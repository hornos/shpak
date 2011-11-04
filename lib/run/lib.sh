sp_f_load z
sp_f_load net/ma

#/// \fn sp_f_run_check
#/// \brief run program input integrity checks
#///
#/// \param 1 CHARACTER(*) program name
#/// \param 2 CHARACTER(*) guide file
function sp_f_run_check() {
  local _prg="${1}"
  local _guide="${2}"
  local _r=${_FALSE_}

  if test -z "${_prg}" || test -z "${_guide}" ; then
    return ${_FALSE_}
  fi

  sp_f_stt "Check: ${_prg} ${_guide}"

  # load program library
  sp_f_load run/${_prg}

  # read guide
  if ! test -f "${_guide}" ; then
    sp_f_err_fnf "${_guide}"
    return ${_FALSE_}
  fi
  . "${_guide}"

  # checks
  if ! test -x "${PRGBIN}" ; then
    sp_f_err_fnf "${PRGBIN}"
    return ${_FALSE_}
  fi

  if ! test -d "${INPUTDIR}" ; then
    sp_f_err_fnf "${INPUTDIR}"
    return ${_FALSE_}
  fi

  if ! test -d "${LIBDIR}" ; then
    sp_f_err_fnf "${LIBDIR}"
    return ${_FALSE_}
  fi

  # run program specific check
  sp_f_${_prg}_check
  _r=$?
  if test ${_r} -gt 0 ; then
    return ${_r}
  fi
  echo ""
  echo "ALL CHECKS PASSED"
  return ${_TRUE_}
}

#/// \fn sp_f_run_clean
#/// \brief cleanup aftermath
function sp_f_run_clean() {
  cd "${INPUTDIR}"
  local _p_wdir=$(sp_f_inm "${WORKDIR}" "@")
  sp_f_rmdir "${_p_wdir}"
  sp_f_rmdir "${STAGEDIR}"
  sp_f_rmlnk "${WORKDIRLINK}"
  return ${_TRUE_}
}

#/// \fn sp_f_run_fsv
#/// \brief save with prefix
#///
#/// \param 1 CHARACTER(*) file
#/// \param 2 CHARACTER(*) prefix
function sp_f_run_fsv() {
  local _rs="${1}"
  local _inp="${2}"
  if ! test -z "${_inp}" ; then
    _inp="${_inp}."
  fi
  local _p_dst="${RESULTDIR}/${_inp}${_rs}${sp_s_z}"
  sp_f_svzmv "${_rs}" "${_p_dst}"
}

#/// \fn sp_f_run_collect
#/// \brief collect results suffix ($2) might ($1) be removed
#///
#/// \param 1 LOGICAL remove suffix?
#/// \param 2 CHARACTER(*) suffix
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

  for _rs in ${RESULTS}; do
    # if test -f "${_rs}" ; then
    if test -r "${_rs}" ; then
      sp_f_run_fsv "${_rs}" "${_inp}"
      _r=$?
      if test ${_r} -gt 0 ; then
        return ${_r}
      fi
    else
      sp_f_wrn "skipped unknown ${_rs}"
    fi
  done

  return ${_TRUE_}
}


#/// \fn sp_f_runprg
#/// \brief run program
#///
#/// \param 1 CHARACTER(*) program
#/// \param 2 CHARACTER(*) guide file
#/// \param 3 CHARACTER(*) scheduler
function sp_f_runprg() {
  local _prg=${1:-vasp}
  local _guide=${2:-vasp.guide}
  _sched=${3}
  local _r

  # load scheduler library
  if ! test -z "${_sched}" ; then
    sp_f_load que/${_sched}
  fi

  # load program library
  sp_f_load run/${_prg}

  # read guide and general check
  sp_f_run_check "${_prg}" "${_guide}"
  _r=$?
  if test ${_r} -gt 0 ; then
    return ${_r}
  fi

  # create directories
  cd "${INPUTDIR}"

  # workdir
  local _p_wdir=$(sp_f_inm "${WORKDIR}" "@")
  if ! sp_f_mkdir "${_p_wdir}" ; then
    return ${_FALSE_}
  fi

  # resultdir
  if ! sp_f_mkdir "${RESULTDIR}" ; then
    sp_f_run_clean
    return ${_FALSE_}
  fi

  # tempdir
  local _t_dir="${_prg}-${USER}-${HOSTNAME}-${$}"

  # stage dir for broadcast
  if sp_f_ird "${WORKDIR}" "@" ; then
    local _p_sdir="${sp_p_tmp}/tmp-${_t_dir}"
    if ! test -z "${STAGEDIR}" ; then
      _p_sdir="${STAGEDIR}"
    else
      STAGEDIR="${_p_sdir}"
    fi
    sp_f_mkdir "${_p_sdir}"
    if test $? -gt 0 ; then
      sp_f_run_clean
      return ${_FALSE_}
    fi
    sp_f_stt "Input broadcast"
    echo "Stage directory: ${STAGEDIR}"
    echo "Check local node scratch for output!"
  fi

  # workdir link
  WORKDIRLINK="${INPUTDIR}/${_prg}-${USER}-${HOSTNAME}-${$}"
  _p_wdir=$(readlink "${_p_wdir}")
  if test $? -gt 0 ; then
    _p_wdir=$(sp_f_inm "${WORKDIR}" "@")
  fi

  if sp_f_ird "${WORKDIR}" "@" ; then
    sp_f_mklnk "." "${WORKDIRLINK}"
  else
    sp_f_mklnk "${_p_wdir}" "${WORKDIRLINK}"
  fi
  if test $? -gt 0 ; then
    sp_f_wrn "cannot create ${_p_wdir}"
  fi

  # preapre
  sp_f_${_prg}_prepare
  _r=$?
  if test ${_r} -gt 0 ; then
    if test "${ONERR}" = "clean" ; then
      sp_f_run_clean
    fi
    sp_f_err "${_prg} prepare exited with error code ${_r}"
    return ${_r}
  fi

  # delete stage dir
  sp_f_rmdir "${STAGEDIR}"

  # run program
  cd "${_p_wdir}"

  sp_f_stt "Input files in ${_p_wdir}:"
  ls

  # MPI & options
  local _out=${_prg}.output
  local _program="${PRGBIN}"

  if ! test -z "${PRERUN}" ; then
    _program="${PRERUN} ${_program}"
  fi

  if ! test -z "${PARAMS}" ; then
    _program="${_program} ${PARAMS}"
  fi

  # start program
  sp_f_run_mail "Started"

  sp_f_stt "Running: ${_prg}"
  # echo "${_program}"

  # set ld libs
  if ! test -z "${LDLIB}" ; then
    echo "LD_LIBRARY_PATH: ${LDLIB}"
    if test -z "${LD_LIBRARY_PATH}" ; then
      export LD_LIBRARY_PATH=${LDLIB}
    else
      export LD_LIBRARY_PATH=${LDLIB}:${LD_LIBRARY_PATH}
    fi
  fi

  local _inp=$(sp_f_inm "${MAININPUT}")
  if sp_f_ird "${MAININPUT}" ; then
    if ! test -z "${PRELOAD}" ; then
      echo "LD_PRELOAD: ${PRELOAD}"
      if sp_f_ird "${MAININPUT}" "!" ; then
        LD_PRELOAD="${PRELOAD}" ${_program} "${_inp}" >& "${_out}"
        echo "LD_PRELOAD=${PRELOAD} ${_program} ${_inp} >& ${_out}"
      else
        LD_PRELOAD="${PRELOAD}" ${_program} < "${_inp}" >& "${_out}"
        echo "LD_PRELOAD=${PRELOAD} ${_program} < ${_inp} >& ${_out}"
      fi
    else
      if sp_f_ird "${MAININPUT}" "!" ; then
        ${_program} "${_inp}" >& "${_out}"
        echo "${_program} ${_inp} >& ${_out}"
      else
        ${_program} < "${_inp}" >& "${_out}"
        echo "${_program} < ${_inp} >& ${_out}"
      fi
    fi
  else
    if ! test -z "${PRELOAD}" ; then
      echo "LD_PRELOAD: ${PRELOAD}"
      LD_PRELOAD="${PRELOAD}" ${_program} >& "${_out}"
    else
      ${_program} >& "${_out}"
    fi
  fi
  _r=$?

  sp_f_stt "Temporary directory in case of A : B"
  local _oemsg=" error: not saved   success: saved"
  case "${ONERR}" in 
    "clean") _oemsg=" error: cleaned     success: saved";;
    "save")  _oemsg=" error: saved       success: saved";;
    "leave") _oemsg=" error: not saved   success: not saved";;
  esac
  echo "${_oemsg}"

  sp_f_stt "Output files in\n${_p_wdir}"
  ls

  # check exit status
  if test ${_r} -gt 0 && ! test "${ONERR}" = "save" ; then
    if test "${ONERR}" = "clean" ; then
      sp_f_run_clean
    fi
    sp_f_err "program ${_program} exited with error ${_r}"
    sp_f_run_mail "Failed (${_r})"
    return ${_r}
  fi

  # finish
  sp_f_${_prg}_finish
  _r=$?
  if test ${_r} -gt 0 && ! test "${ONERR}" = "save" ; then
    if test "${ONERR}" = "clean" ; then
      sp_f_run_clean
    fi
    sp_f_err "program ${_prg} finish exited with error code ${_r}"
    sp_f_run__mail "Failed (finish)"
    return ${_r}
  fi

  # collect
  sp_f_stt "Saved output files:"
  ls ${RESULTS}

  if test "${ONERR}" != "leave" ; then
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
  fi
  sp_f_run_mail "Completed"
  echo ""
  sp_f_dln
  echo ""
}

#/// \fn sp_f_run_mail
#/// \brief mailer for the run
#///
#/// \param 1 CHARACTER(*) message
#///
#/// Remark: _sched is global
function sp_f_run_mail() {
  local _act=${1:-Started}

  if ! test -z "${QUEUE_MAIL_TO}" ; then
    local _sub="${_act}"
    local _msg="${_act}"
    if ! test -z "${_sched}" ; then
      _sub=$(sp_f_qmail_sub)
      _msg=$(sp_f_qmail_msg)
      _sub="${_sub} ${_act}"
    fi
    sp_f_mail "${QUEUE_MAIL_TO}" "${_sub}" "${_msg}"
  fi
}

#/// \fn sp_f_run_bcast
#/// \brief local or remote boradcast a file
#///
#/// \param 1 LOGICAL broadcast via a stage directory
#/// \param 2 CHARACTER(*) work directory
#/// \param 3 CHARACTER(*) stage directory
#/// \param 4 CHARACTER(*) input file
#/// \param 5 CHARACTER(*) destination file
function sp_f_run_bcast() {
  local _isd=${1}
  local _p_wdir="${2}"
  local _p_sdir="${3}"
  local _p_if="${4}"
  local _dst="${5}"
  local _n_dst=$(sp_f_zbn "${_p_if}")

  if test -d "${_p_if}" ; then
    cp -R "${_p_if}" "${_p_wdir}"
    return ${_TRUE_}
  elif test -f "${_p_if}" ; then
    if ${_isd} ; then
      sp_f_zcpumv "${_p_if}" "${_p_sdir}" "${_dst}"
      if test -z "${_dst}" ; then
        _dst="${_n_dst}"
      fi
      ${sp_b_qbca} "${_p_sdir}/${_dst}" "${_p_wdir}/${_dst}"
    else
      sp_f_zcpumv "${_p_if}" "${_p_wdir}" "${_dst}"
    fi
  else
    sp_f_err_fnf "${_p_if}"
    return ${_FALSE_}
  fi
  return ${_TRUE_}
}


#/// \fn sp_f_run_check_libs
#/// \brief check input libraries
function sp_f_run_check_libs() {
  local _lib=""
  local __lib=""
  local _p_if=""

  for _lib in ${LIBS}; do
    __lib=$(sp_f_inm "${_lib}" "!")
    _p_if="${LIBDIR}/${__lib}"
    if ! test -f "${_p_if}" ; then
      sp_f_err_fnf "${_p_if}"
      return ${_FALSE_}
    fi
  done
  return ${_TRUE_}
}

#/// \fn sp_f_run_prepare_libs
#/// \brief preapre and broadcast input libraries
#///
#/// \param 1 LOGICAL broadcast via stage directory
#/// \param 2 CHARACTER(*) work directory
#/// \param 3 CHARACTER(*) stage directory
#///
#/// Remark: input libraries are datafiles for the 
#/// program and are not connected with shared os libs
function sp_f_run_prepare_libs() {
  local _isd=${1}
  local _p_wdir="${2}"
  local _p_sdir="${3}"
  local _s_l="${4}"
  local _p_if=""
  local _dst=""
  local _lib=""
  local __lib=""

  for _lib in ${LIBS}; do
    __lib=$(sp_f_inm "${_lib}" "!")
    _p_if="${LIBDIR}/${__lib}"
    if ! test -f "${_p_if}" ; then
      sp_f_err_fnf "${_p_if}"
      return ${_FALSE_}
    fi
    if sp_f_ird "${_lib}" "!" ; then
      _dst=""
    else
      _dst=${__lib%%.*${_s_l##.}*}${_s_l}
      _dst=${_dst##*/}
    fi
    sp_f_run_bcast ${_isd} "${_p_wdir}" "${_p_sdir}" "${_p_if}" "${_dst}"
  done
  return ${_TRUE_}
}

#/// \fn sp_f_run_check_others
#/// \brief check other inputs
function sp_f_run_check_others() {
  local _p_if=""
  local _oin=""

  for _oin in ${OTHERINPUTS}; do
    _p_if="${INPUTDIR}/${_oin}"
    # if ! test -f "${_p_if}" ; then
    if ! test -r "${_p_if}" ; then
      sp_f_err_fnf "${_p_if}"
      return ${_FALSE_}
    fi
  done
  return ${_TRUE_}
}

#/// \fn sp_f_run_prepare_others
#/// \brief prepare and broadcast other inputs
#///
#/// \param 1 LOGICAL broadcast via stage directory
#/// \param 2 CHARACTER(*) work directory
#/// \param 3 CHARACTER(*) stage directory
function sp_f_run_prepare_others() {
  local _isd=${1}
  local _p_wdir="${2}"
  local _p_sdir="${3}"
  local _p_if=""
  local _oin=""

  for _oin in ${OTHERINPUTS}; do
    _p_if="${INPUTDIR}/${_oin}"
    # if ! test -f "${_p_if}" ; then
    if ! test -r "${_p_if}" ; then
      sp_f_err_fnf "${_p_if}"
      return ${_FALSE_}
    fi
    sp_f_run_bcast ${_isd} "${_p_wdir}" "${_p_sdir}" "${_p_if}"
  done
  return ${_TRUE_}
}

#/// \fn sp_f_run_summary
#/// \brief show program specific summary
#///
#/// \param 1 CHARACTER(*) program
#/// \param 2 CHARACTER(*) guide file
function sp_f_run_summary() {
  # options
  local _prg=${1:-vasp}
  local _guide=${2:-vasp.guide}

  # load program library
  sp_f_load run/${_prg}

  # read guide
  if ! test -f "${_guide}" ; then
    sp_f_err_fnf "${_guide}"
    return ${_FALSE_}
  fi
  . "${_guide}"

  # read guide and general check
  sp_f_${_prg}_summary
}
