#f3--&7-9-V13------21-------------------42--------------------64------72

function sp_f_tstr() {
  local _t=$1
  printf "%02d:%02d:%02d\n" $((_t/3600)) $((_t/60%60)) $((_t%60))
}