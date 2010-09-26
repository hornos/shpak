sp_p_home=$(dirname "${SHPAK_KICKSTART}")
sp_p_home=${sp_p_home%%/lib}

sp_p_user="${HOME}/shpak"

sp_p_lib="${sp_p_home}/lib"

# set defaults ------------------------------------------------------------------
sp_p_hosts="${sp_p_user}/hosts"
sp_p_queues="${sp_p_user}/queues"
sp_p_keys="${sp_p_user}/keys"
sp_p_lck="${sp_p_user}/lock"
sp_p_remote="${sp_p_user}/remote"

sp_s_lib=".sh"
sp_s_cfg=".cfg"
sp_s_lck=".lck"

# common functions --------------------------------------------------------------
sp_p_f="${sp_p_lib}/f.sh"
if ! test -r "${sp_p_f}" ; then
  echo "functions ${sp_p_f} not found"
  exit 10
fi
. "${sp_p_f}"

# create directories ------------------------------------------------------------
sp_f_mkdir "${sp_p_lck}"
sp_f_mkdir "${sp_p_keys}"
