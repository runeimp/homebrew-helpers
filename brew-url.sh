#!/usr/bin/env bash
#####
# Homebrew URL Launcher
#
# @see [Starting browser (Firefox, Safari, Opera, Chrome) from batch/bash script - Tonjoo Studio]: https://tonjoostudio.com/starting-browser-firefox-safari-opera-chrome-from-batchbash-script/
#
#####
# ChangeLog:
# ----------
# 2016-05-25  1.0.0      Initial script creation?
#

app="$1"

case "${app:0:8}" in
	[Cc]askroom)
		open -a 'Google Chrome' $(brew cask info $app | grep -v caskroom | egrep ^https?:.*)
		;;
	*)
		open -a 'Google Chrome' $(brew info $app | egrep ^https?:.*)
		;;
esac
