
sp_f_load enc/base

function sp_f_gpg___() {
  local _s="${1}"
  local _d=${2:-false}
  local _es=""

  if ${_d} ; then
    _es=$(sp_f_b64dec "${_s}" | ${sp_b_gpg} -d 2>/dev/null)
    sp_f_b64dec "${_es}"
  else
    _es=$(sp_f_b64enc "${_s}" | ${sp_b_gpg} --symmetric 2>/dev/null)
    sp_f_b64enc "${_es}"
  fi
}

function sp_f_gpgenc() {
  sp_f_gpg___ "${1}" false
}

function sp_f_gpgdec() {
  sp_f_gpg___ "${1}" true
}

