#!/usr/bin/env bash
#####
# Homebrew URL Launcher
#
# @see [Starting browser (Firefox, Safari, Opera, Chrome) from batch/bash script - Tonjoo Studio]: https://tonjoostudio.com/starting-browser-firefox-safari-opera-chrome-from-batchbash-script/
#
#####
# ChangeLog:
# ----------
# 2017-09-12  1.3.0      Added BROWSER_NAME env var checking, and config parsing
# 2017-09-07  1.2.1      Updated URL handling
# 2017-04-04  1.2.0      Added the --chrome, --default, -f, --firefox, -o, --opera, -s, --safari, -v, and --version POSIX and GNU options.
# 2017-03-15  1.1.0      Added -c and -d options and smarter parsing. 
# 2016-05-25  1.0.0      Initial script creation?
#

#
# APP DATA
#
readonly APP_AUTHOR='RuneImp <runeimp@gmail.com>'
readonly APP_LICENSE='MIT'
readonly APP_NAME='Homebrew URL Launcher'
readonly APP_VERSION='1.3.0'
readonly CLI_NAME='brew-url'

readonly APP_LABEL="$APP_NAME v$APP_VERSION"


#
# CONSTANTS
#
readonly BROWSER_CHROME='Google Chrome'
readonly BROWSER_FIREFOX='Firefox'
readonly BROWSER_OPERA='Opera'
readonly BROWSER_SAFARI='Safari'


#
# VARIABLES
#
if [[ -n "$BROWSER_NAME" ]]; then
	browser="$BROWSER_NAME"
else
	browser="$BROWSER_SAFARI"
fi
declare -i caskroom=1


#
# LOAD CONFIG
#
if [[ -e "${XDG_CONFIG_HOME}/brew-url" ]]; then
	echo "Loading... ${XDG_CONFIG_HOME}/brew-url"
	source "${XDG_CONFIG_HOME}/brew-url"
elif [[ -e "${HOME}/.config/brew-url" ]]; then
	echo "Loading... ${HOME}/.config/brew-url"
	source "${HOME}/.config/brew-url"
elif [[ -e "${HOME}/.local/brew-url" ]]; then
	echo "Loading... ${HOME}/.local/brew-url"
	source "${HOME}/.local/brew-url"
elif [[ -e "${HOME}/.brew-url" ]]; then
	echo "Loading... ${HOME}/.brew-url"
	source "${HOME}/.brew-url"
fi


#
# OPTION PARSING
#
until [[ $# -eq 0 ]]; do
	case "$1" in
		-c | --chrome)
			browser="$BROWSER_CHROME"
			;;
		-d | --default)
			browser="$BROWSER_SAFARI"
			;;
		[Cc]askroom*)
			caskroom=0
			app="$1"
			;;
		-f | --firefox)
			browser="$BROWSER_FIREFOX"
			;;
		-o | --opera)
			browser="$BROWSER_OPERA"
			;;
		-s | --safari)
			browser="$BROWSER_SAFARI"
			;;
		-v | --version)
			echo "$APP_LABEL"
			exit 0
			;;
		*)
			app="$1"
			;;
	esac

	shift
done

# echo "browser: $browser"
# echo "caskroom: $caskroom"
# echo "app: $app"
# exit 69

result=$(brew info "$app" 2>&1)
exit_code=$?

# echo "result: $result"
# echo "exit_code: $exit_code"

if [[ $exit_code -gt 0 ]]; then
	result=$(brew cask info "$app" 2>&1)
	exit_code=$?
	# echo "result: $result"
	# echo "exit_code: $exit_code"
fi

if [[ $exit_code -gt 0 ]]; then
	echo "Couldn't find app in Homebrew" 1>&2
else
	url=$(echo "$result" | grep -v caskroom | grep -E ^https?:.* | head -1)
	open -a "$browser" "$url"
fi
