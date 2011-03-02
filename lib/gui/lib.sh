
sp_g_cdb='{none:0,white:37,yellow:33,purple:35,red:31,cyan:36,green:32,blue:34,black:30'
sp_g_fst='{normal:0,bold:1,under:4,blink:5,inv:7,conc:8}'
sp_g_ces='\033['

function sp_f_ctxt() {
  local _txt=${1:-color}
  local _fg=${2:-none}
  local _bg=${3:-none}
  local _st=${4:-normal}
  local _cfg=0
  local _cbg=0
  local _head=""
  local _tail=""

  _cfg=$(sp_f_aa "${sp_g_cdb}" "${_fg}")
  _cbg=$(sp_f_aa "${sp_g_cdb}" "${_bg}")
  _fst=$(sp_f_aa "${sp_g_fst}" "${_st}")

  # fg
  if test "${_fg}" != "none" ; then
    _head="${sp_g_ces}${_fst};${_cfg}m"
    _tail="${sp_g_ces}0m"
  fi
  # bg
  if test "${_bg}" != "none" ; then
    _cbg=$((_cbg+10))
    _head="${_head}${sp_g_ces}${_cbg}m"
    if test "${_tail}" == "" ; then
    _tail="${sp_g_ces}0m"
    fi
  fi
  echo -e "${_head}${_txt}${_tail}"
}
