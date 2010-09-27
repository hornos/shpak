

function sp_f_pbs() {
  local _p_qbat="${1}"

  echo "#${sp_g_qsub} -N ${NAME}"                    >> "${_p_qbat}"

  # mail
  if ! test -z "${QUEUE_MAIL}" && test "${QUEUE_MAIL}" != "runprg" ; then
    echo "#${sp_g_qsub} -m ${QUEUE_MAIL}"            >> "${_p_qbat}"
    if ! test -z "${QUEUE_MAIL_TO}" ; then
      echo "#${sp_g_qsub} -M ${QUEUE_MAIL_TO}"       >> "${_p_qbat}"
    fi
  fi

  # time
  if ! test -z "${TIME}" ; then
    echo "#${sp_g_qsub} -lwalltime=${TIME}"          >> "${_p_qbat}"
  fi

  # memory
  if ! test -z "${MEMORY}" ; then
    echo "#${sp_g_qsub} -lpmem=${MEMORY}${sp_g_qms}" >> "${_p_qbat}"
  fi

  # other constraints
  local _const=""
  local _con=""
  if ! test -z "${QUEUE_CONST}" ; then
    for _con in ${QUEUE_CONST} ; do
      _const="${_const}:${_con}"
    done
  fi

  local _tasks=""
  if ! test -z "${TASKS}" ; then
    _tasks=":ppn=${TASKS}"
  fi

  if ! test -z "${NODES}" ; then
    echo "#${sp_g_qsub} -lnodes=${NODES}${_tasks}${_const}" >> "${_p_qbat}"
  fi

  # project
  if ! test -z "${QUEUE_PROJECT}" ; then
    echo "#${sp_g_qsub} -A ${QUEUE_PROJECT}"                >> "${_p_qbat}"
  fi

  if test "${QUEUE_SHARE}" = "off" ; then
    echo "#${sp_g_qsub} -W x=NACCESSPOLICY:SINGLEUSER"      >> "${_p_qbat}"
  fi

  # queue
  if ! test -z "${QUEUE_QUEUE}" ; then
    echo "#${sp_g_qsub} -q ${QUEUE_QUEUE}"                  >> "${_p_qbat}"
  fi

  echo "#${sp_g_qsub} -o ${QUEUE_STDOUT:-StdOut}"           >> "${_p_qbat}"
  echo "#${sp_g_qsub} -e ${QUEUE_ERROUT:-ErrOut}"           >> "${_p_qbat}"

  if ! test -z "${QUEUE_OPTS}" ; then
    echo "#${sp_g_qsub} ${QUEUE_OPTS}"                      >> "${_p_qbat}"
  fi

  echo 'cd "${PBS_O_WORKDIR}"'                              >> "${_p_qbat}"
}

function sp_f_qmail_sub() {
  echo "Job ${PBS_JOB_ID} (${PBS_JOBNAME})"
}

function sp_f_qmail_msg() {
  local _m=""
  _m=$(date)
  if ! test -z "${PBS_NNODES}" ; then
    echo "${_m}\nRunning on ${PBS_NNODES} nodes"
  else
    echo "${_m}"
  fi
}
