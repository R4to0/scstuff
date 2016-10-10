#!/bin/bash

# install_bshift_support.sh - Revision 11 WIP (Jan 27 2016 19:02 UTC-2:00)
# Updates: https://gist.githubusercontent.com/R4to0/59433ea738d9630dfbd1/raw/install_bshift_support.sh
# Tested on Ubuntu 14.04 and Debian 8 Jessie
#
# What's new?
# - Added svencoop_addon support
# - Now using the new BShiftBSPConverter
# - Silent output option

#for future use, leave false
steamdl=false

# install support for svencoop_addon folder, false disables it
scaddon=false

# Enable/disable status output
statusout=true

# Don´t change anything below this line unless you know what are doing!!


# clear screen
clear

# greetings message
echo ""
echo "-= Valve Blue Shift map support for Sven Co-op 5.0 =-"
echo ""
echo "Warning: around 55MB is used after installation."

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

# the bit bucket aka NULL
null=/dev/null

# future use
if [ "$steamdl" == true ]
then
	# temp dir for downloading
	bstmpdir=/tmp/bshift

	# appid
	id=130
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

# set maplist
maplist="ba_canal1 ba_canal1b ba_canal2 ba_canal3 ba_elevator ba_maint ba_outro ba_power1 ba_power2 ba_security1 ba_security2 ba_teleport1 ba_teleport2 ba_tram1 ba_tram2 ba_tram3 ba_xen1 ba_xen2 ba_xen3 ba_xen4 ba_xen5 ba_xen6 ba_yard1 ba_yard2 ba_yard3 ba_yard3a ba_yard3b ba_yard4 ba_yard4a ba_yard5 ba_yard5a"

# dependencies
deps(){
	command -v unzip >/dev/null 2>&1  || { 
			echo "Unzip not found."
			echo "You can install by using 'sudo apt-get install unzip"
			echo "on Ubuntu and Debian, and 'yum install unzip'"
			echo "on Redhat or CentOS."
			exit 1
	}
	
	#don't know how to do on same func
	if [ ! -f "BShiftBSPConverter" ]
	then
		echo "Missing BShiftBSPConverter, please reinstall SvenDS."
		exit 1
	fi

	if [ ! -f "ripent" ]
	then
		echo "Missing ripent, please reinstall SvenDS."
		exit 1
	fi
}

# let's see if all files are where we want
mchk(){
	for check in $maplist; do

		# try every map in the list
		if [ -f "$mpath/$check.bsp" ]
		then
			# Found it? Cool!
			if [ "$statusout" == true ]
			then
				echo "Found $check"
			fi
		else
			# Show missing message to user and exit script.
			echo ""
			echo "Oops! Map file $check.bsp is missing. Please check if you"
			echo "have all Blue Shift map files in maps folder!"
			echo ""
			exit 1
		fi
	done
	echo ""
}

# convert/byte swapping
bsppatch(){
	# loop for patching
	for mpatch in $maplist; do

		# converting
		./BShiftBSPConverter "$mpath/$mpatch".bsp >$null
		if [ "$statusout" == true ]
		then
			echo "Converting $mpatch..."
		fi
	done
	echo ""
}

#unzip blue shift support files into maps folder
unzips(){
	if [ "$statusout" == true ]
	then
		echo "Unzipping support files..."
	fi
	unzip -o bshift_support.sven -d $mpath >$null
	echo ""
}

# *.ent patching section
entpatch(){
	# ripent binary
	ripent="./ripent -import"
	
	# patching loop
	for ent in $maplist; do
		if [ "$statusout" == true ]
		then
			echo "Patching $ent..."
		fi
		$ripent -import "$mpath/$ent".bsp >$null
	done
	echo ""
}

# clean all the remaining mess :)
cleanup(){
	if [ "$statusout" == true ]
	then
		echo "Cleaning up..."
	fi
	rm $mpath/ba_*.ent
	echo ""
}

# Time to call the functions!
deps
mchk
bsppatch
unzips
entpatch
cleanup

# We made it Mr Calhoun, we made it!
if [ "$statusout" == true ]
then
	echo "All done! If you see a bunch of errors please"
	echo "contact us at http://forums.svencoop.com"
else
	echo "Done!"
fi

exit 0

# - R4to0 was here...
