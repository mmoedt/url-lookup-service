#!/bin/bash
#
# Author: Michael Moedt (mmoedt@gmail.com)
# License: MIT
#

# Note: This file is intended to be sourced; define a function for each desired subcommand and then source this

debug() {
    #if [ "${VERBOSE_LVL}" = "0" ]; then return; fi   ## FIXME: Does not work...
    #echo $*
    return
}

usage() {
    cat <<EOF

Usage:
  ./do [options] <function> [arguments]

  Where function is one of: $(for FUNC in ${FUNCS}; do echo -en "\n    - ${FUNC}"; done)

  Options:
    -v : be more verbose
    --help : display info about command, options and arguments

EOF
}

run-do-script() {

FUNCS=""
for FUNC in $(declare -F | sed -E 's|^declare -f ||')
do  if [[ "${FUNC}" =~ ^_.*$ ]]
    then debug "Ignoring internal '${FUNC}'…"
    elif [[ "${FUNC}" =~ ^do-.*$ ]]
    then _FUNC="${FUNC#do-}"
         debug "Found function ${FUNC}…"
         FUNCS="${FUNCS} ${FUNC#do-}"
    else : # debug "Ignoring '${FUNC}'…"
    fi
done

VERBOSE_LVL=0
COMMAND=""
ARGS=""
PROCEED=1
while [ $# -gt 0 ]
do case "$1" in
       -v)
           VERBOSE_LVL=$((VERBOSE_LVL + 1))
           ;;
       --help)
           SHOW_HELP=1
           ;;
       --*)
           echo "Unrecognized option '${1}'"
           PROCEED=0
           ;;
       *)
           if [ "${COMMAND}" = "" ]
           then COMMAND="${1}"
           else ARGS="${ARGS} ${1}"
           fi
           ;;
   esac
   shift
done

if [ "${COMMAND}" = "" ]
then usage
elif [ "${PROCEED}" = "0" ]
then echo "Not proceeding due to previous error.."
else {
    FOUND=0
    for FUNC in ${FUNCS}
    do {
        if [ "${FUNC}" = "${COMMAND}" ]
        then eval "do-${COMMAND} ${ARGS}"
             FOUND=1
        fi
    }
    done
    if [ "${FOUND}" = "0" ]
    then echo "Error: function '${COMMAND}' not found.  Use the 'help' function for more details."
    fi
}
fi

}
