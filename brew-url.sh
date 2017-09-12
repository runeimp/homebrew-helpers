#!/usr/bin/env bash
#####
# Homebrew URL Launcher
#
# @see [Starting browser (Firefox, Safari, Opera, Chrome) from batch/bash script - Tonjoo Studio]: https://tonjoostudio.com/starting-browser-firefox-safari-opera-chrome-from-batchbash-script/
#
#####
# ChangeLog:
# ----------
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
readonly APP_VERSION='1.2.1'
readonly CLI_NAME='brew-url'

readonly APP_LABEL="$APP_NAME v$APP_VERSION"

#
# CONSTANTS
#
readonly BROWSWER_CHROME='Google Chrome'
readonly BROWSWER_FIREFOX='Firefox'
readonly BROWSWER_OPERA='Opera'
readonly BROWSWER_SAFARI='Safari'

#
# VARIABLES
#
browser="$BROWSWER_OPERA"
declare -i caskroom=1

#
# OPTION PARSING
#
# echo "\$@: $@"

until [[ $# -eq 0 ]]; do
	case "$1" in
		-c | --chrome)
			browser="$BROWSWER_CHROME"
			;;
		-d | --default)
			browser="$BROWSWER_SAFARI"
			;;
		[Cc]askroom*)
			caskroom=0
			app="$1"
			;;
		-f | --firefox)
			browser="$BROWSWER_FIREFOX"
			;;
		-o | --opera)
			browser="$BROWSWER_OPERA"
			;;
		-s | --safari)
			browser="$BROWSWER_SAFARI"
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
