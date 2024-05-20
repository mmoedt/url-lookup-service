#!/bin/bash
#
# Author: Michael Moedt (mmoedt@gmail.com)
# License: MIT
#

# Load helper functions and globals; note that the function 'run-do-script' still needs to be called
THIS_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
source "${THIS_DIR}/.do.sh"

# Note: Bash / Unix environment settings should be defined in the ENV_FILE,
#  and should be available to subcommands (e.g. java, maven, ..) since they're exported
# versus settings in the SETTINGS_FILE, which are used by this script and not directly by subcommands

# Environment setup:  (Needed for most functions)  but quietly
ENV_FILE="${ENV_FILE:-my-env.sh}"
if [ -e "${ENV_FILE}" ]; then
    debug 1 "Loading environment settings from '${ENV_FILE}'.."
    # shellcheck source=./my-env.sh
    QUIET=1  # enh: quiet++
    source "${ENV_FILE}" > /dev/null
    QUIET=0
fi

# shellcheck source=./my-settings.sh
SETTINGS_FILE="${SETTINGS_FILE:-my-settings.sh}"

#
# Helper functions
#

banner() {
    if [ -x $(which figlet) ]; then
        figlet "$@"
    else
        echo "####################"
        echo "$@"
        echo "####################"
    fi
}


#
# Commands (functions starting with 'do-')
#

do-help() {
    usage
    # Append a little extra info:
    cat <<EOF

Environment variables used:
   ENV_FILE: [default: my-env.sh]
       - bash script sourced (if it exists) to load your particular environment variables & overrides
EOF
}

env-tests() {

    # Example tests:

    # if [[ "$(which npm)" == "" ]]; then
    #     echo "ERROR: 'npm' not found in path!"
    # elif ((USING_YARN)) && [[ "$(which yarn)" == "" ]]; then
    #     echo "ERROR: Using yarn, but 'yarn' not found in path!"
    # elif [[ "${NEEDED_VARIABLE}" == "" ]]; then
    #     echo "ERROR: 'NEEDED_VARIABLE' is not set!"
    # else
    #     return 0
    # fi

    # return 1  ## Error
    return 0
}

load-settings() {
    # shellcheck source=./my-settings.sh
    if [ -e "${SETTINGS_FILE}" ]; then
        source "${SETTINGS_FILE}"
    else
        # echo "No settings file '${SETTINGS_FILE}' found"  # quietly exit for now
        return
    fi
    # MY_DB_PROPS_FILE="${MY_DB_PROPS_FILE:-${DB_JAVA_USER}.db.properties}"
}

do-build() {

    load-settings

    if [[ ${1} =~ [-]{0,2}noclean ]]; then  # okay for now if 'noclean', '-noclean', '--noclean'
        local NOCLEAN="1"
        echo "okay; going to attempt to avoid unnecessary cleaning"
    else
        local NOCLEAN="0"
    fi

    BUILD_START=$(date +%H:%M:%S)
    BUILD_START_SEC=$(date +%s)

    env-tests || return

    # Sample:
    if [[ "${NOCLEAN}" == "0" ]]; then
        echo ' # Cleaning... '
        # if ((USING_YARN))
        # then yarn run clean
        # else npm  run clean
        # fi
        echo ' (nothing to do)  Done!'
    fi

    # echo ' # Installing/updating node.js dependencies... ' &&
    #     if ((USING_YARN))
    #     then yarn run clean
    #     else npm  run clean
    #     fi &&
    #     npm install &&

    #     echo ' # Compiling... ' &&
    #     if ((USING_YARN))
    #     then yarn run build
    #     else npm run build
    #     fi &&

    #     ## Copying over test data//
    #     ##echo ' # Copying over db config for tests... ' &&
    #     ##cp -vb -t target/.../. "${MY_DB_PROPS_FILE}" &&

    #     echo ' # Done!' &&
    #     RET=0 ||
    #     RET=1

    BUILD_END=$(date +%H:%M:%S)
    BUILD_END_SEC=$(date +%s)
    echo "Build start @: ${BUILD_START}"
    echo "Build done  @: ${BUILD_END}"
    echo "   time taken: $(( BUILD_END_SEC - BUILD_START_SEC ))s"

    return ${RET}
}

do-run() {
    run-once
}

run-once() {
    uvicorn main:app --reload
}

run-loop() {
    FLAGFILE_PAUSE="do-run-paused.flag"
    FLAGFILE_STOP="do-run-stop.flag"
    RESTART_DELAY="2.0"  # delay between restarts, to allow ctrl-c, and limit effects of a broken start loop

    env-tests || return

    echo ' # Running loop ... (hit CTRL-C twice-in-a-row to stop)'

    FIRST=1
    while true
    do
        # Let's check the flagfiles first
        if [ -e "${FLAGFILE_STOP}" ]; then
            echo -e "\n\n\033[31mService exited\033[00m; Exiting run script due to STOP flagfile .. @$(date +%Y-%m-%d.%H:%M:%S)\n\n"
            rm "${FLAGFILE_STOP}"
            break
        elif [ -e "${FLAGFILE_PAUSE}" ]; then
            echo -e "\n\n\033[31mService exited\033[00m; Pausing service restart due to PAUSE flagfile .. @$(date +%Y-%m-%d.%H:%M:%S)\n\n"
            while [ -e "${FLAGFILE_PAUSE}" ]; do
                sleep 0.5
            done
        else
            if [ $FIRST == 1 ]; then
                FIRST=0
            else
                echo ".. Auto-restarting service, after ${RESTART_DELAY} second delay; Hit CTRL-C to stop.."
                sleep ${RESTART_DELAY}  # Reduce bad looping effects of a failing service start...
            fi

            echo "Starting server.."

            run-once

            echo -e "\n\n\033[31mserver exited\033[00m; @$(date +%Y-%m-%d.%H:%M:%S)\n"
        fi
    done
}

do-tests() {
    true &&
        #banner test:unit &&
        #python tests.py

    echo "Quick CURL test:"

TEST_URLS="
https%3A%2F%2Fwww.youtube.com%2Fwatch%3Fv%3DdQw4w9WgXcQ
https%3A%2F%2Fwww.youtube.com%2Fshorts%2FDJHRSER6Mz4
"
    for ENCODED_URL in ${TEST_URLS}; do
        echo -n "Testing: '${ENCODED_URL}'.. "
        curl -X 'GET' \
            "http://localhost:8000/v1/urlinfo/${ENCODED_URL}" \
            -H 'accept: application/json'
        echo ""
    done
}

do-update-api-docs() {
    ./do run &
    _PID=$!
    echo "Updating API documentation..."
    wget -O docs/openapi.json "http://localhost:8000/openapi.json"
    type jq && cat docs/openapi.json | jq > docs/openapi.nice.json
    kill ${_PID}
}

# Run the script using all the above defined functions
run-do-script $@
