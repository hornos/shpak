#f3--&7-9-V13------21-------------------42--------------------64------72

function sp_f_scrls() {
  screen -ls | awk \
  'BEGIN{ses="{";c=1;f=1}
  /^[[:space:]]+[0-9]+\./{
    split($0, arr, " ");
    if( f )
      ses = ses c ":" arr[1]
    else
      ses = ses "," c ":" arr[1]
    ++c;
    f=0;
  }
  END{ses=ses "}"; print ses;}
  '
}

function sp_f_scr() {
  local _aa="$(sp_f_scrls)"
  local _c=0
  local _r=""
  local _msg="${1:-Select screen}"
  local _flt=${2:-3}
  local _ans

  while true; do
    _c=$((++_c))
    _r=$(sp_f_aa "${_aa}" ${_c})
    if test $? -gt 0 ; then
      break
    fi
    echo "${_c}: ${_r}"
  done

  while true ; do
    echo -en "\n${_msg} (1-$((${_c}-1)) q) [${_flt}]: "
    read _ans
    _ans=$(sp_f_lc ${_ans})
    case "${_ans}" in
      "y" )
        return 0
      ;;
      "q" )
        return 1
      ;;
      "n" )
        return 0
        screen
      ;;
      *)
        if test ${_ans} -lt ${_c} && test ${_ans} -gt 0 ; then
          screen -D -r $(sp_f_aa "${_aa}" ${_ans})
          return 0
        fi
        sp_f_err "invalid answer"
        _flt=$((_flt-1))
      ;;
    esac
    if test ${_flt} -lt 1 ; then
      return 1
    fi
  done
}
