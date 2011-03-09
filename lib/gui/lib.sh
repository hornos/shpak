#f3--&7-9-V13------21-------------------42--------------------64------72
# GLOBALS
#/// \var sp_g_cdb
#/// \brief color code db
sp_g_cdb='{none:0,white:37,yellow:33,purple:35,red:31,cyan:36,green:32,blue:34,black:30}'

#/// \var sp_g_fst
#/// \brief font style db
sp_g_fst='{normal:0,bold:1,under:4,blink:5,inv:7,conc:8}'

#/// \var sp_g_esc
#/// \brief escape
sp_g_esc='\033'

#/// \var sp_g_edb
#/// \brief bloack character codes db
sp_g_edb='{diamond:140,dsblock:141,rbcorner:152,rtcorner:153,ltcorner:154,lbcorner:155,junction:156,hline:161,ljunction:164,rjunction:165,bjunction:166,tjunction:167,vline:170}'

#f3--&7-9-V13------21-------------------42--------------------64------72
# COLOR
#/// \fn sp_f_ctxt
#/// \brief print a color text
#///
#/// \param 1 CHARACTER(*) text to display
#/// \param 2 CHARACTER(*) forground color
#/// \param 3 CHARACTER(*) background color
#/// \param 4 CHARACTER(*) font style
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
#/// \param 1 CHARACTER(*) header text
#/// \param 2 CHARACTER(*) font type
function sp_f_htxt() {
  local _s="${1:-shpak}"
  local _f="${2:-utf8-slant}"
  ${sp_b_flt} -f "${_f}" "${_s}"
}

#f3--&7-9-V13------21-------------------42--------------------64------72
# DRAW

#/// \fn sp_f_dtxt
#/// \brief print draw characters
#///
#/// \param 1 CHARACTER(*) edb character key
#/// \param 2 INTEGER span
function sp_f_dtxt() {
  local _k="${1:-diamond}"
  local _s="${2:-3}"
  local _c=""
  _c=$(sp_f_aa "${sp_g_edb}" "${_k}")
  if test $? -gt 0 ; then
    return 1
  fi
  for((i=0;i<_s;++i)) ; do
    sp_f_btxt "${_c}"
  done
}
