#f3--&7-9-V13------21-------------------42--------------------64------72

#/// \fn sp_f_slurm
#/// \brief SLURM submission
#///
#/// \param mode
#/// \param queue batch file
function sp_f_slurm() {
  local _mode="${1:-submit}"
  local _p_qbat="${2:-slurm.sh}"
  local _con=""
  local _const=""
  if test "${_mode}" = "login" ; then
    local _qlogin="${sp_b_qlogin}"
    # name
    _qlogin="${_qlogin} --job-name ${NAME}"
    # time
    if ! test -z "${TIME}" ; then
      _qlogin="${_qlogin} --time=${TIME}"
    fi
    # memory
    if ! test -z "${MEMORY}" ; then
      _qlogin="${_qlogin} --mem-per-cpu=${MEMORY}${sp_g_qms}"
    fi
    # nodes
    if ! test -z "${NODES}" ; then
      _qlogin="${_qlogin} --nodes=${NODES}"
    fi
    # tasks
    if ! test -z "${TASKS}" ; then
      _qlogin="${_qlogin} --ntasks-per-node=${TASKS}"
    fi
    # other constraints
    _const=""
    if ! test -z "${QUEUE_CONST}" ; then
      _qlogin="${_qlogin} --constraint="
      local _first=true
      for _con in ${QUEUE_CONST} ; do
        if ${_first} ; then
          _const="${_con}"
          _first=false
        else
          _const="${_const}\&${_con}"
        fi
      done
      _qlogin="${_qlogin}${_const}"
    fi
    # partition
    if ! test -z "${QUEUE_PART}" ; then
      _qlogin="${_qlogin} --partition=${QUEUE_PART}"
    fi
    # project
    if ! test -z "${QUEUE_PROJECT}" ; then
      _qlogin="${_qlogin} --account=${QUEUE_PROJECT}"
    fi
    echo "${_qlogin}" >> "${_p_qbat}"
    return 
  fi # end login

  # submit
  # name
  echo "#${sp_g_qsub} --job-name ${NAME}"                  >> "${_p_qbat}"

  # mail
  if ! test -z "${QUEUE_MAIL}" && test "${QUEUE_MAIL}" != "runprg" ; then
    echo "#${sp_g_qsub} --mail-type=${QUEUE_MAIL}"         >> "${_p_qbat}"
    if ! test -z "${QUEUE_MAIL_TO}" ; then
      echo "#${sp_g_qsub} --mail-user=${QUEUE_MAIL_TO}"    >> "${_p_qbat}"
    fi
  fi

  # time
  if ! test -z "${TIME}" ; then
    echo "#${sp_g_qsub} --time=${TIME}"                    >> "${_p_qbat}"
  fi

  # memory
  if ! test -z "${MEMORY}" ; then
    echo "#${sp_g_qsub} --mem-per-cpu=${MEMORY}${sp_g_qms}" >> "${_p_qbat}"
  fi

  if ! test -z "${NODES}" ; then
    echo "#${sp_g_qsub} --nodes=${NODES}"                  >> "${_p_qbat}"
  fi

  if ! test -z "${TASKS}" ; then
      echo "#${sp_g_qsub} --ntasks-per-node=${TASKS}"      >> "${_p_qbat}"  
  fi

  # other constraints
  if ! test -z "${QUEUE_CONST}" ; then
    for _con in ${QUEUE_CONST} ; do
      echo "#${sp_g_qsub} --constraint=${_con}"     >> "${_p_qbat}"
    done
  fi

  # partition
  if ! test -z "${QUEUE_PART}" ; then
    echo "#${sp_g_qsub} --partition=${QUEUE_PART}"  >> "${_p_qbat}"
  fi

  # project
  if ! test -z "${QUEUE_PROJECT}" ; then
    echo "#${sp_g_qsub} --account=${QUEUE_PROJECT}" >> "${_p_qbat}"
  fi

  # exclusive?
  if test "${QUEUE_SHARE}" = "off" ; then
    echo "#${sp_g_qsub} --exclusive"                >> "${_p_qbat}"
  fi

  echo "#${sp_g_qsub} -o ${QUEUE_STDOUT:-StdOut}"   >> "${_p_qbat}"
  echo "#${sp_g_qsub} -e ${QUEUE_ERROUT:-ErrOut}"   >> "${_p_qbat}"

  if ! test -z "${QUEUE_OPTS}" ; then
    echo "#${sp_g_qsub} ${QUEUE_OPTS}"              >> "${_p_qbat}"
  fi
}

function sp_f_qmail_sub() {
  echo "Job ${SLURM_JOB_ID} (${SLURM_JOB_NAME})"
}

function sp_f_qmail_msg() {
  local _m=""
  _m=$(date)
  if ! test -z "${SLURM_JOB_NUM_NODES}" ; then
    echo "${_m}\nRunning on ${SLURM_JOB_NUM_NODES} nodes"
  else
    echo "${_m}"
  fi
}
