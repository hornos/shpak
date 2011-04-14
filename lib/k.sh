#/// \file k.sh
#/// \brief shpak kernel
#///
#/// Defines the common paths and functions
#///
#/// In the spirit of http://msdn.microsoft.com/en-us/library/Aa260976
#/// Global namespace for shpak: sp
#/// Namespace separator: _
#///
#/// Binary (path+options) subnamespace: b
#/// Function subnamespace: f
#/// Global variable subnamespace: g
#/// Path subnamespace: p
#/// Suffix subnamespace: s

#f3--&7-9-V13------21-------------------42--------------------64------72
### GLOBALS
#/// \var sp_p_home
#/// \brief shpak global home directory
sp_p_home=$(dirname "${SHPAK_KERNEL}")
sp_p_home=${sp_p_home%%/lib}

#/// \var sp_p_user
#/// \brief shpak user home directory
sp_p_user="${HOME}/shpak"

#/// \var sp_p_lib
#/// \brief shpak library directory
#///
#/// This directory contains libraries that can be loaded by sp_f_load
sp_p_lib="${sp_p_home}/lib"

#/// \var sp_p_hosts
#/// \brief shpak hosts directory
#///
#/// This directory contains host descriptors (see template therein)
sp_p_hosts="${sp_p_user}/hosts"

#/// \var sp_p_queues
#/// \brief shpak queues directory
#///
#/// This directory contains queue descriptors (see examples therein)
#/// You need this for batch processing
sp_p_queues="${sp_p_user}/ques"

#/// \var sp_p_keys
#/// \brief shpak keys directory
#///
#/// This directory contains keys for ssh and encfs
#/// In case of ssh the key file (.key) is a symlink of the private key
#/// In case of encfs the key file (.encfs5) is used to encrypt the stream
sp_p_keys="${sp_p_user}/keys"

sp_p_icos="${sp_p_user}/icos"

#/// \var sp_p_lock
#/// \brief shpak lock directory
#///
#/// This directory contains locks for various operations
sp_p_lck="${sp_p_user}/lck"

#/// \var sp_p_sshfs
#/// \brief shpak remote directory
#///
#/// This directory contains mounts of remote machines
sp_p_sshfs="${HOME}/sshfs"

#/// \var sp_p_encfs
#/// \brief shpak encfs directory
#///
#/// This directory contains mounts of encfs directories
sp_p_encfs="${HOME}/encfs"

#/// \var sp_p_dbs
#/// \brief shpak database directory
#///
#/// This directory contains sqlite databases
sp_p_db="${sp_p_user}/db"

#f3--&7-9-V13------21-------------------42--------------------64------72
### SUFFIXES

#/// \var sp_s_lib
#/// \brief library suffix
sp_s_lib=".sh"

#/// \var sp_s_cfg
#/// \brief library config suffix
sp_s_cfg=".cfg"

#/// \var sp_s_lck
#/// \brief lock file suffix
sp_s_lck=".lck"


#f3--&7-9-V13------21-------------------42--------------------64------72
### MISC

#/// \var sp_g_awkprn
#/// \brief supress login messages of sshcmd
sp_g_awkprn='BEGIN{p=1} /^(-){70}/{if(!p) p=1; else p=0} {if(p) print}'

#/// \var sp_g_debug
#/// \brief show debug messages TODO: dip ifc
sp_g_debug=false

#/// \var sp_g_nruler
#/// \brief normal ruler
sp_g_nruler="----------------------------------------------------------------------72"

#/// \var sp_g_bruler
#/// \brief bold ruler
sp_g_bruler="========================================================================"


#f3--&7-9-V13------21-------------------42--------------------64------72
# start kernel
sp_p_f="${sp_p_lib}/f.sh"
if ! test -r "${sp_p_f}" ; then
  echo "functions not found: ${sp_p_f}"
  exit 200
fi
. "${sp_p_f}"
