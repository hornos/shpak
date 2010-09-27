

function sp_f_slurm() {
  local _p_qbat="${1}"

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
    for con in ${QUEUE_CONST} ; do
      echo "#${sp_g_qsub} --constraint=${con}"      >> "${_p_qbat}"
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
