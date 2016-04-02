#!/bin/bash

# install_opfor_support.sh - Revision 2 (Apr 02 2016 06:33PM UTC-3:00) by Rafael "R4to0" Maciel.
# Under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License 
# CC BY-NC-SA 4.0 - http://creativecommons.org/licenses/by-nc-sa/4.0/

# Updates: https://gist.githubusercontent.com/R4to0/314d18e8b4cd2c107d9b0f029dbedf90/raw/install_opfor_support.sh
# Tested on Ubuntu 14.04 and Debian 8 Jessie
#

init() {

	# SteamCMD download. For future use, leave false.
	steamdl=false

	# install support for svencoop_addon folder, false disable it
	scaddon=true

	# Verbose: enable/disable extra info
	verbose=false
	
	# SILENCE! I KILL YOU!
	# Disable echo messages
	silent=false

	# OS arch type
	osarch=`getconf LONG_BIT`

	# Included ripent is 64-bit only.
	# We should choose a right binary otherwise patching will fail
	if [ $osarch == "64" ]
	then
		ripent=ripent
	else
		ripent=ripent_32
	fi
	
	# set path for maps
	if [ "$scaddon" == true ]
	then
		# addon folder
		mpath="../svencoop_addon/maps"
	else
		# default
		mpath="maps"
	fi
	
	if [ "$silent" == true ]
	then
		# small hack to mute echo comms
		alias echo=':'
		
		# force verbose false
		verbose=false
	fi
	
	if [ "verbose" == true ]
	then
		null=""
	else
		null=" > /dev/null 2>&1"
	fi

	# map list
	maplist="of0a0 of1a1 of1a2 of1a3 of1a4 of1a4b of1a5 of1a5b of1a6 of2a1 of2a1b of2a4 of2a5 of2a6 of3a1 of3a2 of3a4 of3a5 of3a6 of4a1 of4a2 of4a3 of4a4 of4a5 of5a1 of5a2 of5a3 of5a4 of6a1 of6a2 of6a3 of6a4 of6a4b of6a5"

	messages

}

messages () {

	echo ""
	echo "-= Valve Opposing Force map support for Sven Co-op 5.0 =-"
	echo ""
	echo "Warning: around 65MB is used after installation."

	if [ "$steamdl" == true ]
	then
		echo "An additional of xxxMB are temporarily used for"
		echo "download process and cleared after finishes."
	fi

	echo ""
	echo "Installation may take a few minutes depending on"
	echo "your system and internet speed. Please be patient."
	echo ""
	echo ""
	
	# It's time to choose! - GMan
	echo "Press CTRL+C to cancel or wait for 5 seconds..."
	sleep 5
	clear

	echo ""
	echo "OS architecture: $osarch-bit"
	echo "SteamCMD download feature: $steamdl"
	echo "svencoop_addon support: $scaddon"
	echo "ripent binary: $ripent"
	echo ""
	echo ""

	validation

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
		echo "Missing $ripent, cannot continue."
		exit 1
	else
		if [[ ! -x "$ripent" ]]
		then
			chmod +x $ripent
		fi
	fi
	
	for mcheck in $maplist; do

		# try every map in the list
		if [ -f "$mpath/$mcheck.bsp" ]
		then
			echo "Found $mcheck"
		else
			# Show message about missing file to user and exit script.
			echo ""
			echo "Oops! Map file $mcheck.bsp is missing. Please check if you"
			echo "have all Opposing Force map files in maps folder!"
			echo ""
			exit 1
		fi
	done
	echo ""

	unzips

}

unzips(){

	echo "Unzipping support files..."
	unzip -o opfor_support.sven -d $mpath >/dev/null 2>&1

	enting

}

enting() {

	for ent in $maplist; do
	echo "Patching $ent..."
	./$ripent -import "$mpath/$ent".bsp >/dev/null 2>&1
	done
	
	cleanup

}

cleanup(){

	echo "Cleaning up..."
	echo ""
	rm $mpath/of*.ent

}

init

# Das ende

echo "All done! If you see a bunch of errors please"
echo "contact us at http://forums.svencoop.com"

exit 0


# - Radio: R4to0, out!...
