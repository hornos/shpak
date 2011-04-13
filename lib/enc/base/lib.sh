
function sp_f_bXX() {
  local _d=${1:-false}
  local _b=${2:-64}
  local _s="${3}"
  local _dir=$(dirname $BASH_SOURCE)
  local _awk="${_dir}/b${_b}.awk"
  if ! test -r "${_awk}" ; then
    return ${_FALSE_}
  fi
  if ! ${_d} ; then
    echo "${_s}" | awk -f "${_awk}"
  else
    echo "${_s}" | awk -f "${_awk}" d
  fi
}

function sp_f_b64enc() {
  sp_f_bXX false 64 "${1}"
}

function sp_f_b64dec() {
  sp_f_bXX true 64 "${1}"
}

function sp_f_b85enc() {
  sp_f_bXX false 85 "${1}"
}

function sp_f_b85dec() {
  sp_f_bXX true 85 "${1}"
}
