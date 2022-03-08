#!/usr/bin/env bash

#############################################################################
#       Copyright (c) 1999-2022, Sven Co-op Team. All rights reserved.      #
#                                                                           #
#   A wrapper script for the game client binaries                           #
#                                                                           #
#   Discord channel: https://discord.gg/svencoop                            #
#   Steam Discussions: https://steamcommunity.com/app/225840/discussions/   #
#############################################################################

# Warn user if running from a unsupported shell (eg.: old sh) -R4to0
if [ -z "${BASH}" ] ; then
	echo "WARNING: You're running from an unsupported shell, some functions might not work! Please use bash instead."
fi

# figure out the absolute path to the script being run a bit
GAMEROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Fallback to old method in case the bash one fails (sh compatible)
# non-obvious, the ${0%/*} pulls the path out of $0, cd's into the
# specified directory, then uses $PWD to figure out where that
# directory lives - and all this in a subshell, so we don't affect
# $PWD
if [ -z "${GAMEROOT}" ]; then
	GAMEROOT="$(cd "${0%/*}" && echo "${PWD}")"
fi

# Fallback to current relative dir in case both lookup methods fails -R4to0
if [ -z "${GAMEROOT}" ]; then
	GAMEROOT="."
fi

GAMEPARAMS="${*}"

# Steam runtime libs
STEAMRUNTIME_DIR="$HOME/.steam/bin32/steam-runtime/i386/lib/i386-linux-gnu:$HOME/.steam/bin32/steam-runtime/i386/usr/lib/i386-linux-gnu"
STEAMOVERLAY_LIBS="$HOME/.steam/bin32/gameoverlayrenderer.so"
STEAMOVERLAY=0

# Client bins to check for missing dependencies
# TODO: scan for mod dir from -game param instead of hardcoding -R4to0 (22 August 2021)
CLIENTBINS=(
	"filesystem_stdio.so"
	"hw.so"
	"libdiscord-rpc.so"
	"libMiles.so"
	"libSDL2-2.0.so.0"
	"libsteam_api.so"
	"libtier0.so"
	"libvstdlib.so"
	"platform/servers/serverbrowser_linux.so"
	#"steamclient.so" # local isn't used by the game client -R4to0
	"svencoop/cl_dlls/client.so"
	"svencoop/cl_dlls/gameui.so"
	"svencoop/cl_dlls/libfmodex.so"
	"svencoop/cl_dlls/libsqlite3.so"
	"svencoop/dlls/libcurl.so.4"
	"svencoop/dlls/server.so"
	"svencoop_linux"
	"vgui.so"
	"vgui2.so"
)

# dll hell with penguins (-Duggles)
# ldd gep/sed/awk logic ripped from steam.sh
# @param {array} library list to check
dependencycheck() {
	echo -ne "Checking for missing dependencies... "

	# no list specified, quit
	if [ -z "$1" ]; then
		echo -ne "\n"
		return
	fi;

	MISSINGLIBS=""
	
	if [ -n "${SVENDS_DIR}" ]; then
		ROOTDIR="${SVENDS_DIR}" # server
		LAUNCHTYPE="SvenDS"
	elif [ -n "${GAMEROOT}" ]; then
		ROOTDIR="${GAMEROOT}" # client
		LAUNCHTYPE="Sven Co-op"
	else
		ROOTDIR="." # /shrug
		LAUNCHTYPE="Sven Co-op"
	fi

	# single filecheck
	if [ -f "${ROOTDIR}/${1}" ]; then
		# check if 32-bit support is installed
		if ! LD_PRELOAD='' ldd "${ROOTDIR}/${1}" >>/dev/null 2>&1; then
			showmessage "ERROR: Missing 32-bit loader!"
			#exit 1
			return 1
		fi
	fi

	for libfile in "${@}"
	do
		#echo "checking: ${ROOTDIR}/${libfile}"

		# check if critical server libs exists
		if [ ! -f "${ROOTDIR}/${libfile}" ]; then
			showmessage "ERROR: file ${libfile} is missing!"
			#exit 1
			return 1
		fi

		# *triggers Duggles* -R4to0
		MISS=$(LD_PRELOAD='' ldd "${ROOTDIR}/${libfile}" | grep "=>" | grep -v -e / -e linux-gate | awk '{print $1}' || true)
	
		if [ -n "${MISS}" ]; then # hit
			if [ -z "${MISSINGLIBS}" ]; then # first one
				MISSINGLIBS="${MISS}"
			else # newline + append
				MISSINGLIBS="${MISSINGLIBS}"$'\n'"${MISS}"
			fi
		fi
	done

	if [ -n "${MISSINGLIBS}" ]; then
		MISSINGLIBS="$(printf "%s\n" "${MISSINGLIBS[@]}" | sort -u)" # sort unique
		echo -ne "\n"
		showmessage "WARNING: You are missing the following 32-bit libraries, and ${LAUNCHTYPE} may not run:\n${MISSINGLIBS}\n\nPlease refer to the documentation of your Linux distribution for information about installing these libraries."
	else
		echo "OK!"
	fi
}

# prints in terminal and display a gui message if available (client only)
# @param {string} message to display
showmessage() {
	echo -ne "\n${1}\n\n"

	# hack to check if we are running game client
	# so we don't need args for this
	if [ -n "${GAMEROOT}" ]; then
		# shellcheck disable=SC2016 # hack² to get a clean PATH env to avoid some broken Steam bins, eg.: zenity (Thanks Duggles)
		CLEANPATH="$(env -i bash --login -c 'echo ${PATH}')"
		# loop through all well known gui dialogs
		for guitype in zenity gxmessage kdialog yad xmessage
		do
			guibin="$(PATH=${CLEANPATH} command -v ${guitype})"
			
			if [ -n "${guibin}" ]; then
				# use the correct params for the bin we found
				case "${guitype}" in
				"zenity" ) LD_LIBRARY_PATH="" "${guibin}" --width=640 --info --text="${1}" 2> /dev/null; break; ;; # make it auto scalable somehow? -R4to0
				"gxmessage" ) echo -ne "${1}" | "${guibin}" -center -file -; break; ;;
				"kdialog" ) "${guibin}" --msgbox "${1}"; break; ;;
				"yad" ) "${guibin}" --text "${1}" --center --button="gtk-ok:0"; break; ;;
				"xmessage" ) echo -ne "${1}" | "${guibin}" -center -file -; break; ;;
				esac
			fi
		done
	fi
}

# Fetch GNUC version and warn if running from a outdated distro -R4to0
GNUC_VER="$(ldd --version | awk '/ldd/{print $NF}')" # current running on the system
GNUC_MIN="2.24" # minimum supported version for the game binaries

# major || major && minor
if (( ${GNUC_VER%%.*} < ${GNUC_MIN%%.*} || ( ${GNUC_VER%%.*} <= ${GNUC_MIN%%.*} && ${GNUC_VER##*.} < ${GNUC_MIN##*.} ) )); then
	showmessage "WARNING: Unsupported distro GNU C Library detected. Please update your distro.\n\nYour system has: ${GNUC_VER}\nMinimum required: ${GNUC_MIN}"
fi

# shellcheck disable=SC2153 # STEAM_RUNTIME is set externally
# Set Steam runtime setting, use custom one to not override what steam-native sets -R4to0
# https://wiki.archlinux.org/index.php/Steam/Troubleshooting
if [ -n "${STEAM_RUNTIME}" ]; then
	if [ "${STEAM_RUNTIME}" = "0" ]; then
		STEAMRUNTIME=0
	else
		STEAMRUNTIME=1
	fi
else
    STEAMRUNTIME=1
fi

# Script options
while [ $# -gt 0 ]; do
	case "${1}" in
	"-nosteamruntime")
		STEAMRUNTIME=0
		;;
	"-steamoverlay")
		STEAMOVERLAY=1 # conditional implemented 08 March 2022 -R4to0
		;;
	esac
	shift
done

#determine platform
UNAME="$(uname)"

# Prepend game root to system's library path at runtime.
# Ours first, local set 2nd (if STEAMRUNTIME=1), Steam runtime last (if STEAMRUNTIME=1).
if [ "${UNAME}" == "Darwin" ]; then
	export DYLD_LIBRARY_PATH="${GAMEROOT}:${DYLD_LIBRARY_PATH}"
elif [ "${UNAME}" == "Linux" ]; then
	if [ "${STEAMRUNTIME}" = "0" ]; then
		export LD_LIBRARY_PATH="${GAMEROOT}"
		# shellcheck disable=SC2016
		PATH="$(env -i bash --login -c 'echo ${PATH}')" # clean PATH env (Thanks Duggles)
		export PATH
	else
		export LD_LIBRARY_PATH="${GAMEROOT}:${LD_LIBRARY_PATH}:${STEAMRUNTIME_DIR}"
	fi
fi

# get into game dir or die
cd "${GAMEROOT}" || exit

# Determine binary to use.
# TODO: Extend this to arch detection with x64 bins, if we get there... -R4to0
if [ -z "${GAMEEXE}" ]; then
	if [ "${UNAME}" == "Darwin" ]; then
		echo "macOS systems are not supported at this time..." # -R4to0 (11 December 2020)
		# osascript -e 'tell app "System Events" to display dialog "macOS systems are not supported at this time..." buttons {"OK"} with icon stop' # THIS NEEDS TESTING -R4to0 (11 December 2020)
		exit 0
		# GAMEEXE="svencoop_osx"
	elif [ "${UNAME}" == "Linux" ]; then
		GAMEEXE="svencoop_linux"
		dependencycheck "${CLIENTBINS[@]}"
	fi
fi

ulimit -n 2048 # Increase max file descriptors value (1024 by default on Debian/Ubuntu)

# Preload additional libraries here, also allows external LD_PRELOAD to be set.
# Steam overlay libs are preloaded when launching from Steam Client,
# but not from terminal, so preload here as well. -R4to0
if [ "${STEAMOVERLAY}" = "1" ]; then
	export LD_PRELOAD="./libiconv.so.2:${LD_PRELOAD}:${STEAMOVERLAY_LIBS}" # Append whatever Steam gives AND Steam Overlay libs if launched from terminal -R4to0 (08 March 2022)
else
	export LD_PRELOAD="./libiconv.so.2" # :${LD_PRELOAD}:${STEAMOVERLAY_LIBS}
fi

# Print all the variables we have set. This goes to Steam stdout/terminal
# and may help to diagnosticate game launching issues. -R4to0
echo "Game executable: ${GAMEEXE}"
echo "Launch parameters: ${GAMEPARAMS}"
echo "Game dir: ${GAMEROOT}"
echo "Platform type: ${UNAME}"
echo "GNU C version: $(ldd --version | awk '/ldd/{print $NF}')"
echo "File descriptors size: $(ulimit -n)"
echo "Current Linux library path: ${LD_LIBRARY_PATH}"
echo "Pre-loaded libs: ${LD_PRELOAD}"
#echo "System env: $(env)"
echo "System Path: ${PATH}"
echo "Using Steam runtime: $([[ $STEAMRUNTIME -eq 1 ]] && echo "yes" || echo "no")"
echo "Steam overlay is $([[ $STEAMOVERLAY -eq 1 ]] && echo "enabled" || echo "disabled")!"
echo -ne "\nLaunching...\n\n\n"

# Check if game binary exists.
# Some people have been running this as if it was the dedicated server
# launcher so let's tell that this is not the right launcher... -R4to0 (12 Jan 2021)
if [ ! -f "${GAMEROOT}/${GAMEEXE}" ]; then
	showmessage "----------------------------------------------------------------\nERROR: Game client executable not found.\nMake sure your installation is complete and validate files through Steam.\n\nAre you trying to run a dedicated server?\nYou should use \"svends_run\" launcher instead.\n----------------------------------------------------------------"
fi

STATUS=42
while [ "${STATUS}" -eq 42 ]; do
	# shellcheck disable=SC2086
	${DEBUGGER} "${GAMEROOT}/${GAMEEXE}" ${GAMEPARAMS}
	STATUS=$?
done

if [ "${STATUS}" -ne 0 ]; then
	showmessage "Uh oh it seems the game has crashed or failed to run (╯°□°）╯︵ ┻━┻\nSupport available on our Discord server: https://discord.gg/svencoop"
fi

exit $STATUS
