#f3--&7-9-V13------21-------------------42--------------------64------72

sp_g_kmpaff=( "none" \
              "granularity=core,compact,0,0" \
              "norespect,granularity=core,none,0,0" \
              "granularity=thread,compact0,0" )

#/// \var sp_f_jobsub
#/// \brief submit job
#///
#/// \param 1 submit mode
#/// \param 2 job file
#/// \param 3 check before submission
function sp_f_jobsub() {
  local _mode=${1:-submit}
  local _ji=${2:-start.job}
  local _check=${3:-false}
  local _r

# read job info
#f3--&7-9-V13------21-------------------42--------------------64------72
  if test -f "${_ji}" ; then
    . ${_ji}
  else
    sp_f_err "not found ${_ji}"
    return 1
  fi

# MODE: summary
#f3--&7-9-V13------21-------------------42--------------------64------72
  if test "${_mode}" = "summary" ; then
    sp_f_jobsub_check "${COMMAND}" "${_mode}"
    return $?
  fi

# read queue info
#f3--&7-9-V13------21-------------------42--------------------64------72
  local _p_qi="${sp_p_queues}/${QUEUE:-default}"
  if test -r "${_p_qi}" ; then
    . ${_p_qi}
  else
    sp_f_err "not found ${_p_qi}"
    return 2
  fi

# MODE: submit / login
#f3--&7-9-V13------21-------------------42--------------------64------72
  local _sched=${SCHED}
  sp_f_load que/${_sched}

  if test "${_mode}" = "login" ; then
    local _p_qbat="./${_sched}.login.sh"
  else
    local _p_qbat="./${_sched}.sh"
  fi
  local _tt
  _tt=$(date)

# write job control file
  echo "#!${sp_p_qsh}"      > "${_p_qbat}"
  echo "## ${_tt}"         >> "${_p_qbat}"

# resource parameters
  local _nodes=${NODES:-1}
  local _cores=${CORES:-4}
  local _sckts=${SCKTS:-2}
  local _thrds=${THRDS:-1}
  local _kmpaff=${KMPAFF:-0}

  local _sockets=$((_nodes*_sckts))
  local _tasks=$((_sckts*_cores))
  local _slots=$((_nodes*_tasks))
  local _threads=${_cores}

  if test ${_thrds} -gt 1 ; then
    _threads=${_thrds}
  fi

# global compoiund resources
  SLOTS=${_slots}
  TASKS=${_tasks}

# common checks
  if test -z "${COMMAND}" ; then
    sp_f_err "no command"
    return 10
  fi

  if test -z "${NAME}" ; then
    sp_f_err "no job name"
    return 11
  fi

# scheduler specific
  sp_f_${_sched} "${_mode}" "${_p_qbat}"

  if test "${_mode}" != "login" ; then
# setup
    if ! test -z "${QUEUE_SETUP}" ; then
      echo "${QUEUE_SETUP}"                        >> "${_p_qbat}"
    fi

# ulimit
    if ! test -z "${QUEUE_ULIMIT}" ; then
      echo "${QUEUE_ULIMIT}"                       >> "${_p_qbat}"
    fi

# mail
    if test "${QUEUE_MAIL}" = "runprg" ; then
      echo "export QUEUE_MAIL_TO=${QUEUE_MAIL_TO}" >> "${_p_qbat}"
    fi

# MPI
    if test "${HYBMPI}" = "on" ; then
      echo "export HYBMPI_MPIRUN_OPTS=\"-np ${_sockets} -npernode ${_sckts}\"" >> "${_p_qbat}"
    else
      _threads=${_thrds}
      echo "export HYBMPI_MPIRUN_OPTS=\"-np ${_slots} -npernode ${_tasks}\""   >> "${_p_qbat}"
    fi
    # openMP & Intel MKL
    echo "export OMP_NUM_THREADS=${_threads}" >> "${_p_qbat}"
    echo "export MKL_NUM_THREADS=${_threads}" >> "${_p_qbat}"
    if test ${_threads} -gt 1 ; then
      echo "export KMP_LIBRARY=turnaround"    >> "${_p_qbat}"
      if test ${_kmpaff} -gt 0 ; then
        echo "export KMP_AFFINITY=${sp_g_kmpaff[${_kmpaff}]}" >> "${_p_qbat}"
      fi
      echo "export MKL_DYNAMIC=TRUE"          >> "${_p_qbat}"
    else
      echo "export KMP_LIBRARY=serial"        >> "${_p_qbat}"
      echo "export MKL_DYNAMIC=FALSE"         >> "${_p_qbat}"
    fi

# setup command an mail
    if test "${COMMAND/*runprg*/runprg}" = "runprg" ; then
      COMMAND="${COMMAND} -s ${SCHED}"
      # check
      if ${_check} ; then
        sp_f_jobsub_check "${COMMAND}"
        _r=$?
        if test ${_r} -gt 0 ; then
          return ${_r}
        fi
      fi
    fi

    echo "${COMMAND}"                         >> "${_p_qbat}"
  fi

# submission, print out job file
  sp_f_stt "Scheduler: ${_sched}"
  cat "${_p_qbat}"
  sp_f_sln
  echo

# MODE: login
#f3--&7-9-V13------21-------------------42--------------------64------72
  if test "${_mode}" = "login" ; then
    local _q="Login"
  else
    local _q="Submit"
  fi
  sp_f_yesno "${_q} ?"
  _r=$?
  if test ${_r} -gt 0 ; then
    return ${_r}
  fi
  echo
  if test "${_mode}" = "login" ; then
    sh "${_p_qbat}"
  else
    ${sp_b_qsub} "${_p_qbat}"
  fi
}

#/// \fn sp_f_jobsub_check
#/// \brief deep check the job
#///
#/// \param 1 CHARACTER(*) command
#/// \param 2 CHARACTER(*) mode
function sp_f_jobsub_check() {
  local _cmd="${1##runprg}"
  local _mode="${2:-submit}"
  local _prg="vasp"
  local _guide="vasp.guide"
  local _opt
  local _r
  local _tmp

  OPTIND=1
  while getopts p:g:s: _opt ${_cmd[@]}; do
    case ${_opt} in
      p) _prg=${OPTARG};;
      g) _guide=${OPTARG};;
      s) _tmp=${OPTARG};;
    esac
  done

  # try to load run lib
  sp_f_load run

  if test "${_mode}" = "summary" ; then
    sp_f_run_summary "${_prg}" "${_guide}"
  else
    sp_f_run_check "${_prg}" "${_guide}"
  fi
}