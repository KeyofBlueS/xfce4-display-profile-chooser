#!/bin/bash

# xfce4-display-profile-chooser

# Version:    0.0.1
# Author:     KeyofBlueS
# Repository: https://github.com/KeyofBlueS/xfce4-display-profile-chooser
# License:    GNU General Public License v3.0, https://opensource.org/licenses/GPL-3.0

function list_profiles()	{

	for PROFILE_ID in ${PROFILES_ID}; do
		## TODO: check if configured displays in profile are connected.
		#MISSING_DISPLAY='0'
		#PROFILE_EDIDS="$(xfconf-query -v -l -c displays -p /"${PROFILE_ID}" | grep '/EDID ' | awk '{print $2}')"
		#for PROFILE_EDID in ${PROFILE_EDIDS}; do
			#if ! echo "${CONNECTED_EDID}" | grep -q "${PROFILE_EDID}"; then
				#MISSING_DISPLAY='1'
			#fi
		#done
		PROFILE_ID="$(xfconf-query -v -l -c displays -p /"${PROFILE_ID}" | awk 'NR==1{for (i=1;i<=NF;i++) printf("%s ",$i)}')"
		if echo "${PROFILE_ID}" | grep -q "${ACTIVE_PROFILE}"; then
			echo "${PROFILE_ID:1} *(active)"
		#elif [[ "${MISSING_DISPLAY}" = '1' ]]; then
			#echo "${PROFILE_ID:1} #(Displays missing. Cannot set this profile)"
		else
			echo "${PROFILE_ID:1}"
		fi
	done

	exit 0
}

function set_profiles()	{

	if echo "${PROFILE_ID}" | grep -q "${ACTIVE_PROFILE}"; then
		echo "This profile (${PROFILE_ID}) is already set"
		exit 1
	elif ! echo "${PROFILES_ID}" | grep -q "${PROFILE_ID}"; then
		echo "This profile (${PROFILE_ID}) does not exist"
		exit 1
	fi

	## TODO: check if configured displays in profile are connected.
	#PROFILE_EDIDS="$(xfconf-query -v -l -c displays -p /"${PROFILE_ID}" | grep '/EDID ' | awk '{print $2}')"
	#for PROFILE_EDID in ${PROFILE_EDIDS}; do
		#if ! echo "${CONNECTED_EDID}" | grep -q "${PROFILE_EDID}"; then
			#echo "One or more display in this profile are not connected. Cannot set profile ${PROFILE_ID}"
			#exit 1
		#fi
	#done

	xfconf-query --create -c displays -p /Schemes/Apply -t string -s "${PROFILE_ID}"

	exit 0
}

function givemehelp() {

	echo "
# xfce4-display-profile-chooser

# Version:    0.0.1
# Author:     KeyofBlueS
# Repository: https://github.com/KeyofBlueS/xfce4-display-profile-chooser
# License:    GNU General Public License v3.0, https://opensource.org/licenses/GPL-3.0

### DESCRIPTION
With this bash script you can, via command line, list and set already configured display profiles in xfce4-display-settings.
This is usefull if you want e.g. to automate stuff by setting profiles with a script or to use a keyboard shortcut.

### TODO
Prevent the application of a profile that contains one or more displays that are not connected, cause it can lead to a misconfiguration.

### USAGE

$ xfce4-display-profile-chooser <option> <value>


Options:
-s, --set-profiles <profile_id>     Set a profile
-l, --list-profiles                 Show profiles id list
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

PROFILES_ID="$(xfconf-query -l -c displays | awk -F'/' '{print $2}' | uniq | grep -Ev "(ActiveProfile|Default|Fallback|IdentityPopups)")"
ACTIVE_PROFILE="$(xfconf-query -v -l -c displays | grep '/ActiveProfile' | awk '{print $2}')"
## TODO: check if configured displays in profile are connected.
#CONNECTED_EDID="$(some command to get current connected displays EDID the same way as seen in xconf-query)"

for opt in "$@"; do
	shift
	case "$opt" in
		'--set-profiles')		set -- "$@" '-s' ;;
		'--list-profiles')		set -- "$@" '-l' ;;
		'--help')				set -- "$@" '-h' ;;
		*)						set -- "$@" "$opt"
	esac
done

while getopts "s:lh" opt; do
	case ${opt} in
		s ) PROFILE_ID="${OPTARG}"; set_profiles
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
