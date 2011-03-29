#f3--&7-9-V13------21-------------------42--------------------64------72
### GLOBALS

function sp_f_surf() {
  local _s="${1:-julian assange}"
  local _h=${2:-100}
  local _e=${3:-google}
  local _b=${4:-w3m}
  
  echo $_s
  SURFRAW_browser="${_b}" surfraw -t ${_e} -results=${_h} "${_s}"
}
