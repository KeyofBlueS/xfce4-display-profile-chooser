#!/bin/bash

# xfce4-display-profile-chooser

# Version:    0.0.5
# Author:     KeyofBlueS
# Repository: https://github.com/KeyofBlueS/xfce4-display-profile-chooser
# License:    GNU General Public License v3.0, https://opensource.org/licenses/GPL-3.0

function check_connected_displays()	{
	## TODO: check if configured displays in profile are connected. Please see https://github.com/KeyofBlueS/xfce4-display-profile-chooser/issues/1
	PROFILE_ID_CHECK="${1}"
	MISSING_DISPLAY='0'
	PROFILE_EDIDS="$(echo "${PROFILES_IDS_PROP}" | grep "${PROFILE_ID_CHECK}" | grep '/EDID ' | awk '{print $2}')"
	for PROFILE_EDID in ${PROFILE_EDIDS}; do
		for CONNECTED_EDID in ${CONNECTED_EDIDS}; do
			if ! echo "${CONNECTED_EDID}" | grep -xq "${PROFILE_EDID}"; then
				MISSING_DISPLAY='1'
			fi
		done
	done
}

function list_profiles()	{

	for PROFILES_ID in ${PROFILES_IDS}; do
		PROFILE_NAME="$(echo "${PROFILES_IDS_PROP}" | grep "/${PROFILES_ID}" | awk 'NR==1{for (i=1;i<=NF;i++) printf("%s ",$i)}' | grep -oP '(?<=\ ).*')"
		unset PROFILE_STATE
		unset PROFILE_COLOR
		if echo "${ACTIVE_PROFILE}" | grep -xq "${PROFILES_ID}"; then
			PROFILE_STATE=', state: active'
			PROFILE_COLOR='1;32'
		else
			#PROFILE_STATE=', state: available'
			PROFILE_STATE=''
			PROFILE_COLOR='2;32'
		fi

		## TODO: check if configured displays in profile are connected. Please see https://github.com/KeyofBlueS/xfce4-display-profile-chooser/issues/1
		#check_connected_displays "${PROFILES_ID}"
		if [[ "${MISSING_DISPLAY}" = '1' ]]; then
			PROFILE_STATE=', state: Display/s missing, cannot set this profile'
			PROFILE_COLOR='1;31'
		fi

		echo -e "\e[${PROFILE_COLOR}mid: ${PROFILES_ID}, name: ${PROFILE_NAME:0:-1}${PROFILE_STATE}\e[0m"
		if [[ "${VERBOSE}" = 'true' ]]; then
			list_profiles_verbose
		fi
	done
}

function list_profiles_verbose()	{

	PROFILE_OUTPUTS="$(echo "${PROFILES_IDS_PROP}" | grep "${PROFILES_ID}" | grep '/EDID ' | awk -F'/' '{print $3}')"
	for PROFILE_OUTPUT in ${PROFILE_OUTPUTS}; do
		PROFILE_OUTPUT_PROP="$(echo "${PROFILES_IDS_PROP}" | grep "/${PROFILES_ID}/${PROFILE_OUTPUT}")"

		name="$(echo "${PROFILE_OUTPUT_PROP}" | grep "${PROFILE_OUTPUT} " | awk 'NR==1{for (i=1;i<=NF;i++) printf("%s ",$i)}' | grep -oP '(?<=\ ).*')"
		edid="$(echo "${PROFILE_OUTPUT_PROP}" | grep '/EDID ' | awk '{print $2}')"
		active="$(echo "${PROFILE_OUTPUT_PROP}" | grep '/Active ' | awk '{print $2}')"
		position_X="$(echo "${PROFILE_OUTPUT_PROP}" | grep '/Position/X ' | awk '{print $2}')"
		position_Y="$(echo "${PROFILE_OUTPUT_PROP}" | grep '/Position/Y ' | awk '{print $2}')"
		primary="$(echo "${PROFILE_OUTPUT_PROP}" | grep '/Primary ' | awk '{print $2}')"
		reflection="$(echo "${PROFILE_OUTPUT_PROP}" | grep '/Reflection ' | awk '{print $2}')"
		refreshrate="$(echo "${PROFILE_OUTPUT_PROP}" | grep '/RefreshRate ' | awk '{print $2}')"
		resolution="$(echo "${PROFILE_OUTPUT_PROP}" | grep '/Resolution ' | awk '{print $2}')"
		rotation="$(echo "${PROFILE_OUTPUT_PROP}" | grep '/Rotation ' | awk '{print $2}')"
		scale_X="$(echo "${PROFILE_OUTPUT_PROP}" | grep '/Scale/X ' | awk '{print $2}')"
		scale_Y="$(echo "${PROFILE_OUTPUT_PROP}" | grep '/Scale/Y ' | awk '{print $2}')"

		echo "output=${PROFILE_OUTPUT}"
		echo "name=${name}"
		echo "edid=${edid}"
		echo "active=${active}"
		echo "position_X=${position_X}"
		echo "position_Y=${position_Y}"
		echo "primary=${primary}"
		echo "reflection=${reflection}"
		echo "refreshrate=${refreshrate}"
		echo "resolution=${resolution}"
		echo "rotation=${rotation}"
		echo "scale_X=${scale_X}"
		echo "scale_Y=${scale_Y}"
		echo
	done
}

function set_profile()	{

	echo
	PROFILE_NAME="$(echo "${PROFILES_IDS_PROP}" | grep "/${PROFILE_ID}" | awk 'NR==1{for (i=1;i<=NF;i++) printf("%s ",$i)}' | grep -oP '(?<=\ ).*')"
	if echo "${ACTIVE_PROFILE}" | grep -xq "${PROFILE_ID}"; then
		echo -e "\e[1;33mProfile ${PROFILE_ID} - ${PROFILE_NAME:0:-1} was already set\e[0m"
		exit 1
	fi
	
	EXIST=0
	for PROFILES_ID in ${PROFILES_IDS}; do
		if echo "${PROFILES_ID}" | grep -xq "${PROFILE_ID}"; then
			EXIST=1
		fi
	done
	if [[ "${EXIST}" = '0' ]]; then
		echo -e "\e[1;31mProfile id ${PROFILE_ID} does not exist\e[0m"
		exit 1
	fi

	## TODO: check if configured displays in profile are connected. Please see https://github.com/KeyofBlueS/xfce4-display-profile-chooser/issues/1
	MISSING_DISPLAY=0
	#check_connected_displays "${PROFILE_ID}"
	if [[ "${MISSING_DISPLAY}" = '1' ]]; then
		echo -e "\e[1;31mOne or more display in this profile are not connected. Cannot set profile ${PROFILE_ID} - ${PROFILE_NAME}\e[0m"
		exit 1
	fi
	
	xfconf-query --create -c displays -p /Schemes/Apply -t string -s "${PROFILE_ID}"
	echo -e "\e[2;32mProfile ${PROFILE_ID} - ${PROFILE_NAME:0:-1} is set\e[0m"
}

function givemehelp() {

	echo "
# xfce4-display-profile-chooser

# Version:    0.0.5
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
-v, --list-verbose                  Show profiles list with additional info
-h, --help                          Show this help
"
}

for bin in xfconf-query awk cat grep; do
	if ! command -v "${bin}" &>/dev/null; then
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

PROFILES_IDS_PROP="$(xfconf-query -v -l -c displays)"
PROFILES_IDS="$(echo "${PROFILES_IDS_PROP}" | awk -F'/' '{print $2}' | awk '{print $1}' | uniq | grep -Ev "(ActiveProfile|Default|Fallback|IdentityPopups)")"
ACTIVE_PROFILE="$(echo "${PROFILES_IDS_PROP}" | grep '/ActiveProfile' | awk '{print $2}')"

## TODO: check if configured displays in profile are connected. Please see https://github.com/KeyofBlueS/xfce4-display-profile-chooser/issues/1
#CONNECTED_EDIDS="$(some command to get current connected displays EDID the same way as seen in xconf-query)"

for opt in "$@"; do
	shift
	case "$opt" in
		'--set-profile')		set -- "$@" '-s' ;;
		'--list-profiles')		set -- "$@" '-l' ;;
		'--list-verbose')		set -- "$@" '-v' ;;
		'--help')				set -- "$@" '-h' ;;
		*)						set -- "$@" "$opt"
	esac
done

while getopts "s:lvh" opt; do
	case ${opt} in
		s ) PROFILE_ID="${OPTARG}"; actions="${actions} set_profile"
		;;
		l ) actions="${actions} list_profiles"
		;;
		v ) VERBOSE='true'; actions="${actions} list_profiles"
		;;
		h ) givemehelp; exit 0
		;;
		*) echo -e "\e[1;31m## ERROR\e[0m"; givemehelp; exit 1
	esac
done

if ((OPTIND == 1))
then
    actions="${actions} list_profiles"
fi

if echo "${actions}" | grep -q 'list_profiles'; then
	list_profiles
fi
if echo "${actions}" | grep -q 'set_profile'; then
	set_profile
fi
exit 0
