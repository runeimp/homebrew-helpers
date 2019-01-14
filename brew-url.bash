#!/usr/bin/env bash
#####
# Homebrew URL Launcher
#
# @see [Starting browser (Firefox, Safari, Opera, Chrome) from batch/bash script - Tonjoo Studio]: https://tonjoostudio.com/starting-browser-firefox-safari-opera-chrome-from-batchbash-script/
#
#####
# ChangeLog:
# ----------
# 2018-04-21  1.4.0      Added Lynx and Links text browser support.
#                        Also fixed command line options not overriding config.
# 2018-01-17  1.3.1      Added debuging via -D and --debug options
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
readonly APP_VERSION='1.4.0'
readonly CLI_NAME='brew-url'

readonly APP_LABEL="$APP_NAME v$APP_VERSION"


#
# CONSTANTS
#
readonly BROWSER_CHROME='Google Chrome'
readonly BROWSER_FIREFOX='Firefox'
readonly BROWSER_OPERA='Opera'
readonly BROWSER_SAFARI='Safari'
readonly BROWSER_LINKS='links'
readonly BROWSER_LYNX='lynx'


#
# VARIABLES
#
if [[ -n "$BROWSER_NAME" ]]; then
	browser="$BROWSER_NAME"
else
	browser="$BROWSER_SAFARI"
fi
declare -i caskroom=1
declare -i debug=1


#
# LOAD CONFIG
#
if [[ -e "${XDG_CONFIG_HOME}/brew-url" ]]; then
	[ $debug -eq 0 ] && echo "Loading... ${XDG_CONFIG_HOME}/brew-url" 1>&2
	source "${XDG_CONFIG_HOME}/brew-url"
elif [[ -e "${HOME}/.config/brew-url" ]]; then
	[ $debug -eq 0 ] && echo "Loading... ${HOME}/.config/brew-url" 1>&2
	source "${HOME}/.config/brew-url"
elif [[ -e "${HOME}/.local/brew-url" ]]; then
	[ $debug -eq 0 ] && echo "Loading... ${HOME}/.local/brew-url" 1>&2
	source "${HOME}/.local/brew-url"
elif [[ -e "${HOME}/.brew-url" ]]; then
	[ $debug -eq 0 ] && echo "Loading... ${HOME}/.brew-url" 1>&2
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
		-D | --debug)
			debug=0
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
	if [[ "$browser" == "$BROWSER_LINKS" ]]; then
		term-wipe
		echo "Links $url"
		echo
		links -dump "$url"
	elif [[ "$browser" == "$BROWSER_LYNX" ]]; then
		term-wipe
		echo "Lynx $url"
		echo
		lynx --dump "$url"
	else
		open -a "$browser" "$url"
	fi
fi
