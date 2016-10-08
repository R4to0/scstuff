#!/bin/bash

# install_opfor_support.sh for Sven Co-op 5.x
# Last update: Oct 8 2016 14:50 UTC-3:00 by Rafael "R4to0" Maciel.

# Tested on Ubuntu 14.04 and Debian 8 Jessie


init() {

	# If you don't want to install into svencoop_addon folder,
	#set to false (not recommended)
	scaddon=true

	# Do not touch below, unless you know what are doing.

	# Game name
	gamename="Opposing Force"

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
	
	# Destination path for maps
	if [ "$scaddon" == true ]
	then
		# svencoop_addon folder
		mpath="../svencoop_addon/maps"
	else
		# svencoop standard folder (not recommended)
		mpath="maps"
	fi

	# Path of Opposing Force installation
	op4dir="../../Half-Life/gearbox"

	# map list
	maplist="
		of0a0 of1a1 of1a2 of1a3 of1a4 of1a4b of1a5 of1a5b of1a6 \
		of2a1 of2a1b of2a4 of2a5 of2a6 \
		of3a1 of3a2 of3a4 of3a5 of3a6 \
		of4a1 of4a2 of4a3 of4a4 of4a5 \
		of5a1 of5a2 of5a3 of5a4 \
		of6a1 of6a2 of6a3 of6a4 of6a4b of6a5"

}

messages () {

	echo ""
	echo "-= Valve $gamename map support for Sven Co-op 5.0 =-"
	echo ""
	echo "Warning: around 70MB is used after installation."

	echo ""
	echo "Installation may take a few minutes depending on"
	echo "your system performance. Please be patient."
	echo ""
	echo ""
	
	# It's time to choose! - GMan
	for count in {5..1}; do echo -ne "Press CTRL+C to cancel or wait $count seconds..."'\r'; sleep 1; done; echo ""
	clear

	echo ""
	echo "OS architecture: $osarch-bit"
	echo "svencoop_addon support: $scaddon"
	echo "ripent binary: $ripent"
	echo ""
	echo ""

}

validation() {

	command -v unzip >/dev/null 2>&1  || { 
		echo "Unzip not found."
		echo "You can install by using 'sudo apt-get install unzip"
		echo "on Ubuntu and Debian, and 'yum install unzip'"
		echo "on RedHat or CentOS."
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

	# Check if Opposing Force game directory exists
	if [ -d "$op4dir" ];
	then
		echo "Found $gamename installation."
		copyop4
	fi

	for mcheck in $maplist; do

		# Extra check: let's make sure we have all map files!
		if [ -f "$mpath/$mcheck.bsp" ]
		then
			echo "Found $mcheck in maps folder!"
		else
			# Show message about missing file to user and exit script.
			echo ""
			echo "Oops! Map file $mcheck.bsp is missing. Please check if you"
			echo "have a working $gamename installation and/or"
			echo "all map files in maps folder before running this script!"
			echo ""
			exit 1
		fi
	done
	echo ""

}

copyop4(){

	for copy in $maplist; do
	echo "Copying $copy..."
	cp "$op4dir/maps/$copy.bsp" "$mpath/$copy.bsp"
	done
	echo ""

}

unzips(){

	echo "Unzipping support files..."
	unzip -o opfor_support.sven -d $mpath >/dev/null 2>&1

}

enting() {

	for ent in $maplist; do
	echo "Patching $ent..."
	./$ripent -import "$mpath/$ent".bsp >/dev/null 2>&1
	done
	echo ""

}

cleanup(){

	echo "Cleaning up..."
	echo ""
	rm $mpath/of*.ent

}

init
messages
validation
unzips
enting
cleanup

# Das ende

echo "All done! If you have any problems, ask"
echo "for help at http://forums.svencoop.com"

exit 0


# - Radio: R4to0, out!...
