#!/bin/bash
SRC_URL="http://tldp.org/HOWTO/Bash-Prompt-HOWTO/c583.html"
#   Script: escgen

_b=false
_ul=200
_ll=100
while getopts hu:l: o; do
  case "$o" in
    h) exit 1;;
    u) _ul=$OPTARG;;
    l) _ll=$OPTARG;;
  esac
done

let lower_val=${_ll}
let upper_val=${_ul}

if [ "${lower_val}" -gt "${upper_val}" ]
then
   # echo -e "\033[1;31m${lower_val} is larger than ${upper_val}.\033[0m"
   echo -e "${lower_val} is larger than ${upper_val}"
   echo
   exit 1
fi
if [ "${upper_val}" -gt "777" ]
   then
   echo -e "Values cannot exceed 777"
   echo
   exit 1
fi

echo
echo "Credit ${SRC_URL}"
echo
echo "1st Syntax: \0OCT"
echo "2nd Syntax: \033(0\0OCT\033(B"
echo
let i=$lower_val
let line_count=1
let limit=$upper_val
padding="000"
echo "OCT: 1st 2nd  OCT: 1st 2nd  OCT: 1st 2nd  OCT: 1st 2nd  OCT: 1st 2nd"
echo "--------------------------------------------------------------------"
while [ "$i" -lt "$limit" ] ; do
  octal_escape_1="\\0$i"
  octal_escape_2="\033(0${octal_escape_1}\033(B"
  pi=${padding:${#i}}$i
  echo -en "$pi: '$octal_escape_1' '$octal_escape_2'  "
  if [ "$line_count" -gt "4" ] ; then 
    echo
    let line_count=0
  fi
  let i=$(echo -e "obase=8 \n ibase=8 \n $i+1 \n quit" | bc)
  let line_count=$line_count+1
done
echo
