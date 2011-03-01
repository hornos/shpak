#!/bin/bash
SRC_URL="http://tldp.org/HOWTO/Bash-Prompt-HOWTO/c583.html"
#   Script: escgen

_b=false
_ul=200
_ll=100
while getopts hbu:l: o; do
  case "$o" in
    b) _b=true;;
    h) exit1;;
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
echo "Syntax: \0OCT"
echo
let i=$lower_val
let line_count=1
let limit=$upper_val
padding="000"
while [ "$i" -lt "$limit" ]
do
   octal_escape="\\0$i"
   if ${_b} ; then
     octal_escape="\033(0${octal_escape}\033(B"
   fi
   pi=${padding:${#i}}$i
   echo -en "$pi: '$octal_escape' "
   if [ "$line_count" -gt "7" ]
   then 
      echo
      let line_count=0
   fi
   let i=$(echo -e "obase=8 \n ibase=8 \n $i+1 \n quit" | bc)
   let line_count=$line_count+1
done
echo
