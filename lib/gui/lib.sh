#f3--&7-9-V13------21-------------------42--------------------64------72
# GLOBALS
sp_g_cdb='{none:0,white:37,yellow:33,purple:35,red:31,cyan:36,green:32,blue:34,black:30'
sp_g_fst='{normal:0,bold:1,under:4,blink:5,inv:7,conc:8}'
sp_g_esc='\033'


#f3--&7-9-V13------21-------------------42--------------------64------72
# COLOR
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
    _head="${sp_g_esc}[${_fst};${_cfg}m"
    _tail="${sp_g_esc}[0m"
  fi
  # bg
  if test "${_bg}" != "none" ; then
    _cbg=$((_cbg+10))
    _head="${_head}${sp_g_esc}[${_cbg}m"
    if test "${_tail}" == "" ; then
    _tail="${sp_g_esc}[0m"
    fi
  fi
  echo -e "${_head}${_txt}${_tail}"
}

#f3--&7-9-V13------21-------------------42--------------------64------72
# TEXT
#/// \fn sp_f_htxt
#/// \brief print a header with figlet
#///
#/// \param _s CHARACTER(*) header text
#/// \param _f CHARACTER(*) font type
function sp_f_htxt() {
  local _s="${1:-shpak}"
  local _f="${2:-slant}"
  figlet -f "${_f}" "${_s}"
}

#f3--&7-9-V13------21-------------------42--------------------64------72
# DRAW

