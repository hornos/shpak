#f3--&7-9-V13------21-------------------42--------------------64------72

function sp_f_scrls() {
  ${sp_p_scr} -ls | awk \
  'BEGIN{ses="{";c=1;f=1}
  /^[[:space:]]+[0-9]+\./{
    split($0, arr, " ");
    gsub("\\(","",arr[2]);
    gsub("\\)","",arr[2]);
    if( f )
      ses = ses c ":" arr[1] "|" substr(arr[2],1,1)
    else
      ses = ses "," c ":" arr[1] "|" substr(arr[2],1,1)
    ++c;
    f=0;
  }
  END{ses=ses "}"; print ses;}
  '
}

function sp_f_scrid() {
  sp_f_spl "${1}" 1
}

function sp_f_scrst() {
  sp_f_spl "${1}" 2
}

# TODO: ?
function sp_f_scrpd() {
  local _r
  ${sp_b_scr} $*
  _r=$?
  if test ${_r} -eq 129 ; then
    logout
  fi
  return ${_r}
}

function sp_f_scr() {
  local _aa="$(sp_f_scrls)"
  local _c=0
  local _r=""
  local _msg="${1:-Choose}"
  local _flt=${2:-3}
  local _ans
  local _id
  local _st
  local _f=true

  ${sp_p_scr} -q -ls
  if test $? -lt 10 ; then
    sp_f_yesno "Open a new screen"
    if test $? -gt 0 ; then
      return 1
    fi
    sp_f_scrpd
    return $?
  fi

  while true; do
    _c=$((++_c))
    _r=$(sp_f_aa "${_aa}" ${_c})
    if test $? -gt 0 ; then
      break
    fi

    _id="$(sp_f_scrid ${_r})"
    _st="$(sp_f_scrst ${_r})"
    if ${_f} && test "${_st}" == "D" ; then
      _fid="${_id}"
      _f=false
      echo "${_c}: * ${_st} ${_id}"
    else
      echo "${_c}:   ${_st} ${_id}"
    fi
  done

  while true ; do
    echo -en "\n${_msg} (1-$((${_c}-1)) / n / q) [${_flt}]: "
    read _ans
    _ans=$(sp_f_lc ${_ans})
    case "${_ans}" in
      "q" )
        echo -e "Abort\n"
        return 1
      ;;
      "n" )
        sp_f_scrpd
        return $?
      ;;
      "case" )
        sp_f_scrpd -D -r "${_fid}"
        return $?
      ;;
      *)
        if test ${_ans} -lt ${_c} && test ${_ans} -gt 0 ; then
          _id=$(sp_f_scrid "$(sp_f_aa "${_aa}" ${_ans})")
          sp_f_scr_pd -D -r "${_id}"
          return $?
        fi
        echo -e "Invalid\n"
        _flt=$((_flt-1))
      ;;
    esac
    if test ${_flt} -lt 1 ; then
      return 1
    fi
  done
}
