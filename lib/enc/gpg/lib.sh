
function sp_f_gpg___() {
  sp_f_load enc/base

  local _s="${1}"
  local _d=${2:-false}

  if ${_d} ; then
    sp_f_b64dec "$(sp_f_b64dec "${_s}" | ${sp_b_gpg} -d 2>/dev/null)"
  else
    sp_f_b64enc "$(sp_f_b64enc "${_s}" | ${sp_b_gpg} -a --symmetric 2>/dev/null)"
  fi
}

function sp_f_gpgenc() {
  sp_f_gpg___ "${1}" false
}

function sp_f_gpgdec() {
  sp_f_gpg___ "${1}" true
}

function sp_f_gpgfp() {
  local _u="${1}"
  ${sp_b_gpg} --fingerprint "${_u}"
}

function sp_f_gpgfpe() {
  local _u="${1}"
  local _e=$(sp_f_gpgfp "${_u}" | awk '/uid/{print}')
  _e=${_e%%>*}
  _e=${_e##*<}
  echo "${_e}"
}

function sp_f_gpghnc() {
  local _s="${1}"
  local _e="${2}"
  local _h=${3:-false}
  local _r=""
  if ! test -r "${_s}" || test -z "${_e}" ; then
    return 1
  fi
  if ${_h} ; then
    _r="hidden-"
  fi
  ${sp_b_gpg} -o - --armor --encrypt --${_r}recipient "${_e}" "${_s}"
}
