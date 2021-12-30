#!/bin/bash

# xfce4-display-profile-chooser

# Version:    0.1.1
# Author:     KeyofBlueS
# Repository: https://github.com/KeyofBlueS/xfce4-display-profile-chooser
# License:    GNU General Public License v3.0, https://opensource.org/licenses/GPL-3.0

function check_connected_displays()	{

	## TODO: check if configured displays in profile are connected. Help is needed, please see https://github.com/KeyofBlueS/xfce4-display-profile-chooser/issues/1
	profile_id_check="${1}"
	missing_display='0'
	profile_edids="$(echo "${profiles_ids_prop}" | grep "${profile_id_check}" | grep '/EDID ' | awk '{print $2}')"
	for profile_edid in ${profile_edids}; do
		for connected_edid in ${connected_edids}; do
			if ! echo "${connected_edid}" | grep -xq "${profile_edid}"; then
				missing_display='1'
			fi
		done
	done
}

function list_profiles()	{

	for profiles_id in ${profiles_ids}; do
		profile_name="$(echo "${profiles_ids_prop}" | grep "/${profiles_id}" | awk 'NR==1{for (i=1;i<=NF;i++) printf("%s ",$i)}' | grep -oP '(?<=\ ).*' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g")"
		unset profile_state
		unset profile_color
		if echo "${active_profile_id}" | grep -xq "${profiles_id}"; then
			profile_state=', state: active'
			profile_color='1;32'
		else
			#profile_state=', state: available'
			profile_state=''
			profile_color='2;32'
		fi

		## TODO: check if configured displays in profile are connected. Help is needed, please see https://github.com/KeyofBlueS/xfce4-display-profile-chooser/issues/1
		#check_connected_displays "${profiles_id}"
		if [[ "${missing_display}" = '1' ]]; then
			profile_state=', state: not available'
			profile_color='1;31'
		fi

		echo -e "\e[${profile_color}mid: ${profiles_id}, name: ${profile_name::-1}${profile_state}\e[0m"
		if [[ "${verbose}" = 'true' ]]; then
			list_profiles_verbose
		fi
	done
}

function list_profiles_verbose()	{

	profile_outputs="$(echo "${profiles_ids_prop}" | grep "${profiles_id}" | grep '/EDID ' | awk -F'/' '{print $3}')"
	for profile_output in ${profile_outputs}; do
		profile_output_prop="$(echo "${profiles_ids_prop}" | grep "/${profiles_id}/${profile_output}")"

		name="$(echo "${profile_output_prop}" | grep "${profile_output} " | awk 'NR==1{for (i=1;i<=NF;i++) printf("%s ",$i)}' | grep -oP '(?<=\ ).*')"
		edid="$(echo "${profile_output_prop}" | grep '/EDID ' | awk '{print $2}')"
		active="$(echo "${profile_output_prop}" | grep '/Active ' | awk '{print $2}')"
		position_X="$(echo "${profile_output_prop}" | grep '/Position/X ' | awk '{print $2}')"
		position_Y="$(echo "${profile_output_prop}" | grep '/Position/Y ' | awk '{print $2}')"
		primary="$(echo "${profile_output_prop}" | grep '/Primary ' | awk '{print $2}')"
		reflection="$(echo "${profile_output_prop}" | grep '/Reflection ' | awk '{print $2}')"
		refreshrate="$(echo "${profile_output_prop}" | grep '/RefreshRate ' | awk '{print $2}')"
		resolution="$(echo "${profile_output_prop}" | grep '/Resolution ' | awk '{print $2}')"
		rotation="$(echo "${profile_output_prop}" | grep '/Rotation ' | awk '{print $2}')"
		scale_X="$(echo "${profile_output_prop}" | grep '/Scale/X ' | awk '{print $2}')"
		scale_Y="$(echo "${profile_output_prop}" | grep '/Scale/Y ' | awk '{print $2}')"

		echo "output=${profile_output}"
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

function set_profile() {

	echo
	unset error
	profile_name="$(echo "${profiles_ids_prop}" | grep "/${profile_id}" | awk 'NR==1{for (i=1;i<=NF;i++) printf("%s ",$i)}' | grep -oP '(?<=\ ).*' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g")"
	if echo "${active_profile_id}" | grep -xq "${profile_id}"; then
		echo -e "\e[1;33mProfile ${profile_id} - ${profile_name} was already set\e[0m"
		error=1
	fi

	exist=0
	for profiles_id in ${profiles_ids}; do
		if echo "${profiles_id}" | grep -xq "${profile_id}"; then
			exist=1
		fi
	done
	if [[ "${exist}" = '0' ]]; then
		echo -e "\e[1;31mProfile id ${profile_id} does not exist\e[0m"
		error=1
	fi

	## TODO: check if configured displays in profile are connected. Help is needed, please see https://github.com/KeyofBlueS/xfce4-display-profile-chooser/issues/1
	#check_connected_displays "${profile_id}"
	if [[ "${missing_display}" = '1' ]]; then
		set_profile_error
		error=1
	fi

	if [[ "${error}" != '1' ]]; then
		xfconf-query --create -c displays -p /Schemes/Apply -t string -s "${profile_id}"
		echo -e "\e[2;32mProfile ${profile_id} - ${profile_name} is set\e[0m"
	fi
}

function set_profile_error() {

	echo -e "\e[1;31mOne or more display in this profile are not connected. Cannot set profile ${profile_id} - ${profile_name}\e[0m"
}

function yad_chooser() {

	ycommopt='--title=xfce4-display-profile-chooser --center --image-on-top --wrap --sticky --on-top --buttons-layout=spread'

	yad_check_error

	while true; do
		inizialize
		unset verbose
		profiles="$(list_profiles | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g")"
		profiles_names="$(echo "${profiles}" | awk -F'name: ' '{print $2}' | sort)"
		while IFS= read -r profiles_name; do
			if [[ -z "${profiles_list}" ]]; then
				profiles_list="${profiles_name}"
			else
				profiles_list="${profiles_list}!${profiles_name}"
			fi
		done <<< "${profiles_names}"

		active_profile_name="$(echo "${profiles_names}" | grep 'state: active')"

		profile="$(yad ${ycommopt} --window-icon "xfce-display-external" --image "avatar-default" --text="Current: ${active_profile_name}" --form --field="Profile:CB" "${profiles_list}" --button="Exit"!exit!Exit:99 \
		--button="Help"!help-about!"Show help":98 \
		--button="Info"!user-info!"Show profiles info":97 \
		--button="Display"!org.xfce.settings.display!"Open xfce4-display-settings":96 \
		--button="Refresh"!view-refresh!"Refresh profiles list":95 \
		--button="Set Profile"!dialog-apply!"Set selected profile":0)"
		profile_choice="${?}"
		if [[ "${profile_choice}" -eq 99 ]]; then
			exit 0
		elif [[ "${profile_choice}" -eq 98 ]]; then
			yad_help
		elif [[ "${profile_choice}" -eq 97 ]]; then
			yad_verbose
		elif [[ "${profile_choice}" -eq 96 ]]; then
			xfce4-display-settings
		elif [[ "${profile_choice}" -eq 95 ]]; then
			true
		elif [[ "${profile_choice}" -eq 0 ]]; then
		profile="$(echo "${profile}" | awk -F'|' '{print $1}')"
			profile_id="$(echo "${profiles}" | grep "${profile}" | awk '{print $2}' | awk -F',' '{print $1}')"
			set_profile
			if [[ "${missing_display}" = '1' ]]; then
				error_text="$(set_profile_error | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g")"
				yad_show_error
			fi
			if [[ "${error}" != '1' ]]; then
				sleep 1.5
			fi
		else
			exit 0
		fi

		unset profiles_list
	done
}

function yad_help() {

		info="$(givemehelp)"
		echo "$info" | \
		yad ${ycommopt} --window-icon "xfce-display-external" --image "help-about" --text="Help" --width=900 --height=500 --text-info --button="Exit"!exit!Exit:99 \
		--button="Go Back"!back!"Go back to profile selection menu":98
		info_choice="${?}"
		if [ "${info_choice}" -eq 99 ]; then
			exit 0
		elif [ "${info_choice}" -eq 98 ]; then
			true
		else
			exit 0
		fi
}

function yad_verbose() {

	while true; do
		verbose='true'
		info="$(list_profiles | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g")"
		echo "$info" | \
		yad ${ycommopt} --window-icon "xfce-display-external" --image "user-info" --text="Profiles info:" --width=900 --height=500 --text-info --button="Exit"!exit!Exit:99 \
		--button="Refresh"!view-refresh!"Refresh profiles info":98 \
		--button="Go Back"!back!"Go back to profile selection menu":97
		info_choice="${?}"
		if [ "${info_choice}" -eq 99 ]; then
			exit 0
		elif [ "${info_choice}" -eq 98 ]; then
			true
		elif [ "${info_choice}" -eq 97 ]; then
			break
		else
			exit 0
		fi
	done
}

function yad_check_error() {

	check_dependencies
	if [[ "${gui_error}" = '1' ]]; then
		dependencies_error
		exit 1
	elif [[ "${commline_error}" = '1' ]]; then
		error_text="$(dependencies_error | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g")"
		yad_show_error
		exit 1
	fi

	check_xfce
	if [[ "${not_xfce}" = '1' ]]; then
		error_text="$(xfce_error | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g")"
		yad_show_error
		exit 1
	fi
}

function yad_show_error() {

	echo "$error_text" | \
	yad ${ycommopt} --window-icon "xfce-display-external" --image "dialog-error" --text="Dependancies error:" --width=900 --height=200 --text-info --button="Exit"!exit!Exit:99
}

function check_dependencies() {

	commline_bins='xfconf-query awk cat grep'
	gui_bins='yad xfce4-display-settings'
	for bin in ${commline_bins} ${gui_bins}; do
		if ! command -v "${bin}" &>/dev/null; then
			if [[ "${bin}" = 'xfconf-query' ]]; then
				bin="xfconf"
			fi
			if [[ $bin = 'cat' ]]; then
				bin="coreutils"
			fi
			if [[ $bin = 'xfce4-display-settings' ]]; then
				bin="xfce4-settings"
			fi
			if [[ -z "${missing}" ]]; then
				missing="${bin}"
			else
				missing="${missing} ${bin}"
			fi
		fi
	done

	for commline_bin in ${commline_bins}; do
		if echo "${missing}" | grep -q "${commline_bin}"; then
			commline_error='1'
		fi
	done

	for gui_bin in ${gui_bins}; do
		if echo "${missing}" | grep -q "${gui_bin}"; then
			gui_error='1'
		fi
	done
}

function dependencies_error() {

	if [[ "${commline_error}" = '1' ]]; then
		echo -e "\e[1;31mERROR: This script require \e[1;34m${missing}\e[1;31m. Use e.g. \e[1;34msudo apt-get install ${missing}"
		echo -e "\e[1;31mInstall the requested dependencies and restart this script.\e[0m"
		echo
	fi

	if [[ "${gui_error}" = '1' ]]; then
		echo -e "\e[1;33mWARNING: This script require \e[1;34m${missing}\e[1;33m for the GUI. Use e.g. \e[1;34msudo apt-get install ${missing}"
		echo -e "\e[1;33mInstall the requested dependencies and restart this script.\e[0m"
		echo
	fi
}

function check_xfce() {

	if ! echo "${XDG_CURRENT_DESKTOP}" | grep -iq 'xfce'; then
		not_xfce='1'
	fi
}

function xfce_error() {

	echo -e "\e[1;31mERROR: This program is intended to manage XFCE Display Profiles.\e[0m"
	echo -e "\e[1;31mIt seems you are not in an XFCE Session.\e[0m"
}

function inizialize() {

	profiles_ids_prop="$(xfconf-query -v -l -c displays)"
	profiles_ids="$(echo "${profiles_ids_prop}" | awk -F'/' '{print $2}' | awk '{print $1}' | uniq | grep -Ev "(ActiveProfile|Default|Fallback|IdentityPopups)")"
	active_profile_id="$(echo "${profiles_ids_prop}" | grep '/ActiveProfile' | awk '{print $2}')"

	## TODO: check if configured displays in profile are connected. Help is needed, please see https://github.com/KeyofBlueS/xfce4-display-profile-chooser/issues/1
	#CONNECTED_EDIDS="$(some command to get current connected displays EDID the same way as seen in xconf-query)"
}

function givemehelp() {

	echo "
# xfce4-display-profile-chooser

# Version:    0.1.1
# Author:     KeyofBlueS
# Repository: https://github.com/KeyofBlueS/xfce4-display-profile-chooser
# License:    GNU General Public License v3.0, https://opensource.org/licenses/GPL-3.0

### DESCRIPTION
With this bash script you can, via command line, list and set already configured display profiles in xfce4-display-settings.
This is useful if you want e.g. to automate stuff by setting profiles with a script or to use a keyboard shortcut.
A graphical user interface is provided with the use of yad.

### TODO
Prevent the application of a profile that contains one or more displays that are not connected, cause it can lead to a misconfiguration.
Help is needed, please see https://github.com/KeyofBlueS/xfce4-display-profile-chooser/issues/1

### USAGE

$ xfce4-display-profile-chooser <option> <value>


Options:
-s, --set-profile <profile_id>      Set a profile
-l, --list-profiles                 Show profiles list
-v, --list-verbose                  Show profiles list with additional info
-g, --gui                           Start a graphical user interface
-h, --help                          Show this help
"
}

for opt in "$@"; do
	shift
	case "$opt" in
		'--set-profile')		set -- "$@" '-s' ;;
		'--list-profiles')		set -- "$@" '-l' ;;
		'--list-verbose')		set -- "$@" '-v' ;;
		'--gui')				set -- "$@" '-g' ;;
		'--help')				set -- "$@" '-h' ;;
		*)						set -- "$@" "$opt"
	esac
done

while getopts "s:lvgh" opt; do
	case ${opt} in
		s ) profile_id="${OPTARG}"; actions="${actions} set_profile"
		;;
		l ) actions="${actions} list_profiles"
		;;
		v ) verbose='true'; actions="${actions} list_profiles"
		;;
		g ) actions="${actions} yad_chooser"
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

if echo "${actions}" | grep -q 'yad_chooser'; then
	yad_chooser
	exit 0
fi

check_dependencies
if [[ "${commline_error}" = '1' ]]; then
	dependencies_error
	exit 1
fi

check_xfce
if [[ "${not_xfce}" = '1' ]]; then
	xfce_error
	exit 1
fi

inizialize

if echo "${actions}" | grep -q 'list_profiles'; then
	list_profiles
fi
if echo "${actions}" | grep -q 'set_profile'; then
	set_profile
fi

if [[ "${error}" = '1' ]]; then
	exit 1
else
	exit 0
fi
