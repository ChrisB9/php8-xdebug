export LS_COLORS="${LS_COLORS}di=1;34:"
export EXA_COLORS="da=1;34:gm=1;34"
alias ls='exa'
alias ll='ls -alh --git --header --group'
export PATH=$PATH:~/.composer/vendor/bin:./bin:./vendor/bin:./node_modules/.bin:/usr/local/cargo/bin
source ~/.git-completion.bash
source ~/.git-prompt.sh
source ~/.completions.bash

is_root() {
  return $(id -u)
}

has_sudo() {
  local prompt

  prompt=$(sudo -nv 2>&1)
  if [ $? -eq 0 ] || is_root; then
    return 1
  fi
  return 0
}

# for more information on this: https://github.com/pluswerk/php-dev/blob/master/.additional_bashrc.sh
CONTAINER_ID=$(basename $(cat /proc/1/cpuset))
export HOST_DISPLAY_NAME=$HOSTNAME

if has_sudo -eq 1 && [ sudo docker ps -q ] &>/dev/null; then
  DOCKER_COMPOSE_PROJECT=$(sudo docker inspect ${CONTAINER_ID} | grep '"com.docker.compose.project":' | awk '{print $2}' | tr -d '"' | tr -d ',')
  export NODE_CONTAINER=$(sudo docker ps -f "name=${DOCKER_COMPOSE_PROJECT}_node_1" --format {{.Names}})
  export HOST_DISPLAY_NAME=$(sudo docker inspect ${CONTAINER_ID} --format='{{.Name}}')
  export HOST_DISPLAY_NAME=${HOST_DISPLAY_NAME:1}

  alias node_exec='sudo docker exec -u $(id -u):$(id -g) -w $(pwd) -it ${NODE_CONTAINER}'
  alias node_root_exec='sudo docker exec -w $(pwd) -it ${NODE_CONTAINER}'

  alias node='node_exec node'
  alias npm='node_exec npm'
  alias npx='node_exec npx'
  alias yarn='node_exec yarn'
fi
export HOST_DISPLAY_NAME=$HOSTNAME

if [[ $CONTAINER_ID != ${HOSTNAME}* ]]; then
  export HOST_DISPLAY_NAME=$HOSTNAME
fi

PS1='\033]2;'$(pwd)'\007\[\e[0;36m\][\[\e[1;31m\]\u\[\e[0;36m\]@\[\e[1;34m\]$HOST_DISPLAY_NAME\[\e[0;36m\]: \[\e[0m\]\w\[\e[0;36m\]]\[\e[0m\]\$\[\e[1;32m\]\s\[\e[0;33m\]$(__git_ps1)\[\e[0;36m\]> \[\e[0m\]\n$ '

eval `ssh-agent -s`
if [ -z "$SSH_AUTH_SOCK" ]; then
  ssh-add -t 604800 ~/.ssh/id_rsa
else
  ssh-add
fi

export EDITOR=vim

## this extracts pretty much any archive
function extract() {
  if [ -f $1 ]; then
    case $1 in
    *.tar.bz2) tar xvjf $1 ;;
    *.tar.gz) tar xvzf $1 ;;
    *.bz2) bunzip2 $1 ;;
    *.rar) unrar x $1 ;;
    *.gz) gunzip $1 ;;
    *.tar) tar xvf $1 ;;
    *.tbz2) tar xvjf $1 ;;
    *.tgz) tar xvzf $1 ;;
    *.zip) unzip $1 ;;
    *.Z) uncompress $1 ;;
    *.7z) 7z x $1 ;;
    *) echo "'$1' cannot be extracted via >extract<" ;;
    esac
  else
    echo "'$1' is not a valid file!"
  fi
}

function xdebug-enable() {
  xdebug-mode "profile,develop,coverage"
}

function xdebug-debug() {
  xdebug-mode "debug,develop"
}

function xdebug-disable() {
  xdebug-mode "off"
}