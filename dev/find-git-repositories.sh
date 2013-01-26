#!/bin/bash
#Finds git repositories on the system, eventually update (pull) from remotes
#License: MIT (http://opensource.org/licenses/MIT)
#Copyright: Rxtx Project <nodiscc@gmail.com>
#TODO: list/check/pull multiple branches
#TODO: print multiple remotes on one line
#TODO: quote DIR variables!
#TODO: add a --no-color option

USAGE="USAGE: `basename $0` [OPTION]
    -d /search/path    only search for repositories in /search/path (default ~/)
    -r                 also show remote addresses
    -o                 optimize (git repack && git prune) repositories
    -c                 check for available updates
    -p                 try pushing to remote
    -u                 update (pull) from repositories"

FIND_DIR="$HOME"

RED="\033[00;31m"
GREEN="\033[00;32m"
ENDCOLOR="\033[00m"


while getopts ":d:rcuhpo" opt; do
  case $opt in
    d)
      FIND_DIR="$OPTARG"
      ;;
    r)
      REMOTES="1"
      ;;
    c)
     CHECK="1"
     ;;
    u)
     CHECK="1"
     UPDATE="1"
     ;;
    h)
     echo "$USAGE"
     exit 0
     ;;
    p)
     CHECK="1"
     PUSH="1"
     ;;
    o)
     OPTIMIZE="1"
     ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Usage: -$OPTARG must have an argument" >&2
      exit 1
      ;;
  esac
done

#check if directory is searchable
if [ ! -d $FIND_DIR ]
then
	echo "$FIND_DIR does not exist or is not a valid directory"
	exit 1
else
	FIND_DIR=`readlink -f $FIND_DIR`
fi

#print dir
echo -e "\033[00;32mSearching for git repositories in $FIND_DIR ...\033[00m" >&2

#create array
REPOS=()

#find repos
for i in `find -L $FIND_DIR -name ".git" -type d 2>/dev/null`
do
	REPOS+=(`dirname "$i"`)
done

#print repos list
for DIR in ${REPOS[@]}
do
	REMOTE=`grep "url" $DIR/.git/config 2>/dev/null | awk -F " " '{print $3}'`

	if [ "$REMOTES" = "1" ]
	then
		echo "$DIR - $REMOTE"
	else
		echo $DIR
	fi

	if [ "$CHECK" = "1" ]
	then
		cd $DIR
		git remote update &>/dev/null
		if [[ `git status | egrep "Your branch is ahead"` != "" ]]
			then echo -e "${RED}Not up to date (do a git push)${ENDCOLOR}";
			if "$PUSH"="1"; then echo -e "${GREEN}Pushing to remote...${ENDCOLOR}"; git push; fi
		elif [[ `git status | egrep "Untracked files"` != "" ]]
			then echo -e "${RED}Not up to date (untracked files)${ENDCOLOR}"
		elif [[ `git status | egrep "Your branch is behind"` != "" ]]
			then echo -e "${RED}Not up to date (do a git pull)${ENDCOLOR}"
			if "$UPDATE"="1"; then echo -e "${GREEN}Pulling from remote...${ENDCOLOR}"; git pull; fi
		elif [[ `git status | egrep "not staged for commit"` != "" ]]
			then echo -e "${RED}Not up to date (unstaged changes)${ENDCOLOR}"
		fi
	fi

	if [ "$OPTIMIZE"="1" ]
	then
		cd $DIR
		echo -e "${GREEN}Optimizing repository...${ENDCOLOR}"
		git repack && git prune
	fi
done
