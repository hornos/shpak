# +-----------------------------------------------------------------------------+
# | shPAK: common script header                                                 |
# +-----------------------------------------------------------------------------+

sp_g_bn=$(basename "${0}")
sp_p_k="${HOME}/shpak/lib/k.sh"

if test -z "${SHPAK_KICKSTART}" ; then
  if test -r "${sp_p_k}" ; then
    SHPAK_KICKSTART="${sp_p_k}"
  else
    echo "kickstart error"
    exit 100
  fi
fi
# read kickstart
. "${SHPAK_KICKSTART}"
