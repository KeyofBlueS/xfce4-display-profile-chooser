#!/bin/bash

# xfce4-display-profile-chooser

# Version:    0.0.3
# Author:     KeyofBlueS
# Repository: https://github.com/KeyofBlueS/xfce4-display-profile-chooser
# License:    GNU General Public License v3.0, https://opensource.org/licenses/GPL-3.0

function check_connected_displays()	{
	# TODO: check if configured displays in profile are connected.
	## Please see https://github.com/KeyofBlueS/xfce4-display-profile-chooser/issues/1
	MISSING_DISPLAY='0'
	PROFILE_EDIDS="$(xfconf-query -v -l -c displays -p /"${PROFILE_ID}" | grep '/EDID ' | awk '{print $2}')"
	for PROFILE_EDID in ${PROFILE_EDIDS}; do
		for CONNECTED_EDID in ${CONNECTED_EDIDS}; do
			if ! echo "${CONNECTED_EDID}" | grep -xq "${PROFILE_EDID}"; then
				MISSING_DISPLAY='1'
			fi
		done
	done
}

function list_profiles()	{

	for PROFILE_ID in ${PROFILES_IDS}; do
		PROFILE_NAME="$(xfconf-query -v -l -c displays -p /"${PROFILE_ID}" | awk 'NR==1{for (i=1;i<=NF;i++) printf("%s ",$i)}' | grep -oP '(?<=\ ).*')"
		unset PROFILE_STATE
		unset PROFILE_COLOR
		if echo "${ACTIVE_PROFILE}" | grep -xq "${PROFILE_ID}"; then
			PROFILE_STATE=', state: active'
			PROFILE_COLOR='1;32'
		else
			#PROFILE_STATE=', state: available'
			PROFILE_STATE=''
			PROFILE_COLOR='2;32'
		fi

		## TODO: check if configured displays in profile are connected.
		## Please see https://github.com/KeyofBlueS/xfce4-display-profile-chooser/issues/1
		#check_connected_displays
		if [[ "${MISSING_DISPLAY}" = '1' ]]; then
			PROFILE_STATE=', state: Display/s missing, cannot set this profile'
			PROFILE_COLOR='1;31'
		fi

		echo -e "\e[${PROFILE_COLOR}mid: ${PROFILE_ID}, name: ${PROFILE_NAME:0:-1}${PROFILE_STATE}\e[0m"
	done

	exit 0
}

function set_profile()	{

	PROFILE_NAME="$(xfconf-query -v -l -c displays -p /"${PROFILE_ID}" | awk 'NR==1{for (i=1;i<=NF;i++) printf("%s ",$i)}' | grep -oP '(?<=\ ).*')"
	if echo "${ACTIVE_PROFILE}" | grep -xq "${PROFILE_ID}"; then
		echo -e "\e[1;33mThis profile (${PROFILE_ID} - ${PROFILE_NAME:0:-1}) is already set\e[0m"
		exit 1
	fi
	
	EXIST=0
	for PROFILES_ID in ${PROFILES_IDS}; do
		if echo "${PROFILES_ID}" | grep -xq "${PROFILE_ID}"; then
			EXIST=1
		fi
	done
	if [[ "${EXIST}" = '0' ]]; then
		echo -e "\e[1;31mThis profile (${PROFILE_ID}) does not exist\e[0m"
		exit 1
	fi

	## TODO: check if configured displays in profile are connected.
	## Please see https://github.com/KeyofBlueS/xfce4-display-profile-chooser/issues/1
	#check_connected_displays
	if [[ "${MISSING_DISPLAY}" = '1' ]]; then
		echo -e "\e[1;31mOne or more display in this profile are not connected. Cannot set profile ${PROFILE_ID} - ${PROFILE_NAME}\e[0m"
		exit 1
	fi
	
	xfconf-query --create -c displays -p /Schemes/Apply -t string -s "${PROFILE_ID}"

	exit 0
}

function givemehelp() {

	echo "
# xfce4-display-profile-chooser

# Version:    0.0.3
# Author:     KeyofBlueS
# Repository: https://github.com/KeyofBlueS/xfce4-display-profile-chooser
# License:    GNU General Public License v3.0, https://opensource.org/licenses/GPL-3.0

### DESCRIPTION
With this bash script you can, via command line, list and set already configured display profiles in xfce4-display-settings.
This is usefull if you want e.g. to automate stuff by setting profiles with a script or to use a keyboard shortcut.

### TODO
Prevent the application of a profile that contains one or more displays that are not connected, cause it can lead to a misconfiguration.
Please see https://github.com/KeyofBlueS/xfce4-display-profile-chooser/issues/1

### USAGE

$ xfce4-display-profile-chooser <option> <value>


Options:
-s, --set-profile <profile_id>      Set a profile
-l, --list-profiles                 Show profiles list
-h, --help                          Show this help
"
}

#echo -n "Checking dependencies... "
for bin in xfconf-query awk cat grep; do
	if ! which "${bin}" &>/dev/null; then
		if [[ "${bin}" = 'xfconf-query' ]]; then
			bin="xfconf"
		fi
		if [[ $bin = 'cat' ]]; then
			bin="coreutils"
		fi
		if [[ -z "${missing}" ]]; then
			missing="${bin}"
		else
			missing="${missing} ${bin}"
		fi
	fi
done
if ! [ -z "${missing}" ]; then
	echo -e "\e[1;31mThis script require \e[1;34m"${missing}"\e[1;31m. Use e.g. \e[1;34msudo apt-get install "${missing}"
\e[1;31mInstall the requested dependencies and restart this script.\e[0m"
	exit 1
fi

PROFILES_IDS="$(xfconf-query -l -c displays | awk -F'/' '{print $2}' | uniq | grep -Ev "(ActiveProfile|Default|Fallback|IdentityPopups)")"
ACTIVE_PROFILE="$(xfconf-query -v -l -c displays | grep '/ActiveProfile' | awk '{print $2}')"

## TODO: check if configured displays in profile are connected.
## Please see https://github.com/KeyofBlueS/xfce4-display-profile-chooser/issues/1
MISSING_DISPLAY='0'
#CONNECTED_EDIDS="$(some command to get current connected displays EDID the same way as seen in xconf-query)"

for opt in "$@"; do
	shift
	case "$opt" in
		'--set-profile')		set -- "$@" '-s' ;;
		'--list-profiles')		set -- "$@" '-l' ;;
		'--help')				set -- "$@" '-h' ;;
		*)						set -- "$@" "$opt"
	esac
done

while getopts "s:lh" opt; do
	case ${opt} in
		s ) PROFILE_ID="${OPTARG}"; set_profile
		;;
		l ) list_profiles
		;;
		h ) givemehelp; exit 0
		;;
		*) echo -e "\e[1;31m## ERROR\e[0m"; givemehelp; exit 1
	esac
done

if ((OPTIND == 1))
then
    echo "No options specified"
    givemehelp
    exit 1
fi

exit 0
