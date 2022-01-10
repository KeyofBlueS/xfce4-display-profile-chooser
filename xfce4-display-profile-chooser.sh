#!/bin/bash

# xfce4-display-profile-chooser

# Version:    0.2.0
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

function get_profile_name() {

	get_name="${1}"
	if [[ "${get_name}" = 'Default' || "${get_name}" = 'Fallback' ]]; then
		echo "${get_name}"
	else
		echo "${profiles_ids_prop}" | grep "/${get_name}" | awk 'NR==1{for (i=1;i<=NF;i++) printf("%s ",$i)}' | grep -oP '(?<=\ ).*' | sed 's/ $//' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g"
	fi
}

function list_profiles() {

	first_profile_item='0'
	for profiles_id in ${profiles_ids}; do
		profile_name="$(get_profile_name "${profiles_id}")"
		if [[ "${profiles_id}" = 'Default' ]] && [[ "${default_profile}" != 'true' ]]; then
			continue
		elif [[ "${profiles_id}" = 'Fallback' ]] && [[ "${fallback_profile}" != 'true' ]]; then
			continue
		fi
		if [[ "${active_profile_id}" = "${profiles_id}" ]]; then
			list_verbose_profiles "${profiles_id}" check_active
			if [[ "${active_profile_state}" != '1' ]]; then
				profile_state=', state: set; active'
				profile_color='1;32'
			else
				profile_state=', state: set; not active'
				profile_color='1;33'
			fi
		else
			## TODO: check if configured displays in profile are connected. Help is needed, please see https://github.com/KeyofBlueS/xfce4-display-profile-chooser/issues/1
			#check_connected_displays "${profiles_id}"
			if [[ "${missing_display}" = '1' ]]; then
				if [[ "${unavailable_profile}" != 'true' ]]; then
					continue
				fi
				profile_state=', state: not available'
				profile_color='1;31'
			else
				#profile_state=', state: available'
				profile_state=''
				profile_color='2;32'
			fi
		fi
		if [[ "${verbose}" = 'true' ]]; then
			first_profile_item="$(("${first_profile_item}" + 1))"
			list_verbose_profiles "${profiles_id}" show_verbose
		else
			echo -e "\e[${profile_color}mid: ${profiles_id}, name: ${profile_name}${profile_state}\e[0m"
		fi
	done
}

function list_verbose_profiles() {

	get_verbose="${1}"
	action_verbose="${2}"

	if [[ "${action_verbose}" = 'show_verbose' ]]; then
		if [[ "${first_profile_item}" -ge '2' ]]; then
			echo
			echo '-----------------------------------------------------------------'
			echo
		fi
		echo -e "\e[${profile_color}mid: ${get_verbose}, name: ${profile_name}${profile_state}\e[0m"
	elif [[ "${action_verbose}" = 'check_active' ]]; then
		xrandr_prop="$(xrandr)"
		active_profile_state='0'
	fi

	profile_outputs="$(echo "${profiles_ids_prop}" | grep "${get_verbose}" | grep '/EDID ' | awk -F'/' '{print $3}')"
	for profile_output in ${profile_outputs}; do
		profile_output_prop="$(echo "${profiles_ids_prop}" | grep "/${get_verbose}/${profile_output}")"

		name="$(echo "${profile_output_prop}" | grep "${profile_output} " | awk 'NR==1{for (i=1;i<=NF;i++) printf("%s ",$i)}' | grep -oP '(?<=\ ).*' | sed 's/ $//')"
		edid="$(echo "${profile_output_prop}" | grep '/EDID ' | awk '{print $2}')"
		active="$(echo "${profile_output_prop}" | grep '/Active ' | awk '{print $2}')"
		position_x="$(echo "${profile_output_prop}" | grep '/Position/X ' | awk '{print $2}')"
		position_y="$(echo "${profile_output_prop}" | grep '/Position/Y ' | awk '{print $2}')"
		primary="$(echo "${profile_output_prop}" | grep '/Primary ' | awk '{print $2}')"
		reflection="$(echo "${profile_output_prop}" | grep '/Reflection ' | awk '{print $2}')"
		refreshrate="$(echo "${profile_output_prop}" | grep '/RefreshRate ' | awk '{print $2}')"
		resolution="$(echo "${profile_output_prop}" | grep '/Resolution ' | awk '{print $2}')"
		rotation="$(echo "${profile_output_prop}" | grep '/Rotation ' | awk '{print $2}')"
		scale_x="$(echo "${profile_output_prop}" | grep '/Scale/X ' | awk '{print $2}')"
		scale_y="$(echo "${profile_output_prop}" | grep '/Scale/Y ' | awk '{print $2}')"

		if [[ "${action_verbose}" = 'show_verbose' ]]; then
			show_verbose_profiles
		elif [[ "${action_verbose}" = 'check_active' ]]; then
			check_active_profile
			if [[ "${active_profile_state}" = '1' ]]; then
				break
			fi
		fi
	done
	if [[ "${action_verbose}" = 'show_verbose' ]]; then
		echo
		echo 'xrand command to set this profile:'
		echo "xrandr${xrandr_command}"
		unset xrandr_command
	fi
	unset action_verbose
}

function show_verbose_profiles() {

		echo
		echo "Output=${profile_output}"
		echo "Name=${name}"
		echo "EDID=${edid}"
		echo "Active=${active}"
		if [[ "${active}" = 'true' || "${get_verbose}" = 'Default' || "${get_verbose}" = 'Fallback' ]]; then
			echo "Position_X=${position_x}"
			echo "Position_Y=${position_y}"
			echo "Primary=${primary}"
			echo "Reflection=${reflection}"
			echo "RefreshRate=${refreshrate}"
			echo "Resolution=${resolution}"
			echo "Rotation=${rotation}"
			echo "Scale_X=${scale_x}"
			echo "Scale_Y=${scale_y}"
		fi

		while IFS= read -r xrandr_opt; do
			xrandr_command="${xrandr_command} ${xrandr_opt}"
		done <<< "$(xrandr_options)"
}

function xrandr_options() {

	get_xrandr_variables

	echo "--output ${xrandr_output}"
	if [[ -n "${xrandr_active}" ]]; then
		echo "--off"
	else
		if [[ -n "${xrandr_primary}" ]]; then
			echo "--primary"
		fi
		echo "--mode ${xrandr_resolution}"
		echo "--rate ${xrandr_refreshrate}"
		echo "--pos ${xrandr_position_x}x${xrandr_position_y}"
		echo "--rotate ${xrandr_rotation}"
		echo "--reflect ${xrandr_reflection}"
		echo "--scale ${xrandr_scale_x}x${xrandr_scale_y}"
	fi
}

function get_xrandr_variables() {

	unset xrandr_output
	unset xrandr_active
	unset xrandr_primary
	unset xrandr_resolution
	unset xrandr_refreshrate
	unset xrandr_position
	unset xrandr_rotation
	unset xrandr_reflection
	unset xrandr_scale

	xrandr_output="${profile_output}"
	if [[ "${active}" = 'false' ]]; then
		xrandr_active='connected'
	fi
	if [[ -n "${position_x}" ]]; then
		xrandr_position_x="${position_x}"
	fi
	if [[ -n "${position_y}" ]]; then
		xrandr_position_y="${position_y}"
	fi
	if [[ -n "${primary}" ]]; then
		if [[ "${primary}" = 'true' ]]; then
			xrandr_primary='primary'
		fi
	fi
	if [[ -n "${reflection}" ]]; then
		if [[ "${reflection}" = '0' ]]; then
			xrandr_reflection="normal"
		else
			xrandr_reflection="${reflection,,}"
		fi
	fi
	if [[ -n "${refreshrate}" ]]; then
		xrandr_refreshrate="${refreshrate}"
	fi
	if [[ -n "${resolution}" ]]; then
		xrandr_resolution="${resolution}"
	fi
	if [[ -n "${rotation}" ]]; then
		if [[ "${rotation}" = '0' ]]; then
			xrandr_rotation="normal"
		elif [[ "${rotation}" = '90' ]]; then
			xrandr_rotation="left"
		elif [[ "${rotation}" = '180' ]]; then
			xrandr_rotation="inverted"
		elif [[ "${rotation}" = '270' ]]; then
			xrandr_rotation="right"
		fi
	fi
	if [[ -n "${scale_x}" ]]; then
		xrandr_scale_x="${scale_x//,/$'.'}"
	fi
	if [[ -n "${scale_y}" ]]; then
		xrandr_scale_y="${scale_y//,/$'.'}"
	fi
}

function check_active_profile() {

	get_xrandr_variables
	if [[ "${xrandr_active}" = 'connected' ]]; then
		xrandr_grep="${xrandr_output} ${xrandr_active}"
		if ! echo "${xrandr_prop}" | grep -q "${xrandr_grep} ("; then
			active_profile_state='1'
		fi
	else
		if [[ -n "${xrandr_primary}" ]]; then
			xrandr_primary_state="${xrandr_primary}"
		fi
		if [[ "${xrandr_rotation}" = 'left' || "${xrandr_rotation}" = 'right' ]]; then
			xrandr_resolution_state="$(echo "${resolution}" | awk -F'x' '{print $2}')x$(echo "${resolution}" | awk -F'x' '{print $1}')"
		else
			xrandr_resolution_state="${resolution}"
		fi
		xrandr_resolution_state="$(perl -e "print "$(echo "${xrandr_resolution_state}" | awk -F'x' '{print $1}')" * "${xrandr_scale_x}"")x$(perl -e "print "$(echo "${xrandr_resolution_state}" | awk -F'x' '{print $2}')" * "${xrandr_scale_y}"")"
		xrandr_position_state="${xrandr_position_x}+${xrandr_position_y}"
		if [[ "${xrandr_rotation}" != 'normal' ]]; then
			xrandr_rotation_state="${xrandr_rotation}"
		fi
		if [[ "${xrandr_reflection}" != 'normal' ]]; then
			if [[ "${xrandr_reflection}" = 'x' || "${xrandr_reflection}" = 'y' ]]; then
				xrandr_reflection_state="${xrandr_reflection^^} axis"
			elif [[ "${xrandr_reflection}" = 'xy' ]]; then
				xrandr_reflection_state="X and Y axis"
			fi
		fi
		xrandr_refreshrate_state="${xrandr_refreshrate::-4}"
		xrandr_refreshrate_state="${xrandr_refreshrate_state//,/$'.'}"

		unset xrandr_grep
		for xrandr_state in ${xrandr_output} connected ${xrandr_primary_state} ${xrandr_resolution_state}+${xrandr_position_state} ${xrandr_rotation_state} ${xrandr_reflection_state}; do
			if [[ -z "${xrandr_grep}" ]]; then
				xrandr_grep="${xrandr_state}"
			else
				xrandr_grep="${xrandr_grep} ${xrandr_state}"
			fi
		done

		export xrandr_prop
		export xrandr_output
		xrandr_output_prop="$(perl -E '$_ = qx/echo "$ENV{xrandr_prop}"/; for (split /^(?!\s)/sm) { chomp; say if /^\S*$ENV{xrandr_output} /; }')"
		if ! echo "${xrandr_output_prop}" | grep -q "${xrandr_grep} ("; then
			active_profile_state='1'
		else
			if ! echo "${xrandr_output_prop}" | grep -q " ${xrandr_refreshrate_state}\*"; then
				active_profile_state='1'
			fi
		fi
	fi
}

function set_profile() {

	if echo "${actions}" | grep -q 'list_profiles'; then
		echo
		if [[ "${verbose}" = 'true' ]]; then
			echo '-----------------------------------------------------------------'
			echo
		fi
	fi
	unset error
	profile_name="$(get_profile_name "${profile_id}")"

	if [[ "${active_profile_id}" = "${profile_id}" ]]; then
		list_verbose_profiles "${profile_id}" check_active
		if [[ "${active_profile_state}" != '1' ]]; then
			echo -e "\e[1;33mProfile ${profile_id} - ${profile_name} is already active\e[0m"
			error='1'
		fi
	fi

	exist='0'
	for profiles_id in ${profiles_ids}; do
		if echo "${profiles_id}" | grep -xq "${profile_id}"; then
			exist='1'
		fi
	done
	if [[ "${exist}" = '0' ]]; then
		echo -e "\e[1;31mProfile id ${profile_id} does not exist\e[0m"
		error='1'
	fi

	## TODO: check if configured displays in profile are connected. Help is needed, please see https://github.com/KeyofBlueS/xfce4-display-profile-chooser/issues/1
	#check_connected_displays "${profile_id}"
	if [[ "${missing_display}" = '1' ]]; then
		set_profile_error
		error='1'
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

	ycommopt='--always-print-result --title=xfce4-display-profile-chooser --center --image-on-top --wrap --buttons-layout=spread'

	yad_check_error

	while true; do
		if pgrep -a yad | grep -q "title=xfce4-display-profile-chooser"; then
			wmctrl -FR "xfce4-display-profile-chooser"
			echo -e "\e[1;33mWARNING: Another instance of xfce4-display-profile-chooser is running."
			exit 0
		fi

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

		active_profile_name="$(echo "${profiles_names}" | grep 'state: set')"

		#profile_yad="$(yad ${ycommopt} --window-icon "xfce-display-external" --image "avatar-default" --text="Current profile: ${active_profile_name}" --form --field="Profile:CB" "${profiles_list}" --field="Show Default profile":chk "${default_profile}" --field="Show Fallback profile":chk "${fallback_profile}" --field="Show unavailable profiles":chk "${unavailable_profile}" --button="Exit"!exit!Exit:99 
		profile_yad="$(yad ${ycommopt} --window-icon "xfce-display-external" --image "avatar-default" --text="Current profile: ${active_profile_name}" --form --field="Profile:CB" "${profiles_list}" --field="Show Default profile":chk "${default_profile}" --field="Show Fallback profile":chk "${fallback_profile}" --button="Exit"!exit!Exit:99 \
		--button="Help"!help-about!"Show help":98 \
		--button="Info"!user-info!"Show profiles info":97 \
		--button="Display"!org.xfce.settings.display!"Open xfce4-display-settings":96 \
		--button="Refresh"!view-refresh!"Refresh profiles list":95 \
		--button="Set profile"!dialog-apply!"Set selected profile":94)"
		profile_choice="${?}"
		default_profile="$(echo "${profile_yad}" | awk -F'|' '{print $2}' | tr '[:upper:]' '[:lower:]')"
		fallback_profile="$(echo "${profile_yad}" | awk -F'|' '{print $3}' | tr '[:upper:]' '[:lower:]')"
		#unavailable_profile="$(echo "${profile_yad}" | awk -F'|' '{print $4}' | tr '[:upper:]' '[:lower:]')"
		if [[ "${profile_choice}" -eq '99' ]]; then
			exit 0
		elif [[ "${profile_choice}" -eq '98' ]]; then
			yad_help
		elif [[ "${profile_choice}" -eq '97' ]]; then
			yad_verbose
		elif [[ "${profile_choice}" -eq '96' ]]; then
			xfce4-display-settings
		elif [[ "${profile_choice}" -eq '95' ]]; then
			true
		elif [[ "${profile_choice}" -eq '94' ]]; then
			profile="$(echo "${profile_yad}" | awk -F'|' '{print $1}')"
			profile_id="$(echo "${profiles}" | grep "${profile}" | awk '{print $2}' | awk -F',' '{print $1}')"
			set_profile
			if [[ "${missing_display}" = '1' ]]; then
				error_text="$(set_profile_error | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g")"
				yad_show_error
			fi
		else
			exit 0
		fi
		unset profiles_list
	done
}

function yad_help() {

	info_help="$(givemehelp)"
	help_yad="$(yad ${ycommopt} --window-icon "xfce-display-external" --image "help-about" --text="Help" --width=900 --height=500 --text-info <<<"${info_help}" --button="Exit"!exit!Exit:99 \
	--button="Go back"!back!"Go back to profile selection menu":98)"
	info_choice="${?}"
	if [[ "${info_choice}" -eq '99' ]]; then
		exit 0
	elif [[ "${info_choice}" -eq '98' ]]; then
		true
	else
		exit 0
	fi
}

function yad_verbose() {

	while true; do
		verbose='true'
		inizialize
		info_verbose="$(list_profiles | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g")"
		#verbose_yad="$(yad ${ycommopt} --window-icon "xfce-display-external" --width=900 --height=800 --form --field="Profiles info:":txt "${info_verbose}" --field="Show Default profile":chk "${default_profile}" --field="Show Fallback profile":chk "${fallback_profile}" --field="Show unavailable profiles":chk "${unavailable_profile}" --button="Exit"!exit!Exit:99 
		verbose_yad="$(yad ${ycommopt} --window-icon "xfce-display-external" --width=900 --height=800 --form --field="Profiles info:":txt "${info_verbose}" --field="Show Default profile":chk "${default_profile}" --field="Show Fallback profile":chk "${fallback_profile}" --button="Exit"!exit!Exit:99 \
		--button="Refresh"!view-refresh!"Refresh profiles info":98 \
		--button="Go back"!back!"Go back to profile selection menu":97)"
		info_choice="${?}"
		default_profile="$(echo "${verbose_yad}" | awk -F'|' '{print $2}' | tr '[:upper:]' '[:lower:]')"
		fallback_profile="$(echo "${verbose_yad}" | awk -F'|' '{print $3}' | tr '[:upper:]' '[:lower:]')"
		#unavailable_profile="$(echo "${profile_yad}" | awk -F'|' '{print $3}' | tr '[:upper:]' '[:lower:]')"
		if [[ "${info_choice}" -eq '99' ]]; then
			exit 0
		elif [[ "${info_choice}" -eq '98' ]]; then
			true
		elif [[ "${info_choice}" -eq '97' ]]; then
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

	error_yad="$(yad ${ycommopt} --window-icon "xfce-display-external" --image "dialog-error" --text="Error:" --width=900 --height=200 --text-info <<<"${error_text}" --button="Exit"!exit!Exit:99)"
}

function check_dependencies() {

	commline_bins='xfconf-query xrandr perl awk cat grep'
	gui_bins='yad xfce4-display-settings wmctrl'
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
		if [[ "${gui_error}" = '1' ]]; then
			echo
		fi
	fi

	if [[ "${gui_error}" = '1' ]]; then
		echo -e "\e[1;33mWARNING: This script require \e[1;34m${missing}\e[1;33m for the GUI. Use e.g. \e[1;34msudo apt-get install ${missing}"
		echo -e "\e[1;33mInstall the requested dependencies and restart this script.\e[0m"
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
	profiles_ids="$(echo "${profiles_ids_prop}" | awk -F'/' '{print $2}' | awk '{print $1}' | uniq | grep -Ev "(ActiveProfile|Schemes|IdentityPopups)")"
	active_profile_id="$(echo "${profiles_ids_prop}" | grep '/ActiveProfile' | awk '{print $2}')"
	if [[ "${active_profile_id}" = 'Default' ]]; then
		default_profile='true'
	elif [[ "${active_profile_id}" = 'Fallback' ]]; then
		fallback_profile='true'
	fi

	## TODO: check if configured displays in profile are connected. Help is needed, please see https://github.com/KeyofBlueS/xfce4-display-profile-chooser/issues/1
	#CONNECTED_EDIDS="$(some command to get current connected displays EDID the same way as seen in xconf-query)"
}

function givemehelp() {

	echo "
# xfce4-display-profile-chooser

# Version:    0.2.0
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
-d, --list-default                  Show Default profile in profiles list
-f, --list-fallback                 Show Fallback profile in profiles list
-g, --gui                           Start with a graphical user interface
-h, --help                          Show this help
"
}

default_profile='false'
fallback_profile='false'
unavailable_profile='false'

for opt in "$@"; do
	shift
	case "$opt" in
		'--set-profile')		set -- "$@" '-s' ;;
		'--list-profiles')		set -- "$@" '-l' ;;
		'--list-verbose')		set -- "$@" '-v' ;;
		'--list-default')		set -- "$@" '-d' ;;
		'--list-fallback')		set -- "$@" '-f' ;;
		'--list-unavailable')	set -- "$@" '-u' ;;
		'--gui')				set -- "$@" '-g' ;;
		'--help')				set -- "$@" '-h' ;;
		*)						set -- "$@" "$opt"
	esac
done

while getopts "s:lvdfugh" opt; do
	case ${opt} in
		s ) profile_id="${OPTARG}"; actions="${actions} set_profile"
		;;
		l ) actions="${actions} list_profiles"
		;;
		v ) verbose='true'; actions="${actions} list_profiles"
		;;
		d ) default_profile='true'; actions="${actions} list_profiles"
		;;
		f ) fallback_profile='true'; actions="${actions} list_profiles"
		;;
		u ) unavailable_profile='true'; actions="${actions} list_profiles"
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
	unset actions
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
