#!/bin/bash

THIS_DIR=$(cd $(dirname "${BASH_SOURCE[0]}"); pwd)
MY_SSH_KEY_FILE="${THIS_DIR}/my-dev-gitlab.id_rsa"

# 1. Set this env variable needed by our Node.js projects:
# export NPM_TOKEN="..."

# 2. Tweak the system 'max_user_watches' to avoid errors
MIN_MUW_SETTING="${MIN_MUW_SETTING:-150100}"
FSKEY="fs.inotify.max_user_watches"

if [ "$(sysctl -n ${FSKEY})" -lt "${MIN_MUW_SETTING}" ]
then
    echo "Adjusting '${FSKEY}' to avoid errors, using sudo..."
    sudo sysctl -w ${FSKEY}=${MIN_MUW_SETTING}
fi

# # 3. Load SSH keys into our ssh-agent, starting it if needed
# if [ -e "${SSH_AUTH_SOCK}" ] && [ -n "$(ps -p ${SSH_AGENT_PID} -o pid=)" ]
# then : # ssh agent set up already
# else eval $(ssh-agent -s)
# fi
# ssh-add "${MY_SSH_KEY_FILE}"

# 4. Set up NVM to run right here
export XDG_CONFIG_HOME="${THIS_DIR}"

export NVM_DIR="${THIS_DIR}/.nvm"
[ -s "${NVM_DIR}/nvm.sh" ] && source "${NVM_DIR}/nvm.sh"  # This loads nvm
[ -s "${NVM_DIR}/bash_completion" ] && source "${NVM_DIR}/bash_completion"  # This loads nvm bash_completion

if [ -e '.nvmrc' ] && [[ $(type -t nvm) == "function" ]]; then
    nvm use
else
    if [ -e "${THIS_DIR}/.nvm/versions/node" ]; then
        # Note: nvm use will re-set up these env vars
        _NVM_DIR=$(ls -trd "${THIS_DIR}/.nvm/versions/node"/v?.*.* | sort | tail -n 1)
        export NVM_INC="${_NVM_DIR}/include/node"
        export NVM_BIN="${_NVM_DIR}/bin"
    fi
fi
# </NVM-RELATED>

# 5. Set up our Python VirtualEnv environment
source .venv/bin/activate

# PATH="${THIS_DIR}/node_modules/.bin:${PATH}"  # for npm-installed tools
