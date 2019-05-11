#!/usr/bin/env bash
###################
# Homebrew Update, Upgrade, Cleanup, Log, and List
#
# Runs `brew update' and saves the output to a dated logfile in your home directory.
#
# @see Semantic Versioning 2.0.0 <https://semver.org/spec/v2.0.0.html>
# @see Semantic Versioning and Structure for IETF Specifications draft-claise-semver-02 <https://tools.ietf.org/html/draft-claise-semver-02>
#
#####
# ChangeLog:
# ----------
# 2019-01-31  1.3.0      Updated SemVer regex to allow for underscores in the
#                        pre-release section.
# 2019-01-19  1.2.0      Updated term_wipe function to work properly in KiTTY.
#                        Added new message to check if log should be
#                        automatically removed.
# 2019-01-11  1.1.0      Added cleanup as it's own option/command.
#                        Added semver command for compatibility checking.
#                        Updated SemVer regex.
# 
# 2019-01-07  1.0.0      Added upgrade option with major and minor version
#                        checking for smart cleanup. Also added help.
# 2018-06-28  0.3.0      Updated to work better with tmux
# 2018-03-18  0.2.0      Now removes logs that only have 'Already up-to-date'
#                        Now checks for $XDG_CONFIG_HOME and $HOME/.local
#                        directories and creates a brewup directory if one of
#                        those exists. Or creates $HOME/.brewup to store
#                        brewup logs.
# 2018-01-10  0.1.1      Updated the output a bit
# 2017-08-10  0.1.0      Initial creation
#

#
# APP DATA
#
readonly APP_AUTHOR='RuneImp <runeimp@gmail.com>'
readonly APP_DESC='Homebrew Update, Upgrade, Cleanup, Log, and List'
readonly APP_LICENSE='MIT'
readonly APP_NAME='BrewUp'
readonly APP_VERSION='1.3.0'
readonly CLI_NAME='brewup'

readonly APP_LABEL="$APP_NAME v$APP_VERSION"


#
# CONSTANTS
#
declare -r HOMEBREW_PREFIX=$(brew --prefix)
declare -r LOG_LEVEL_DEBUG=4
declare -r LOG_LEVEL_ERROR=1
declare -r LOG_LEVEL_FATAL=0
declare -r LOG_LEVEL_INFO=3
declare -r LOG_LEVEL_WARNING=2

# Major, Minor, Patch, Pre-release Version, Build Number
declare -r SEMVER_2_0_0_RE='^(([0-9]+)(\.([0-9]+))(\.([0-9]+)))(-?(([[:alnum:]-]+)(\.[[:alnum:]-])*))?(\+?(([[:alnum:]-]+)(\.[[:alnum:]-])*))?$'
# declare -r SEMVER_CHECK_RE='^(([0-9]+)(\.([0-9]+))?(\.([0-9]+))?)(_(([[:alnum:]-]+)(\.[[:alnum:]-])*))?(-?(([[:alnum:]-]+)(\.[[:alnum:]-])*))?(\+?(([[:alnum:]-]+)(\.[[:alnum:]-])*))?$'
declare -r SEMVER_CHECK_RE='^(([0-9]+)(\.([0-9]+))?(\.([0-9]+))?)(_(([[:alnum:]-]+)(\.[[:alnum:]-])*))?(-?(([[:alnum:]]+[[:alnum:]_-]*)(\.[[:alnum:]-])*))?(\+?(([[:alnum:]-]+)(\.[[:alnum:]-])*))?$'
declare -r SEMVER_DATE_RE='^(([0-9]+)(-?([0-9]{2}))(-?([0-9][0-9]))).?(([0-9][0-9])(\:?([0-9][0-9]))?(\:?([0-9]{2}))?)?(\.?([0-9]+))?([+-][0-9:]{4,5}|[zZ])?$'
declare -r SEMVER_RE='^(([0-9]+)(\.([0-9]+))?(\.([0-9]+))?(\.([0-9]+))?)(_(([[:alnum:]-]+)(\.[[:alnum:]-])*))?(-?(([[:alnum:]]+[[:alnum:]_-]*)(\.[[:alnum:]-])*))?(\+?([[:alnum:].-]+))?$'

# ERRORS
declare -ri ERROR_BAD_ARGUMENT=5
declare -ri ERROR_SEMVER_PARSE=4
declare -ri ERROR_VERSIONS_MATCH=3


declare -r SKIP_MSG_NO_CHANGES_CORE="$(cat <<EOM
Updated 1 tap (homebrew/core).
No changes to formulae.
EOM
)"
declare -r SKIP_MSG_NO_CHANGES_CASK="$(cat <<EOM
Updated 1 tap (homebrew/cask).
No changes to formulae.
EOM
)"
declare -r SKIP_MSG_UPDATED_ONE_CASK_="$(cat <<EOM
Updated 1 tap (homebrew/cask).

EOM
)"

declare -a SKIP_MESSAGES=( "Already up-to-date." "No changes to formulae." )


#
# VARIABLES
#
declare -a ARGS
declare -a semver_parsed
declare -i debug_level=$LOG_LEVEL_INFO
declare -i dry_run=1 # Command line boolean false
declare -i force_build_test=1
declare cleanup_retain='minor'
declare test_detail=''
declare test_feature=''
declare test_section=''


#
# FUNCTIONS
#
brew_upgrade()
{
	echo
	if [[ $dry_run -eq 0 ]]; then
		echo "Upgrading Homebrew Packages (dry-run)"
	else
		echo "Upgrading Homebrew Packages"
		brew upgrade
	fi
	echo
	smart_cleanup
}

# 0 fatal
# 1 error
# 2 warning
# 3 info
# 4 log_debug

log()
{
	local level="$1"
	local msg="$2"

	printf "%7.7s: %s\n" "$level" "$msg" | fold -w $COLUMNS 1>&2
}

log_debug()
{
	if [[ $debug_level -ge $LOG_LEVEL_DEBUG ]]; then
		log 'DEBUG' "$1"
	fi
}

log_error()
{
	if [[ $debug_level -ge $LOG_LEVEL_ERROR ]]; then
		log 'ERROR' "$1"
	fi
}

log_fatal()
{
	if [[ $debug_level -ge $LOG_LEVEL_FATAL ]]; then
		log 'FATAL' "$1"
	fi
}

log_info()
{
	if [[ $debug_level -ge $LOG_LEVEL_INFO ]]; then
		log 'INFO' "$1"
	fi
}

log_warn()
{
	if [[ $debug_level -ge $LOG_LEVEL_WARNING ]]; then
		log 'WARNING' "$1"
	fi
}

semver_check()
{
	local -i i=0
	local -i version_major
	local -i version_minor
	local -i version_patch
	local version_build
	local version_mmpr
	local version_prere

	until [[ $# -eq 0 ]]; do
		semver="$1"
		echo "SemVer check '$semver'..." 1>&2
		if [[ "$semver" =~ $SEMVER_2_0_0_RE ]]; then
			i=0
			while [[ $i -lt ${#BASH_REMATCH[@]} ]]; do
				if [[ ${#BASH_REMATCH[$i]} -gt 0 ]]; then
					log_debug "semver_check() | \${BASH_REMATCH[$i]} = ${BASH_REMATCH[$i]}"
				fi
				let "i += 1"
			done

			version_mmpr=${BASH_REMATCH[1]}
			version_major=${BASH_REMATCH[2]}
			version_minor=${BASH_REMATCH[4]}
			version_patch=${BASH_REMATCH[6]}
			version_prere="${BASH_REMATCH[8]}"
			version_build="${BASH_REMATCH[12]}"

			echo "SemVer 2.0.0 match" 1>&2
			echo "       Version: $version_mmpr" 1>&2
			echo "         Major: $version_major" 1>&2
			echo "         Minor: $version_minor" 1>&2
			echo "         Patch: $version_patch" 1>&2
			[[ ${#version_prere} -gt 0 ]] && echo "   Pre-release: $version_prere" 1>&2
			[[ ${#version_build} -gt 0 ]] && echo "         Build: $version_build" 1>&2
			echo
		elif [[ "$semver" =~ $SEMVER_CHECK_RE ]]; then
			i=0
			while [[ $i -lt ${#BASH_REMATCH[@]} ]]; do
				if [[ ${#BASH_REMATCH[$i]} -gt 0 ]]; then
					log_debug "semver_check() | \${BASH_REMATCH[$i]} = ${BASH_REMATCH[$i]}"
				fi
				let "i += 1"
			done

			version_mmpr=${BASH_REMATCH[1]}
			version_major=${BASH_REMATCH[2]}
			version_minor=${BASH_REMATCH[4]}
			version_patch=${BASH_REMATCH[6]}
			version_postre=${BASH_REMATCH[8]}
			version_prere="${BASH_REMATCH[12]}"
			version_build="${BASH_REMATCH[16]}"

			echo "$APP_NAME SemVer match" 1>&2
			echo "       Version: $version_mmpr" 1>&2
			echo "         Major: $version_major" 1>&2
			echo "         Minor: $version_minor" 1>&2
			echo "         Patch: $version_patch" 1>&2
			[[ ${#version_postre} -gt 0 ]] && echo "  Post-release: $version_postre" 1>&2
			[[ ${#version_prere} -gt 0 ]] && echo "   Pre-release: $version_prere" 1>&2
			[[ ${#version_build} -gt 0 ]] && echo "         Build: $version_build" 1>&2
			echo
		else
			echo "'$semver' is not a SemVer match" 1>&2
		fi
		shift
	done
}

semver_cmp_mmpr()
{
	local -a mmpr_1_components
	local -a mmpr_2_components
	local -i cmp_major=0
	local -i cmp_minor=0
	local -i cmp_patch=0
	local -i cmp_revision=0
	local -i i=0
	local -i max=0
	local -r NUMBER_RE='^([0-9]+)$'
	local -ri MAJOR_ID=0
	local -ri MINOR_ID=1
	local -ri PATCH_ID=2
	local -ri REVISION_ID=3
	local id='equal'
	local mmpr_1="$1"
	local mmpr_2="$2"


	old_IFS="$IFS"
	IFS='.'
	mmpr_1_components=( $mmpr_1 )
	mmpr_2_components=( $mmpr_2 )
	IFS="$old_IFS"

	log_debug "semver_cmp_mmpr() | \${#mmpr_1_components[@]} = ${#mmpr_1_components[@]} | \${mmpr_1_components[*]} = ${mmpr_1_components[*]}"
	log_debug "semver_cmp_mmpr() | \${mmpr_1_components[0]} = ${mmpr_1_components[0]}"
	log_debug "semver_cmp_mmpr() | \${mmpr_1_components[1]} = ${mmpr_1_components[1]}"
	log_debug "semver_cmp_mmpr() | \${mmpr_1_components[2]} = ${mmpr_1_components[2]}"
	log_debug "semver_cmp_mmpr() | \${mmpr_1_components[3]} = ${mmpr_1_components[3]}"
	
	log_debug "semver_cmp_mmpr()"

	log_debug "semver_cmp_mmpr() | \${#mmpr_2_components[@]} = ${#mmpr_2_components[@]} | \${mmpr_2_components[*]} = ${mmpr_2_components[*]}"
	log_debug "semver_cmp_mmpr() | \${mmpr_2_components[0]} = ${mmpr_2_components[0]}"
	log_debug "semver_cmp_mmpr() | \${mmpr_2_components[1]} = ${mmpr_2_components[1]}"
	log_debug "semver_cmp_mmpr() | \${mmpr_2_components[2]} = ${mmpr_2_components[2]}"
	log_debug "semver_cmp_mmpr() | \${mmpr_2_components[3]} = ${mmpr_2_components[3]}"

	if [[ ${#mmpr_1_components[@]} -gt ${#mmpr_2_components[@]} ]]; then
		max=${#mmpr_1_components[@]}
	else
		max=${#mmpr_2_components[@]}
	fi
	log_debug "semver_cmp_mmpr() | \$max = $max"

	while [[ $i -lt $max ]]; do
		if [[ ${mmpr_1_components[$i]} -eq ${mmpr_2_components[$i]} ]]; then
			let "i += 1"
		else
			case $i in
				$MAJOR_ID) cmp_major=1
					id='major' ;;
				$MINOR_ID) cmp_minor=1
					id='minor' ;;
				$PATCH_ID) cmp_patch=1
					id='patch' ;;
				$REVISION_ID) cmp_revision=1
					id='revision' ;;
			esac
			log_debug "semver_cmp_mmpr() | cmp_major = $cmp_major | cmp_minor = $cmp_minor | cmp_patch = $cmp_patch | cmp_revision = $cmp_revision | id = $id"
			if [[ ${mmpr_1_components[$i]} -lt ${mmpr_2_components[$i]} ]]; then
				echo "$mmpr_1 $id"
				return 1
			else
				echo "$mmpr_2 $id"
				return 2
			fi
		fi
	done

	echo "0 $id"

	return 0
}

semver_cmp_prere()
{
	local -a component_1_identities
	local -a component_2_identities
	local -i i=0
	local -i max=0
	local -r NUMBER_RE='^([0-9]+)$'
	local component_1="$1"
	local component_2="$2"
	local result=0

	if [[ ${#component_1} -eq 0 ]] || [[ ${#component_2} -eq 0 ]]; then
		# NOTE: Should also check for whitespace only
		if [[ ${#component_1} -eq 0 ]] && [[ ${#component_2} -eq 0 ]]; then
			return 0
		else
			if [[ ${#component_1} -eq 0 ]]; then
				echo "$component_2"
				return 2
			else
				echo "$component_1"
				return 1
			fi
		fi
	fi

	old_IFS="$IFS"
	IFS='.'
	component_1_identities=( $component_1 )
	component_2_identities=( $component_2 )
	IFS="$old_IFS"

	log_debug "semver_cmp_prere() | \${component_1_identities[*]} = ${component_1_identities[*]}"
	log_debug "semver_cmp_prere() | \${#component_1_identities[@]} = ${#component_1_identities[@]}"
	log_debug "semver_cmp_prere() | \${component_1_identities[0]} = ${component_1_identities[0]}"
	log_debug "semver_cmp_prere() | \${component_1_identities[1]} = ${component_1_identities[1]}"
	log_debug "semver_cmp_prere() | \${component_1_identities[2]} = ${component_1_identities[2]}"

	log_debug "semver_cmp_prere() | \${component_2_identities[*]} = ${component_2_identities[*]}"
	log_debug "semver_cmp_prere() | \${#component_2_identities[@]} = ${#component_2_identities[@]}"
	log_debug "semver_cmp_prere() | \${component_2_identities[0]} = ${component_2_identities[0]}"
	log_debug "semver_cmp_prere() | \${component_2_identities[1]} = ${component_2_identities[1]}"
	log_debug "semver_cmp_prere() | \${component_2_identities[2]} = ${component_2_identities[2]}"

	if [[ ${#component_1_identities[@]} -gt ${#component_2_identities[@]} ]]; then
		max=${#component_1_identities[@]}
	else
		max=${#component_2_identities[@]}
	fi
	log_debug "semver_cmp_prere() | \$max = $max"

	while [[ $i -lt $max ]]; do
		log_debug "semver_cmp_prere() | \$i = $i"
		if [[ ${component_1_identities[$i]} =~ $NUMBER_RE ]] && [[ ${component_2_identities[$i]} =~ $NUMBER_RE ]]; then
			if [[ ${component_1_identities[$i]} -eq ${component_2_identities[$i]} ]]; then
				log_debug "semver_cmp_prere() | number | Are equal"
				let "i += 1"
			elif [[ ${component_1_identities[$i]} -lt ${component_2_identities[$i]} ]]; then
				log_debug "semver_cmp_prere() | number | \$component_1 = $component_1"
				echo "$component_1"
				return 1
			else
				log_debug "semver_cmp_prere() | number | \$component_2 = $component_2"
				echo "$component_2"
				return 2
			fi
		else
			if [[ "${component_1_identities[$i]}" = "${component_2_identities[$i]}" ]]; then
				log_debug "semver_cmp_prere() | string | Are equal"
				let "i += 1"
			elif [[ "${component_1_identities[$i]}" < "${component_2_identities[$i]}" ]]; then
				log_debug "semver_cmp_prere() | string | \$component_1 = '$component_1'"
				echo "$component_1"
				return 1
			else
				log_debug "semver_cmp_prere() | string | \$component_2 = '$component_2'"
				echo "$component_2"
				return 2
			fi
		fi
	done

	return 0
}

semver_cmp_postre()
{
	local -a component_1_identities
	local -a component_2_identities
	local -i i=0
	local -i max=0
	local -r NUMBER_RE='^([0-9]+)$'
	local component_1="$1"
	local component_2="$2"
	local result=0

	if [[ ${#component_1} -eq 0 ]] || [[ ${#component_2} -eq 0 ]]; then
		# NOTE: Should also check for whitespace only
		if [[ ${#component_1} -eq 0 ]] && [[ ${#component_2} -eq 0 ]]; then
			return 0
		else
			if [[ ${#component_1} -eq 0 ]]; then
				echo "$component_1"
				return 1
			else
				echo "$component_2"
				return 2
			fi
		fi
	fi

	old_IFS="$IFS"
	IFS='.'
	component_1_identities=( $component_1 )
	component_2_identities=( $component_2 )
	IFS="$old_IFS"

	log_debug "semver_cmp_postre() | \${component_1_identities[*]} = ${component_1_identities[*]}"
	log_debug "semver_cmp_postre() | \${#component_1_identities[@]} = ${#component_1_identities[@]}"
	log_debug "semver_cmp_postre() | \${component_1_identities[0]} = ${component_1_identities[0]}"
	log_debug "semver_cmp_postre() | \${component_1_identities[1]} = ${component_1_identities[1]}"
	log_debug "semver_cmp_postre() | \${component_1_identities[2]} = ${component_1_identities[2]}"

	log_debug "semver_cmp_postre() | \${component_2_identities[*]} = ${component_2_identities[*]}"
	log_debug "semver_cmp_postre() | \${#component_2_identities[@]} = ${#component_2_identities[@]}"
	log_debug "semver_cmp_postre() | \${component_2_identities[0]} = ${component_2_identities[0]}"
	log_debug "semver_cmp_postre() | \${component_2_identities[1]} = ${component_2_identities[1]}"
	log_debug "semver_cmp_postre() | \${component_2_identities[2]} = ${component_2_identities[2]}"

	if [[ ${#component_1_identities[@]} -gt ${#component_2_identities[@]} ]]; then
		max=${#component_1_identities[@]}
	else
		max=${#component_2_identities[@]}
	fi
	log_debug "semver_cmp_postre() | \$max = $max"

	while [[ $i -lt $max ]]; do
		log_debug "semver_cmp_postre() | \$i = $i"
		if [[ ${component_1_identities[$i]} =~ $NUMBER_RE ]] && [[ ${component_2_identities[$i]} =~ $NUMBER_RE ]]; then
			if [[ ${component_1_identities[$i]} -eq ${component_2_identities[$i]} ]]; then
				log_debug "semver_cmp_postre() | number | Are equal"
				let "i += 1"
			elif [[ ${component_1_identities[$i]} -lt ${component_2_identities[$i]} ]]; then
				log_debug "semver_cmp_postre() | number | \$component_1 = $component_1"
				echo "$component_1"
				return 1
			else
				log_debug "semver_cmp_postre() | number | \$component_2 = $component_2"
				echo "$component_2"
				return 2
			fi
		else
			if [[ "${component_1_identities[$i]}" = "${component_2_identities[$i]}" ]]; then
				log_debug "semver_cmp_postre() | string | Are equal"
				let "i += 1"
			elif [[ "${component_1_identities[$i]}" < "${component_2_identities[$i]}" ]]; then
				log_debug "semver_cmp_postre() | string | \$component_1 = '$component_1'"
				echo "$component_1"
				return 1
			else
				log_debug "semver_cmp_postre() | string | \$component_2 = '$component_2'"
				echo "$component_2"
				return 2
			fi
		fi
	done

	return 0
}

semver_cmp_diff()
{
	log_debug "semver_cmp_diff() | test_code = '$1' | version_a = '$2' | version_b = '$3'"
	local -i test_code=$1
	local version_a="$2"
	local version_b="$3"

	if [[ $test_code -eq 1 ]]; then
		echo "$version_a"
	else
		echo "$version_b"
	fi
	return $test_code
}

semver_cmp()
{
	local -a mmpr_result
	local -i build_code
	local -i i
	local -i mmpr_code
	local -i parser_code
	local -i prere_code
	local -i result
	local build_result
	local prere_result
	local version_a="$1"
	local version_b="$2"

	log_debug "semver_cmp() | version_a = '$version_a' | version_b = '$version_b'"

	semver_parser "$version_a"
	parser_code=$?
	if [[ $parser_code -gt 0 ]]; then
		return $parser_code
	fi
	log_debug "semver_cmp() | \${#semver_parsed[@]} = ${#semver_parsed[@]} | \${semver_parsed[*]} = '${semver_parsed[*]}'"
	local version_a_mmpr="${semver_parsed[0]}"
	local version_a_postre="${semver_parsed[1]}"
	local version_a_prere="${semver_parsed[2]}"
	local version_a_build="${semver_parsed[3]}"

	semver_parser "$version_b"
	parser_code=$?
	if [[ $parser_code -gt 0 ]]; then
		return $parser_code
	fi
	log_debug "semver_cmp() | \${#semver_parsed[@]} = ${#semver_parsed[@]} | \${semver_parsed[*]} = '${semver_parsed[*]}'"
	local version_b_mmpr="${semver_parsed[0]}"
	local version_b_postre="${semver_parsed[1]}"
	local version_b_prere="${semver_parsed[2]}"
	local version_b_build="${semver_parsed[3]}"

	log_debug "semver_cmp() | version_a = $version_a | mmpr = $version_a_mmpr | post = $version_a_postre | pre = $version_a_prere | build = $version_a_build"
	log_debug "semver_cmp() | version_b = $version_b | mmpr = $version_b_mmpr | post = $version_b_postre | pre = $version_b_prere | build = $version_b_build"

	mmpr_result=( $(semver_cmp_mmpr "$version_a_mmpr" "$version_b_mmpr") )
	mmpr_code=$?
	postre_result="$(semver_cmp_postre "$version_a_postre" "$version_b_postre")"
	postre_code=$?
	prere_result="$(semver_cmp_prere "$version_a_prere" "$version_b_prere")"
	prere_code=$?
	build_result="$(semver_cmp_prere "$version_a_build" "$version_b_build")"
	build_code=$?

	log_debug "semver_cmp() | version_a = $version_a | version_b = $version_b"
	log_debug "semver_cmp() |   mmpr_code = $mmpr_code |   mmpr_result = ${mmpr_result[0]} (${mmpr_result[1]})"
	log_debug "semver_cmp() | postre_code = $postre_code | postre_result = '$postre_result'"
	log_debug "semver_cmp() |  prere_code = $prere_code |  prere_result = '$prere_result'"
	log_debug "semver_cmp() |  build_code = $build_code |  build_result = '$build_result'"
	log_debug "semver_cmp() | cleanup_retain = '$cleanup_retain'"

	# If mmpr_code = 0

	case "$cleanup_retain" in
		major)
			# Retain one of each major versions
			# If MMP Code is > 0 and ${mmpr_result[1]} == major then keep both
			# If MMP Code is > 0 and ${mmpr_result[1]} == minor then kill lesser
			# If MMP Code is > 0 and ${mmpr_result[1]} == patch then kill lesser
			# If MMP Code is 0 check pre-release and kill lesser

			if [[ $mmpr_code -gt 0 ]]; then
				if [[ "${mmpr_result[1]}" = 'major' ]]; then
					return 0
				elif [[ "${mmpr_result[1]}" = 'minor' ]] || [[ "${mmpr_result[1]}" = 'patch' ]]; then
					semver_cmp_diff $mmpr_code "$version_a" "$version_b"
					return $?
				else
					if [[ $postre_code -gt 0 ]]; then
						semver_cmp_diff $postre_code "$version_a" "$version_b"
						return $?
					elif [[ $prere_code -gt 0 ]]; then
						semver_cmp_diff $prere_code "$version_a" "$version_b"
						return $?
					elif [[ $build_code -gt 0 ]] && [[ $force_build_test -eq 0 ]]; then
						semver_cmp_diff $build_code "$version_a" "$version_b"
						return $?
					else
						log_info "semver_cmp() | Could not determine lesser version. (${LINENO})"
						echo "Could not determine a lesser verion between $version_a and $version_b . They appear to be equal." 1>&2
					fi
				fi
			else
				if [[ $postre_code -gt 0 ]]; then
					semver_cmp_diff $postre_code "$version_a" "$version_b"
					return $?
				elif [[ $prere_code -gt 0 ]]; then
					semver_cmp_diff $prere_code "$version_a" "$version_b"
					return $?
				elif [[ $build_code -gt 0 ]] && [[ $force_build_test -eq 0 ]]; then
					semver_cmp_diff $build_code "$version_a" "$version_b"
					return $?
				else
					log_info "semver_cmp() | Could not determine lesser version. (${LINENO})"
					echo "Could not determine a lesser verion between $version_a and $version_b . They appear to be equal." 1>&2
				fi
			fi
			;;
		minor)
			# Retain one of each major and minor versions
			# If MMP Code is > 0 and ${mmpr_result[1]} == major then keep both
			# If MMP Code is > 0 and ${mmpr_result[1]} == minor then keep both
			# If MMP Code is > 0 and ${mmpr_result[1]} == patch then kill lesser
			# If MMP Code is 0 check pre-release and kill lesser

			if [[ $mmpr_code -gt 0 ]]; then
				if [[ "${mmpr_result[1]}" = 'major' ]] || [[ "${mmpr_result[1]}" = 'minor' ]]; then
					return 0
				elif [[ "${mmpr_result[1]}" = 'patch' ]]; then
					semver_cmp_diff $mmpr_code "$version_a" "$version_b"
					return $?
				elif [[ "${mmpr_result[1]}" = 'revision' ]]; then
					semver_cmp_diff $mmpr_code "$version_a" "$version_b"
					return $?
				else
					if [[ $postre_code -gt 0 ]]; then
						semver_cmp_diff $postre_code "$version_a" "$version_b"
						return $?
					elif [[ $prere_code -gt 0 ]]; then
						semver_cmp_diff $prere_code "$version_a" "$version_b"
						return $?
					elif [[ $build_code -gt 0 ]] && [[ $force_build_test -eq 0 ]]; then
						semver_cmp_diff $build_code "$version_a" "$version_b"
						return $?
					else
						log_info "semver_cmp() | Could not determine lesser version. (${LINENO})"
						echo "Could not determine a lesser verion between $version_a and $version_b . They appear to be equal." 1>&2
					fi
				fi
			else
				log_debug "semver_cmp() | \$postre_code = '$postre_code' | \$prere_code = '$prere_code' | \$build_code = '$build_code'"
				if [[ $postre_code -gt 0 ]]; then
					semver_cmp_diff $postre_code "$version_a" "$version_b"
					return $?
				elif [[ $prere_code -gt 0 ]]; then
					semver_cmp_diff $prere_code "$version_a" "$version_b"
					return $?
				elif [[ $build_code -gt 0 ]] && [[ $force_build_test -eq 0 ]]; then
					semver_cmp_diff $build_code "$version_a" "$version_b"
					return $?
				else
					log_info "semver_cmp() | Could not determine lesser version. (${LINENO})"
					echo "Could not determine a lesser verion between $version_a and $version_b . They appear to be equal." 1>&2
				fi
			fi
			;;
		patch)
			# Retain one of each major, minor, and patch versions
			# If MMP Code is 0 check pre-release and kill lesser
			# else keep both
			if [[ "${mmpr_result[1]}" = 'major' ]] || [[ "${mmpr_result[1]}" = 'minor' ]] || [[ "${mmpr_result[1]}" = 'patch' ]]; then
				return 0
			else
				if [[ "${mmpr_result[1]}" = 'revision' ]]; then
					semver_cmp_diff $postre_code "$version_a" "$version_b"
					return $?
				elif [[ $postre_code -gt 0 ]]; then
					semver_cmp_diff $postre_code "$version_a" "$version_b"
					return $?
				elif [[ $prere_code -gt 0 ]]; then
					semver_cmp_diff $prere_code "$version_a" "$version_b"
					return $?
				elif [[ $build_code -gt 0 ]] && [[ $force_build_test -eq 0 ]]; then
					semver_cmp_diff $build_code "$version_a" "$version_b"
					return $?
				else
					log_info "semver_cmp() | Could not determine lesser version. (${LINENO})"
					echo "Could not determine a lesser verion between $version_a and $version_b . They appear to be equal." 1>&2
				fi
			fi
			;;
		revision)
			# Retain one of each major, minor, patch, and revision
			# If MMP Code is 0 check post-release, pre-release, etc. and kill lesser
			# else keep both
			if [[ "${mmpr_result[1]}" = 'major' ]] || [[ "${mmpr_result[1]}" = 'minor' ]] || [[ "${mmpr_result[1]}" = 'patch' ]] || [[ "${mmpr_result[1]}" = 'revision' ]]; then
				return 0
			else
				if [[ $postre_code -gt 0 ]]; then
					semver_cmp_diff $postre_code "$version_a" "$version_b"
					return $?
				elif [[ $prere_code -gt 0 ]]; then
					semver_cmp_diff $prere_code "$version_a" "$version_b"
					return $?
				elif [[ $build_code -gt 0 ]] && [[ $force_build_test -eq 0 ]]; then
					semver_cmp_diff $build_code "$version_a" "$version_b"
					return $?
				else
					log_info "semver_cmp() | Could not determine lesser version. (${LINENO})"
					echo "Could not determine a lesser verion between $version_a and $version_b . They appear to be equal." 1>&2
				fi
			fi
			;;
		prere | prerelease | pre-release)
			# Retain all pre-release versions and better
			# If Pre-Release Code is 0 and force_build_test is true (0) check build and kill the lesser
			# If Pre-Release Code is 0 and force_build_test is false (1) keep both
			if [[ $force_build_test -eq 0 ]]; then
				if [[ $prere_code -eq 0 ]] && [[ $build_code -eq 0 ]]; then
					return 0
				else
					if [[ $build_code -eq 1 ]]; then
						echo "$version_a"
					else
						echo "$version_b"
					fi
					return $build_code
				fi
			else
				return 0
			fi
			;;
		build)
			# Retain all versions
			return 0
			;;
	esac

	return 0
}

semver_parser()
{
	# 0 = Major.Minor.Patch
	# 1 = Post-release
	# 2 = Pre-release
	# 3 = Build
	local major_minor_patch_revision
	local post_release
	local pre_release
	local build_version

	semver_parsed=( )

	if [[ "$1" =~ $SEMVER_DATE_RE ]]; then
		i=0
		while [[ $i -lt ${#BASH_REMATCH[@]} ]]; do
			if [[ ${#BASH_REMATCH[$i]} -gt 0 ]]; then
				log_debug "semver_parser() | SEMVER_DATE_RE $1 | \${BASH_REMATCH[$i]} = ${BASH_REMATCH[$i]}"
			fi
			let "i += 1"
		done
		local year=${BASH_REMATCH[2]}           # Major
		local month=${BASH_REMATCH[4]}          # Minor
		local day=${BASH_REMATCH[6]}            # Patch
		local hour=${BASH_REMATCH[8]}           # Post-release
		local minute=${BASH_REMATCH[10]}        # Post-release
		local second=${BASH_REMATCH[12]}        # Post-release
		local micro_second=${BASH_REMATCH[14]}  # Post-release
		local time_zone=${BASH_REMATCH[15]}     # Post-release

		major_minor_patch_revision="${year}.${month}.${day}"
		post_release=""
		[[ ${#hour} -gt 0 ]]         && post_release="${post_release}${hour}"
		[[ ${#minute} -gt 0 ]]       && post_release="${post_release}.${minute}"
		[[ ${#second} -gt 0 ]]       && post_release="${post_release}.${second}"
		[[ ${#micro_second} -gt 0 ]] && post_release="${post_release}.${micro_second}"
		[[ ${#time_zone} -gt 0 ]]    && post_release="${post_release}.${time_zone}"
		pre_release=""
		build_version=""

		semver_parsed=( "${major_minor_patch_revision}" "${post_release}" "${pre_release}" "${build_version}" )
		log_debug "semver_parser() | SEMVER_DATE_RE | ${semver_parsed[*]}"
	elif [[ "$1" =~ $SEMVER_RE ]]; then
		i=0
		while [[ $i -lt ${#BASH_REMATCH[@]} ]]; do
			if [[ ${#BASH_REMATCH[$i]} -gt 0 ]]; then
				log_debug "semver_parser() | SEMVER_RE $1 | \${BASH_REMATCH[$i]} = ${BASH_REMATCH[$i]}"
			fi
			let "i += 1"
		done

		major_minor_patch_revision="${BASH_REMATCH[1]}"
		post_release="${BASH_REMATCH[10]}"
		pre_release="${BASH_REMATCH[14]}"
		build_version="${BASH_REMATCH[18]}"

		semver_parsed=( "${major_minor_patch_revision}" "${post_release}" "${pre_release}" "${build_version}" )
		log_debug "semver_parser() | SEMVER_RE | ${semver_parsed[*]}"
	else
		log_error "semver_parser() | $1 | No SemVer Match"
		return $ERROR_SEMVER_PARSE
	fi
	log_debug "semver_parser() | ${semver_parsed[*]}"

	return 0
}


show_help()
{
	cat <<-EOH
	$APP_LABEL

	$APP_DESC

	$CLI_NAME COMMAND [OPTIONS] ...

	COMMANDS:
	  cleanup     Cleanup when a package has multiple installs
	  help        Display this help info
	  upgrade     Upgrade all packages with "smart cleanup" afterward
	  semver      Check compatibility of a Semantic Version'ish number.
	              Also outputs the breakdown of the number. Major, Minor, etc.
	  test        A simple testing system
	  version     Display app version info

	OPTIONS:
	  -b | -build | --build       Force testing against build
	  -c | -clean | --cleanup     Cleanup when a package has multiple installs
	  -h | -help  | --help        Display this help info
	  -l | last   | list          Display the last brewup update list
	  -n | -noop  | --dry-run     Don't actually upgrade or cleanup anything
	  -r | -ret   | --retain      For cleanup. What level to always retain:
	                              major, minor, patch, prere, build, revision
	  -u | -up    | --upgrade     Upgrade all packages with "smart cleanup"
	  -v | -ver   | --version     Display app version info

	"smart cleanup" saves space by removing extra patch versions of a package.
	This means that brewup will check for multiple versions of a package and
	remove all lower patch versions. For example, lets say you have python 3.5.6,
	3.6.5, 3.6.6, and 3.7.0. The smart cleanup routine will only remove 3.6.5 as
	3.6.6 is the highest patch version of the 3.6 versions. Also 3.5.6 is the only
	3.5 version and 3.7.0 is the only 3.7 version so they are left alone.

	Regarding the retain option, note that you can also use prerelease or
	pre-release where prere is stated. Also for example if you specify minor as the
	retain level then out of the following package versions 0.1.2, 1.0.0-rc1,
	1.0.0-beta, 1.0.0, and 1.1.0 cleanup would only remove 1.0.0-rc1 and
	1.0.0-beta. As they share the same 1.0 start of the version with 1.0.0 and it
	is a release version. So it is the highest version of the three 1.0.x versions.

EOH
}


smart_cleanup()
{
	local -a fields
	local -a keeping
	local -a killing
	local -a versions
	local -i i=0
	local -i j=1
	local -i k=0
	local -i result=0
	local noop_msg=""
	local list="$(brew list --versions --multiple)"
# 	local list="runeimp 0.1.0 0.2 0.2.1 1.0 0.3 1.2.3
# spiritpixie 2.0.0_1 2.0.0-rc1.2+69.13 2.0.0-rc2 2.0.0"
	# local list="spiritpixie 2.0.0_1 2.0.0-rc1.2+69.13 2.0.0-rc2 2.0.0"
	# local list="clang-format 2018-10-04 2018-12-18"
	# local list="kmng 2018-10-04T12:34:56 2018-10-04T123456 2018-10-04T123456.7891011z 20181004x1234567891011z"
# 	local list="kmng 2018-10-04T12:34:56 2018-10-04T1234
# runeimp 0.1.0 0.1.2.3 0.1.2.3_4 1.2.3-rc 1.2.3 0 1.2.3_4+56.789"
	# local list="runeimp 0.1.2.2 0.1.2.3 0.1.2.3_4 0.1.2.3_45 1.2.3"
	local old_IFS="$IFS"

	if [[ $dry_run -eq 0 ]]; then
		noop_msg=" (dry-run)"
	fi

	echo "Smart Cleanup of Homebrew Packages$noop_msg"

	IFS=$'\n'
	for item in $list; do
		log_debug "smart_cleanup() | item = '$item'"
		IFS=' '

		fields=( $item )
		app=${fields[0]}          # Get app name
		unset fields[0]           # Delete item at index
		versions=( $(printf "${fields[*]}" | tr ' ' "\n" | sort | tr "\n" ' ') ) # Sort and re-index to new array
		unset fields

		i=0
		j=1
		keeping=( ${versions[@]} )
		killing=( )
		echo "    Multiple versions of $app [$(echo ${versions[@]} | sed 's/ /, /g')]"
		log_debug "smart_cleanup() | 0 | $app ${versions[0]}"
		log_debug "smart_cleanup() | 1 | $app ${versions[1]}"
		while [[ $j -lt ${#versions[@]} ]]; do
			log_debug "smart_cleanup() | $i of ${#versions[@]} | $app ${versions[$i]}"
			log_debug "smart_cleanup() | $j of ${#versions[@]} | $app ${versions[$j]}"
			ver_kill="$(semver_cmp "${versions[$i]}" "${versions[$j]}")"
			result=$?
			log_debug "smart_cleanup() | result = $result | ver_kill = $ver_kill"
			if [[ $result -eq 0 ]]; then
				log_debug "smart_cleanup() | leaving both"

				let "i += 1"
				let "j = i + 1"
			elif [[ $result -gt 2 ]]; then
				exit $result
			else
				log_debug "smart_cleanup() | killing '$ver_kill'"
				for k in $i $j; do
					log_debug "smart_cleanup() | \${versions[$k]} = ${versions[$k]} | \$ver_kill = $ver_kill"
					if [[ "${versions[$k]}" = "$ver_kill" ]]; then
						killing=( ${killing[@]} "$ver_kill" )
						log_debug  "smart_cleanup() | unset \${versions[$k]}"
						unset versions[$k]        # Delete item at index
						versions=( ${versions[@]} ) # Re-index array
					fi
				done

				k=0
				while [[ $k -lt ${#keeping[@]} ]]; do
					if [[ ${keeping[$k]} = "$ver_kill" ]]; then
						unset keeping[$k]         # Delete item at index
						keeping=( ${keeping[@]} ) # Re-index array
					fi
					let "k += 1"
				done
			fi
			# break
		done
		keeping=( $(printf "${keeping[*]}" | tr ' ' "\n" | uniq | tr "\n" ' ') ) # Remove duplicates in array
		log_debug "smart_cleanup() | keeping = ${keeping[@]} (${#keeping[@]})"
		if [[ ${#keeping[@]} -gt 0 ]]; then
			# echo "smart_cleanup() | \$keeping = [$(printf "${keeping[*]}" | sed 's/ /, /g' )]"
			if [[ ${#keeping[@]} -gt 1 ]]; then
				echo "        Keeping $app [$(printf "${keeping[*]}" | sed 's/ /, /g' )]"
			else
				echo "        Keeping $app ${keeping[*]}"
			fi
		fi
		log_debug "smart_cleanup() | keeping = [$(printf "${keeping[*]}" | tr ' ' "\n" | uniq | tr "\n" ' ' | sed 's/ /, /g' )]"

		if [[ ${#killing[@]} -gt 0 ]]; then
			log_debug "Killing $app ${killing[@]}"
			if [[ ${#killing[@]} -gt 1 ]]; then
				echo "        Killing $app [$(printf "${killing[*]}" | sed 's/ /, /g' )]$noop_msg"
			else
				echo "        Killing $app ${killing[*]}$noop_msg"
			fi
			if [[ $dry_run -eq 0 ]]; then
				for ver in ${killing[@]}; do
					path="${HOMEBREW_PREFIX}/Cellar/${app}/${ver}"
					echo "rm -rf $path (dry-run)"
				done
			else
				for ver in ${killing[@]}; do
					path="${HOMEBREW_PREFIX}/Cellar/${app}/${ver}"
					if [[ -d "$path" ]]; then
						# echo "rm -rf $path (realish)"
						rm -rf "$path"
					else
						echo "Could not remove $app ${ver}"
						if [[ -e "$path" ]]; then
							echo "    Could not find $path"
						else
							echo "    $path was not a directory"
						fi
					fi
				done
			fi
		fi

		IFS=$'\n'
	done

	IFS="$old_IFS"
}


term_wipe()
{
	if [[ ${#VISUAL_STUDIO_CODE} -gt 0 ]]; then
		clear
	elif [[ $KITTY_WINDOW_ID -gt 0 ]]; then
		if [[ -x "$(which tput)" ]]; then
			echo -ne '\033[22;0t' # Put title in stack
			tput reset
			# tput cup 0 0
			echo -ne '\033[23;0t' # Restore title from stack
		else
			# echo -e \\033c # Reset terminal but leaves one empty line above prompt
			:
		fi
	elif [[ "$(uname)" == 'Darwin' ]] && [[ ${#TMUX} -eq 0 ]]; then
		osascript -e 'tell application "System Events" to keystroke "k" using command down'
	elif [[ -f "$(which tput)" ]]; then
		tput reset
		if [[ ${#TMUX} -gt 0 ]]; then
			tput cup 0 0
		fi
	elif [[ -f "$(which reset)" ]]; then
		reset
	else
		clear
		# alias cls="clear; printf '\33[3J'"
		# echo -ne '\033]50;ClearScrollback\a' # For iTerm2
	fi
}


#
# Check for BREWUP_DIR
#
if [[ -d "${XDG_CONFIG_HOME}/brewup" ]]; then
	BREWUP_DIR="${XDG_CONFIG_HOME}/brewup"
elif [[ -d "${HOME}/.local/brewup" ]]; then
	BREWUP_DIR="${HOME}/.local/brewup"
elif [[ -d "${HOME}/.brewup" ]]; then
	BREWUP_DIR="${HOME}/.brewup"
else
	BREWUP_DIR=""
fi

if [[ ${#BREWUP_DIR} -eq 0 ]]; then
	if [[ "${#XDG_CONFIG_HOME}" -gt 0 ]]; then
		if [[ ! -d "${XDG_CONFIG_HOME}/brewup" ]]; then
			mkdir "${XDG_CONFIG_HOME}/brewup"
		fi
		BREWUP_DIR="${XDG_CONFIG_HOME}/brewup"
	elif [[ -d "${HOME}/.local" ]]; then
		if [[ ! -d "${HOME}/.local/brewup" ]]; then
			mkdir "${HOME}/.local/brewup"
		fi
		BREWUP_DIR="${HOME}/.local/brewup"
	else
		if [[ ! -d "${HOME}/.brewup" ]]; then
			mkdir "${HOME}/.brewup"
		fi
		BREWUP_DIR="${HOME}/.brewup"
	fi
fi


#
# OPTION PARSING
#
if [[ $# -eq 0 ]]; then
	cmd='update'
else
	until [[ $# -eq 0 ]]; do
		case "$1" in
			-b | -build | --build)
				# Force testing against build
				force_build_test=0
				;;
			-c | -clean | --cleanup | cleanup)
				# Cleanup multiple installs
				cmd=cleanup
				;;
			-h | -help | --help | help)
				term_wipe
				show_help
				exit 0
				;;
			-l | last | list)
				# Display the last update list
				cmd='list'
				;;
			-n | -noop | --dry-run)
				# Don't actually upgrade or cleanup
				dry_run=0 # Command line boolean true
				;;
			-r | -ret | --retain)
				case "$2" in
					major | minor | patch | prere | prerelease | pre-release | build | rev | revision)
						if [[ "$2" = 'prerelease' ]] || [[ "$2" = 'pre-release' ]]; then
							cleanup_retain='prere'
						else
							cleanup_retain="$2"
						fi
						if [[ "$2" = 'rev' ]]; then
							cleanup_retain='revision'
						fi
						shift
						;;
					*) log_error "The retain option can only accept major, minor, patch, prere, prerelease, pre-release, or build as it's mandatory argument."
						exit $ERROR_BAD_ARGUMENT
						;;
				esac
				;;
			-u | -up | --upgrade | upgrade)
				# Upgrade and Cleanup major versions only
				cmd='upgrade'
				;;
			-v | -ver | --version | version)
				echo "$APP_LABEL"
				exit 0
				;;
			semver)
				# Check Semver
				cmd='semver'
				;;
			test)
				# Don't actually upgrade or cleanup
				cmd='test'
				test_feature="$2"
				test_section="$3"
				test_detail="$4"
				[[ ${#test_feature} -gt 0 ]] && shift
				[[ ${#test_section} -gt 0 ]] && shift
				[[ ${#test_detail} -gt 0 ]] && shift
				;;
			*)
				ARGS=( ${ARGS[@]} "$1" )
				;;
		esac

		shift
	done
fi


#
# MAIN ENTRYPOINT
#
term_wipe

case "$cmd" in
	cleanup)
		# Cleanup multi-version installs
		smart_cleanup
		;;
	list)
		# Display the last package list
		UPDATE_LOG=$(ls "${BREWUP_DIR}/brew-update_"* | tail -1)
		echo "Viewing ${UPDATE_LOG}"
		cat "$UPDATE_LOG"
		;;
	test)
		if [[ "$test_feature" = 'cleanup' ]]; then
			: # Test cleanup
		elif [[ "$test_feature" = 'semver' ]]; then
			if [[ "$test_section" = 'less' ]]; then
				case "$test_detail" in
					major)	version_a='0.1.2'
							version_b='1.2.3' ;;
					minor)	version_a='1.1.2'
							version_b='1.2.3' ;;
					patch)	version_a='1.2.2'
							version_b='1.2.3' ;;
					onepre)	version_a='1.2.3-beta'
							version_b='1.2.3' ;;
					prere | prerelease | pre-release)
						version_a='1.2.3-alpha.4'
						version_b='1.2.3-beta.4' ;;
					build)	version_a='1.2.3-rc.4+56.7890'
							version_b='1.2.3-rc.4+56789.0' ;;
					date)	version_a='2019-01-12'
							version_b='2019-01-11' ;;
					syspatch)	version_a='1.2.3'
								version_b='1.2.3_1' ;;
					*)	log_warn "Unhandled test detail '$test_detail'" ;;
				esac
			elif [[ "$test_section" = 'equal' ]]; then
				version_a='1.2.3-dev+56.7890'
				version_b='1.2.3-dev+56789.0'
			else
				log_warn "Unhandled test section '$test_section'"
			fi
			semver_cmp "$version_a" "$version_b"
		else
			log_warn "Unhandled test feature '$2'"
		fi
		;;
	semver)
		# SemVer Check
		if [[ ${#ARGS[@]} -eq 0 ]]; then
			echo "The semver command requires at least one argument"
		else
			semver_check ${ARGS[@]}
		fi
		;;
	update)
		# Update Homebrew
		declare -r UPDATE_LOG="${BREWUP_DIR}/brew-update_$(date -j '+%Y-%m-%d_%H%M%S').txt"
		echo "Updating Homebrew..."
		brew update | tee -i "$UPDATE_LOG"

		content="$(cat $UPDATE_LOG)"
		printf "%s\n" "$content"
		echo
		IFS=$'\n'
		for line in $content; do
			for msg in "${SKIP_MESSAGES[@]}"; do
				if [[ "$msg" = "$line" ]]; then
					rm "$UPDATE_LOG"
					break 2
				fi
			done
		done
		;;
	upgrade)
		# Upgrade packages
		brew_upgrade
		;;
	*)
		# How did that happen?
		echo "Uknown command '$cmd'" 1>&2
		;;
esac

