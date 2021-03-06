#!/bin/bash

# Sven Co-op support script for Valve games.

# Discord channel: https://discord.gg/y87qr6Y
# Forums: https://forums.svencoop.com/

init() {

	# Install location:
	# true: svencoop_addon, false: svencoop
	addondir=false

	# Don´t change anything below this line unless you know what are doing!!

	# Set root for the script.
	script_root="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

	# Safeguard¹: CD to the correct dir, no matter from where the script is ran.
	if [ "${PWD##*/}" != "svencoop" ];
	then
		cd "$script_root"
	fi

	# Safeguard²: prevent running this script outside svencoop folder if the above fails.
	if [ "${PWD##*/}" != "svencoop" ];
	then
		echo "Error: Script running outside \"svencoop\" folder! Exiting..."
		exit 1
	fi

	# Game name
	gamename="Blue Shift"

	# Get OS arch type
	osarch=$(getconf LONG_BIT)

	# Default ripent is 64-bit.
	# We have to use the right binary otherwise patching will fail...
	if [ "$osarch" == "64" ]
	then
		ripent=maps/ripent
	else
		ripent=maps/ripent_32
	fi

	# BS BSP Patcher binary
	bsp=BShiftBSPConverter

	# Destination path for maps
	if [[ "$addondir" == true ]]
	then
		# svencoop_addon folder
		instdir=svencoop_addon
	else
		# svencoop standard folder
		instdir=svencoop
	fi

	# Blue Shift relative dir
	bsdir="../../Half-Life/bshift"

	# map list
	maplist="
		ba_tram1 ba_tram2 ba_tram3 \
		ba_security1 ba_security2 ba_maint ba_elevator \
		ba_canal1 ba_canal1b ba_canal2 ba_canal3 \
		ba_yard1 ba_yard2 ba_yard3 ba_yard3a ba_yard3b ba_yard4 ba_yard4a ba_yard5 ba_yard5a ba_teleport1 \
		ba_xen1 ba_xen2 ba_xen3 ba_xen4 ba_xen5 ba_xen6 \
		ba_power1 ba_power2 \
		ba_teleport2 \
		ba_outro"

		# Chapter 1: Living Quarters Outbound
		# Chapter 2: Insecurity
		# Chapter 3: Duty Calls
		# Chapter 4: Captive Freight
		# Chapter 5: Focal Point
		# Chapter 6: Power Struggle
		# Chapter 7: A Leap Of Faith
		# Chapter 8: Deliverance

}

messages () {

	echo ""
	echo "-= Half-Life: $gamename map support for Sven Co-op =-"
	echo ""
	echo "Warning: around 60MB is used after installation."

	echo ""
	echo "Installation may take a few minutes depending on"
	echo "your system performance. Please be patient."
	echo ""

	echo "----------------------------------------------------------------------------"
	echo "IMPORTANT: To install $gamename support, you must own 'Half-Life:"
	echo "$gamename' and have it fully downloaded and installed on Steam!"
	echo "----------------------------------------------------------------------------"
	echo ""
	
	# It's time to choose! - GMan
	for count in {5..1}; do echo -ne "Press CTRL+C to cancel or wait $count seconds..."'\r'; sleep 1; done; echo ""
	clear

	echo ""
	echo "OS architecture: $osarch-bit"
	echo "Install directory: $instdir"
	echo "ripent binary: $ripent"
	echo ""
	echo ""

}

validation() {

	command -v unzip >/dev/null 2>&1  || { 
		echo "Unzip not found."
		echo "You can install by using \"sudo apt-get install unzip\""
		echo "for Ubuntu and Debian, and \"yum install unzip\""
		echo "for RedHat or CentOS."
		exit 1
	}

	if [ ! -f "$ripent" ]
	then
		echo "Missing $ripent, cannot continue. Corrupted install?"
		exit 1
	else
		if [[ ! -x "$ripent" ]]
		then
			chmod +x $ripent
		fi
	fi

	if [ ! -f "$bsp" ]
	then
		echo "Missing $bsp, cannot continue. Corrupted install?"
		exit 1
	else
		if [[ ! -x "$bsp" ]]
		then
			chmod +x $bsp
		fi
	fi

	# Check if Blue Shift game directory exists
	if [ -d "$bsdir" ];
	then
		echo "Found $gamename installation."
		copybs
	fi

	for mcheck in $maplist; do

		# Extra check: let's make sure we have all map files before doing anything!
		if [ -f "../$instdir/maps/$mcheck.bsp" ]
		then
			echo "Found $mcheck in maps folder!"
		else
			# Show message about missing file to user and exit script.
			echo ""
			echo "Oops! Map file $mcheck.bsp is missing. Please make sure you"
			echo "have a working $gamename installation and/or"
			echo "all map files in maps folder before running this script!"
			echo ""
			exit 1
		fi
	done
	echo ""

}

# Copy map files from original installation
copybs(){

	# Create required folders if is a clean installation
	if [ ! -d "../$instdir/gfx/env" ];
	then
		echo "Creating gfx/env/ directory..."
		mkdir -p ../$instdir/gfx/env
	fi
	
	if [ ! -d "../$instdir/maps" ];
	then
		echo "Creating maps directory..."
		mkdir -p ../$instdir/maps
	fi

	for copy in $maplist; do
	echo "Copying $copy..."
	cp "$bsdir/maps/$copy.bsp" "../$instdir/maps/$copy.bsp"
	done

	echo "Copying sky textures..."
	cp $bsdir/gfx/env/* ../$instdir/gfx/env/
	echo ""

}

# Patching / importing custom entities
patching() {

	echo "Unzipping support files..."
	unzip -o bshift_support.sven -d ../$instdir/maps >/dev/null 2>&1
	for target in $maplist; do
	echo "Patching $target..."
	./$bsp "../$instdir/maps/$target".bsp >/dev/null 2>&1
	./$ripent -import "../$instdir/maps/$target".bsp >/dev/null 2>&1
	done
	echo ""

}



# clean all the remaining mess :)
cleanup(){

	echo "Cleaning up..."
	rm ../$instdir/maps/ba_*.ent
	echo ""
}

# Time to call the functions!
init
messages
validation
patching
cleanup

# We made it Mr Calhoun, we made it!
echo "All done! If you have any problems, ask"
echo "for help at https://forums.svencoop.com"

exit 0
