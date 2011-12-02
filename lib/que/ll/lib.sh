
function sp_f_ll() {
  local _mode="${1:-submit}"
  local _p_qbat="${2:-ll.sh}"
  local _con=""
  local _const=""
  if test "${_mode}" = "login" ; then
    echo "Login is not supported"
    return ${_FALSE_}
  fi # end login

  # submit
  # name
  echo "#${sp_g_qsub} job_name = ${NAME}"                  >> "${_p_qbat}"

  # mail
  if ! test -z "${QUEUE_MAIL}" && test "${QUEUE_MAIL}" != "runprg" ; then
    echo "#${sp_g_qsub} notification = ${QUEUE_MAIL}"      >> "${_p_qbat}"
    if ! test -z "${QUEUE_MAIL_TO}" ; then
      echo "#${sp_g_qsub} notify_user = ${QUEUE_MAIL_TO}"  >> "${_p_qbat}"
    fi
  fi

  # time
  if ! test -z "${TIME}" ; then
    echo "#${sp_g_qsub} wall_clock_limit = ${TIME}"        >> "${_p_qbat}"
  fi

  # memory
  if ! test -z "${MEMORY}" ; then
    echo "#${sp_g_qsub} requirements=(Memory > ${MEMORY}${sp_g_qms})" >> "${_p_qbat}"
  fi

  if ! test -z "${NODES}" ; then
    echo "#${sp_g_qsub} node = ${NODES}"                   >> "${_p_qbat}"
  fi

  if ! test -z "${TASKS}" ; then
      echo "#${sp_g_qsub} tasks_per_node = ${TASKS}"       >> "${_p_qbat}"
  fi

  # other constraints
  if ! test -z "${QUEUE_CONST}" ; then
    for _con in ${QUEUE_CONST} ; do
      echo "#${sp_g_qsub} network.MPI = ${_con}"     >> "${_p_qbat}"
    done
  fi

  # partition
  # if ! test -z "${QUEUE_PART}" ; then
  #  echo "#${sp_g_qsub} bg_partition = ${QUEUE_PART}"  >> "${_p_qbat}"
  # fi

  # project
  if ! test -z "${QUEUE_PROJECT}" ; then
    echo "#${sp_g_qsub} account_no = ${QUEUE_PROJECT}" >> "${_p_qbat}"
  fi

  # qos
  if ! test -z "${QUEUE_QOS}" ; then
    echo "#${sp_g_qsub} job_type = ${QUEUE_QOS}"    >> "${_p_qbat}"
  fi

  # exclusive?
  # if test "${QUEUE_EXCLUSIVE}" = "yes" ; then
  #   echo "#${sp_g_qsub} --exclusive"                >> "${_p_qbat}"
  # fi

  echo "#${sp_g_qsub} input = ${QUEUE_STDOUT:-/dev/null}" >> "${_p_qbat}"
  echo "#${sp_g_qsub} output = ${QUEUE_STDOUT:-StdOut}"   >> "${_p_qbat}"
  echo "#${sp_g_qsub} error = ${QUEUE_ERROUT:-ErrOut}"    >> "${_p_qbat}"

  # if ! test -z "${QUEUE_OPTS}" ; then
  #   echo "#${sp_g_qsub} ${QUEUE_OPTS}"              >> "${_p_qbat}"
  # fi

  echo "#${sp_g_qsub} queue"                              >> "${_p_qbat}"
}

function sp_f_qmail_sub() {
  echo "Job ${LOADL_JOB_NAME}"
}

function sp_f_qmail_msg() {
  local _m=""
  _m=$(date)
  if ! test -z "${LOADL_TOTAL_TASKS}" ; then
    echo "${_m}\nRunning on ${LOADL_TOTAL_TASKS} tasks"
  else
    echo "${_m}"
  fi
}
