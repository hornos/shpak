#/// \file h.sh
#/// \brief shpak header
#///
#/// Defines the common header for interface scripts
#/// Usage: . $(dirname ${0})/../lib/h.sh

#f3--&7-9-V13------21-------------------42--------------------64------72
#/// \var sp_g_bn
#/// \brief basename of the script
sp_g_bn=$(basename "${0}")

#/// \var sp_p_k
#/// \brief location of the kernel
#///
#/// Environment variable SHPAK_KERNEL can override the default value
sp_p_k="${HOME}/shpak/lib/k.sh"

if test -z "${SHPAK_KERNEL}" ; then
  if test -r "${sp_p_k}" ; then
    SHPAK_KERNEL="${sp_p_k}"
  else
    echo "kernel error"
    exit 100
  fi
fi
. "${SHPAK_KERNEL}"
