#!/bin/bash
#
# Author: Michael Moedt (mmoedt@gmail.com)
# License: MIT
#

# Load helper functions and globals; note that the function 'run-do-script' still needs to be called
THIS_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")  # FIXME?: This might be specific to bash and Linux
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
    show_usage
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

do-build() {

    do-load-settings

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

do-load-settings() {
    # shellcheck source=./my-settings.sh
    if [ -e "${SETTINGS_FILE}" ]; then source "${SETTINGS_FILE}"; else echo "No settings file '${SETTINGS_FILE}' found"; return; fi
    #MY_DB_PROPS_FILE="${MY_DB_PROPS_FILE:-${DB_JAVA_USER}.db.properties}"
}

do-unpause() {
    for FILE in "do-run-paused.flag" "do-run-stop.flag"; do
        if [ -e "${FILE}" ]; then
            rm "${FILE}"
        fi
    done
}

do-pause() {
    FLAGFILE="do-run-paused.flag"
    touch "${FLAGFILE}"
    stop-server || return 1
}

do-restart() {
    BUILD_ARG="${1}"  # e.g. potential '-noclean'

    do-pause
    if [[ $? != 0 ]]; then
        echo "Failed to restart server - not proceeding with build or removing flag-file.."
    else
        echo "Rebuilding.."
        do-build "${BUILD_ARG}" && \
            { echo -e " Done build!\n Unpausing server... "; do-unpause; } || \
            { echo -e " ##! FAILURE TO BUILD - Not removing flag-file to enable service restart!\n  so, re-run the 'restart' subcommand after fixing, or remove '${FLAGFILE}' manually. "; }
    fi
}

##
## FIXME: Need to update for our python based service
##
stop-server() {
    echo "Looking for server process.."
    echo "[ERROR] Not implemented yet"
    return 1

    # This may not be 100% robust, but seems to work well enough
    SERVER_PID=$(ps x | grep -E '/[j]ava .*target/tomcat.*tomcat7:run' | head -n 1 | sed -E 's/[^0-9]*([0-9]+)[^0-9].*/\1/g')

    STOPPED=0
    if [[ "${SERVER_PID}" == "" ]]; then
        echo "ERROR: Failed to read server (tomcat7) PID - assuming it's not running"
        # not counting this as a success, for now.. shouldn't happen
    else
        COUNT=0
        MAX_TRIES=5
        while [[ $COUNT < $MAX_TRIES && $STOPPED == 0 ]]; do
            echo "Terminating server.. (try #${COUNT})"
            kill "${SERVER_PID}"
            COUNT=$(( $COUNT + 1 ))
            sleep 2.0  # crossing fingers
            # Quick check to see if it worked..
            NEW_SERVER_PID=$(ps x | grep -E '/[j]ava .*target/tomcat.*tomcat7:run' | head -n 1 | cut -d " " -f 1)
            if [[ "${NEW_SERVER_PID}" != "${SERVER_PID}" ]]; then
                echo " ..done; server stopped successfully!"
                STOPPED=1
            fi
        done
    fi

    if [[ $STOPPED != 1 ]]; then
        echo "Failed to stop server..."
        return 1
    fi
}

do-stop() {
    MAX_TRIES=5
    FLAGFILE="do-run-stop.flag"

    # Create the flagfile so that do-run will not autorestart..
    touch "${FLAGFILE}"

    stop-server || return 1
}

##
## FIXME: Need to update for our python based service
##
# function do-watch-logs() {
#     LOGFILE="target/tomcat/logs/server.log"

#     while true; do
#         echo "Attempting to watch '${LOGFILE}'.."
#         SERVER_PID=$(ps a | grep -E '/[j]ava .* tomcat7:run' | awk '{print $1}')
#         if [[ "${SERVER_PID}" -gt 0 ]]; then
#             echo "Using PID: ${SERVER_PID}"
#             sleep 1
#             tail --follow=name "${LOGFILE}" --pid=${SERVER_PID} --sleep-interval=1 # not using --retry, the outer loop will do that
#         else
#             tail --follow=name "${LOGFILE}"  # todo: look into using -f --pid= and -s
#         fi
#         # less --follow-name +F "${LOGFILE}"  # another option?
#         echo " about to retry.."
#         sleep 3
#     done
# }

do-run() {
    run-once
}

run-once() {
    # return $(do-run-loop)
    # npm run dev
    python src/main.py
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

# do-bundle() {
#     echo " ## NOT YET IMPLEMENTED "
#     return 1
# }

do-pre-push() {
    # sls offline start
    banner lint:fix &&
        true && # yarn lint:fix &&  ## FIXME
        banner format:fix &&
        true && # yarn format:fix &&  ## FIXME
        banner build test with install &&
        yarn install && # install dependencies
        yarn build && # build our service
        banner OK to build test &&
        # banner show migrations &&
        # orm migration:show &&
        # banner show schema diffs DISABLED &&
        # # orm schema:log &&
        banner test:unit &&
        do-tests && # yarn test:unit &&
        banner test:integration DISABLED &&
        # yarn test:integration &&
        # banner LAST: serverless run test &&
        # yarn run:local
    banner pre-push done
}

do-tests() {
    true &&
        banner test:unit &&
        yarn test:unit &&
        banner test:integration &&
        yarn test:integration
}

do-update-api-docs() {
    echo "Updating API documentation..."
    ## FIXME
}

# Run the script using all the above defined functions
run-do-script $@
