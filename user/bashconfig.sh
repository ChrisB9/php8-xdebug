alias ll='ls -alh'
export PATH=$PATH:~/.composer/vendor/bin:./bin:./vendor/bin:./node_modules/.bin
source ~/.git-completion.bash
source ~/.git-prompt.sh

# for more information on this: https://github.com/pluswerk/php-dev/blob/master/.additional_bashrc.sh
CONTAINER_ID=$(basename $(cat /proc/1/cpuset))
export HOST_DISPLAY_NAME=$HOSTNAME
if [ -e /var/run/docker.sock ]; then
   SUDO=''
   if (( $EUID != 0 )); then
      SUDO='sudo'
   fi
   $SUDO apk add docker
fi
if sudo docker ps -q &>/dev/null; then
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
fi;
export HOST_DISPLAY_NAME=$HOSTNAME

if [[ $CONTAINER_ID != ${HOSTNAME}* ]] ; then
  export HOST_DISPLAY_NAME=$HOSTNAME
fi

PS1='\033]2;'$(pwd)'\007\[\e[0;36m\][\[\e[1;31m\]\u\[\e[0;36m\]@\[\e[1;34m\]$HOST_DISPLAY_NAME\[\e[0;36m\]: \[\e[0m\]\w\[\e[0;36m\]]\[\e[0m\]\$\[\e[1;32m\]\s\[\e[0;33m\]$(__git_ps1)\[\e[0;36m\]> \[\e[0m\]\n$ ';

if [ -z "$SSH_AUTH_SOCK" ] ; then
  ssh-add -t 604800 ~/.ssh/id_rsa
fi
