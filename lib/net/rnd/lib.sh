#f3--&7-9-V13------21-------------------42--------------------64------72

sp_g_rndu="http://www.random.org"
sp_g_rnd_opts="&format=plain&rnd=new"

function sp_f_rint() {
  local _num=${1:-1}
  local _min=${2:-1}
  local _max=${3:-10}
  local _col=${4:-1}
  local _bas=${5:-10}
  local _x=${6:-7}
  local _url="${sp_g_rndu}/integers"
  _url="${_url}/?num=${_num}&min=${_min}&max=${_max}&col=${_col}&base=${_bas}${sp_g_rnd_opts}"
  wget -T ${_x} -qO- "${_url}"
}

function sp_f_rseq() {
  local _min=${1:-1}
  local _max=${2:-10}
  local _col=${3:-1}
  local _x=${4:-7}
  local _url="${sp_g_rndu}/sequences"
  _url="${_url}/?min=${_min}&max=${_max}&col=${_col}${sp_g_rnd_opts}"
  wget -T ${_x} -qO- "${_url}"
}

function sp_f_rstr() {
  local _len=${1:-13}
  local _num=${2:-1}
  local _dig=${3:-on}
  local _ual=${4:-on}
  local _lal=${5:-on}
  local _uni=${6:-on}
  local _x=${7:-7}
  local _url="${sp_g_rndu}/strings"
  _url="${_url}/?num=${_num}&len=${_len}&digits=${_dig}&upperalpha=${_ual}&loweralpha=${_lal}&unique=${_uni}${sp_g_rnd_opts}"
  wget -T ${_x} -qO- "${_url}"
}

function sp_f_rquo() {
  local _ip="${1}"
  local _x=${2:-3}
  if test -n "${_ip}" ; then
    _ip="ip=${_ip}&"
  fi
  local _url="${sp_g_rndu}/quota"
  _url="${_url}/?${_ip}format=plain"
  wget -T ${_x} -qO- "${_url}"
}
