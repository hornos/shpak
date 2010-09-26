
function sp_f_sge() {
  local _p_qbat="${1}"

  echo "#${sp_g_qsub} -N ${NAME}"                     >> "${_p_qbat}"
  echo "#${sp_g_qsub} -S ${QUEUE_SHELL:-${sp_p_qsh}}" >> "${_p_qbat}"

  # mail
  if ! test -z "${QUEUE_MAIL}" && test "${QUEUE_MAIL}" != "runprg" ; then
    echo "#${sp_g_qsub} -m ${QUEUE_MAIL}"             >> "${_p_qbat}"
    if ! test -z "${QUEUE_MAIL_TO}" ; then
      echo "#${sp_g_qsub} -M ${QUEUE_MAIL_TO}"        >> "${_p_qbat}"
    fi
  fi

  # time
  if ! test -z "${TIME}" ; then
    echo "#${sp_g_qsub} -l h_cpu=${TIME}"             >> "${_p_qbat}"
  fi

  # memory
  if ! test -z "${MEMORY}" ; then
    local _mem=${MEMORY}
    local _tot=$((SLOTS*_mem))
    echo "#${sp_g_qsub} -l h_vmem=${_tot}${sp_g_qms}" >> "${_p_qbat}"
  fi

  # arch
  if ! test -z "${QUEUE_ARCH}" ; then
    echo "#${sp_g_qsub} -l arch=${QUEUE_ARCH}"        >> "${_p_qbat}"
  fi

  # other constraints
  if ! test -z "${QUEUE_CONST}" ; then
    echo "#${sp_g_qsub} -l ${QUEUE_CONST}"            >> "${_p_qbat}"
  fi

  # pe
  if ! test -z "${QUEUE_PE}" ; then
    echo "#${sp_g_qsub} -pe ${QUEUE_PE} ${SLOTS}"     >> "${_p_qbat}"
  fi

  # project
  if ! test -z "${QUEUE_PROJECT}" ; then
    echo "#${sp_g_qsub} -A ${QUEUE_PROJECT}"          >> "${_p_qbat}"
  fi

  # queue
  if ! test -z "${QUEUE_QUEUE}" ; then
    echo "#${sp_g_qsub} -q ${QUEUE_QUEUE}"            >> "${_p_qbat}"
  fi

  echo "#${sp_g_qsub} -o ${QUEUE_STDOUT:-StdOut}"     >> "${_p_qbat}"
  echo "#${sp_g_qsub} -e ${QUEUE_ERROUT:-ErrOut}"     >> "${_p_qbat}"

  if ! test -z "${QUEUE_OPTS}" ; then
    echo "#${sp_g_qsub} ${QUEUE_OPTS}"                >> "${_p_qbat}"
  fi

}


function sp_f_queue_mail_sub() {
  echo "Job ${JOB_ID} (${JOB_NAME})"
}

function sp_f_queue_mail_msg() {
  local _m=""
  _msg=$(date)
  if ! test -z "${NSLOTS}" ; then
    echo "${_m}\nRunning on ${NSLOTS} nodes"
  else
    echo "${_m}"
  fi
}
