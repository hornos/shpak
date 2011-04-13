
sp_f_load enc/base

function sp_f_gpg___() {
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

