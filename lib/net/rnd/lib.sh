#f3--&7-9-V13------21-------------------42--------------------64------72

sp_g_rnd_url="http://www.random.org"
sp_g_rnd_opts="&format=plain&rnd=new"
sp_g_rnd_msl=21

function sp_f_rint() {
  local _num=${1:-1}
  local _min=${2:-1}
  local _max=${3:-10}
  local _col=${4:-1}
  local _bas=${5:-10}
  local _x=${6:-7}
  local _url="${sp_g_rnd_url}/integers"
  _url="${_url}/?num=${_num}&min=${_min}&max=${_max}&col=${_col}&base=${_bas}${sp_g_rnd_opts}"
  wget -T ${_x} -qO- "${_url}"
}

function sp_f_rseq() {
  local _min=${1:-1}
  local _max=${2:-10}
  local _col=${3:-1}
  local _x=${4:-7}
  local _url="${sp_g_rnd_url}/sequences"
  _url="${_url}/?min=${_min}&max=${_max}&col=${_col}${sp_g_rnd_opts}"
  wget -T ${_x} -qO- "${_url}"
}

function sp_f__rstr() {
  local _len=${1:-13}
  local _num=${2:-1}
  local _dig=${3:-on}
  local _ual=${4:-on}
  local _lal=${5:-on}
  local _uni=${6:-on}
  local _x=${7:-7}
  local _url="${sp_g_rnd_url}/strings"
  if test ${_len} -lt 21 ; then
    _url="${_url}/?num=${_num}&len=${_len}&digits=${_dig}&upperalpha=${_ual}&loweralpha=${_lal}&unique=${_uni}${sp_g_rnd_opts}"
    wget -T ${_x} -qO- "${_url}"
    return $?
  fi
}

function sp_f_rstr() {
  local _len=${1:-13}
  local _num=${2:-1}
  local _dig=${3:-on}
  local _ual=${4:-on}
  local _lal=${5:-on}
  local _uni=${6:-on}
  local _x=${7:-7}

  if test ${_len} -lt ${sp_g_rnd_msl} ; then
    sp_f__rstr ${_len} ${_num} ${_dig} ${_ual} ${_lal} ${_uni} ${_x}
    return $?
  fi
  # string from a multi-query
  local _il=$((${_len}/${sp_g_rnd_msl}))
  local _ir=$((${_il}+1))
  local _rl=$((${_len}%${sp_g_rnd_msl}))
  local _rq=$(sp_f_rquo)
  if test ${_rq} -lt ${_ir} ; then
    sp_f_err "Not enough quota"
    return ${_FALSE_}
  fi
  echo "Required random.org queries: ${_ir}"
  echo "Curent quota: ${_rq}"
  sp_f_yesno "Continue?"
  if test $? -gt 0 ; then
    return ${_FALSE_}
  fi
  local _rstr=""
  # full
  for((c=0;c<_il;++c)) ; do
    _rstr="${_rstr}$(sp_f__rstr 20 ${_num} ${_dig} ${_ual} ${_lal} ${_uni} ${_x} 2> /dev/null)"
  done
  # residue
  _rstr="${_rstr}$(sp_f__rstr ${_rl} ${_num} ${_dig} ${_ual} ${_lal} ${_uni} ${_x} 2> /dev/null)"
  echo -e "${_rstr}"
}

function sp_f_rquo() {
  local _ip="${1}"
  local _x=${2:-3}
  if test -n "${_ip}" ; then
    _ip="ip=${_ip}&"
  fi
  local _url="${sp_g_rnd_url}/quota"
  _url="${_url}/?${_ip}format=plain"
  wget -T ${_x} -qO- "${_url}"
}
