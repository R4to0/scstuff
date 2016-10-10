#!/bin/bash

# clear screen
clear

# a cool terminal title
PROMPT_COMMAND='echo -ne "\033]0;${USER}@{HOSTNAME}: Sven Co-op 5.0 Blue Shift Installer\007"'

# greetings message
echo ""
echo "-= Valve Blue Shift map support for Sven Co-op 5.0 =-"
echo ""
echo "This is a unfinished work in progress bash script"
echo "for testing propurses only. Use at your own risk"
echo ""
echo ""

# It's time to choose! - GMan (From Half-Life of course!)
echo "Press CTRL+C to cancel or wait for 5 seconds..."
sleep 5
clear

#set default path for maps
mpath="maps"

#set maplist
#maplist="ba_canal1.bsp ba_canal1b.bsp ba_canal2.bsp ba_canal3.bsp ba_elevator.bsp ba_maint.bsp ba_outro.bsp ba_power1.bsp ba_power2.bsp ba_security1.bsp ba_security2.bsp ba_teleport1.bsp ba_teleport2.bsp ba_tram1.bsp ba_tram2.bsp ba_tram3.bsp ba_xen1.bsp ba_xen2.bsp ba_xen3.bsp ba_xen4.bsp ba_xen5.bsp ba_xen6.bsp ba_yard1.bsp ba_yard2.bsp ba_yard3.bsp ba_yard3a.bsp ba_yard3b.bsp ba_yard4.bsp ba_yard4a.bsp ba_yard5.bsp ba_yard5a.bsp"
maplist="ba_canal1.bsp ba_canal1b.bsp" # temp/test

# dependencies
function deps(){
	command -v unzip >/dev/null 2>&1  || { 
			echo "Unzip not found."
			echo "You can install using 'apt-get install unzip"
			echo "on Ubuntu and Debian, and 'yum install unzip'"
			echo "on Redhat or CentOS."
			exit 1
	}
}

# let's see if all files are where we want
function mchk(){
	for check in $maplist; do

		# try every map in the list
		if [ -f "$mpath/$check" ]
		then
			# Found it? Cool!
			echo "Found $check"
		else
			# Show missing message to user and exit script.
			echo ""
			echo "Oops! Map file $check is missing. Please check if you"
			echo "have all Blue Shift maps in svencoop/maps folder!"
			echo ""
			exit 1
		fi
	done
}

# the hard part: swap few hex bytes in each map
function mpatch(){
	# set tmp files for hex values (for now)
	hex1=/tmp/hex1.tmp
	hex2=/tmp/hex2.tmp

	# loop for patching
	for mpatch in $maplist; do

		#dump two bytes group (0x4 to 0xA and 0xC to 0x12) in hex and save to a temp file
		xxd -u -s 4 -l 7 $mpath/$mpatch | xxd -r > $hex1
		xxd -u -s 12 -l 7 $mpath/$mpatch | xxd -r > $hex2
	
		# write values, hex1 to hex2 and hex 2 to hex1
		echo "Patching $mpatch..."
		dd if=$hex1 of=$mpath/$mpatch skip=4 count=7 bs=1 seek=12 conv=notrunc
		dd if=$hex2 of=$mpath/$mpatch skip=12 count=7 bs=1 seek=4 conv=notrunc
	done
}

#unzip blue shift support files into maps folder
function unzips(){
	echo "Unzipping support files..."
	unzip -o bshift_support.sven -d $mpath > /dev/null
}

# *.ent patching section
function entpatch(){
	# ripent binary
	ripent="./ripent-linux-m32 -import"
	
	# patching loop
	for ent in $maplist; do
		echo "Patching entities on $ent..."
		$ripent -import $mpath/$ent > /dev/null
	done
}

# clean all the remaining mess :)
function cleanup(){
	rm $mpath/ba_*.ent
	rm $hex1
	rm $hex2
}

# Time to call the functions!
mchk
mpatch
unzips
entpatch
cleanup

# We made it Mister Calhoun, we made it!
echo "All done!"

exit 0

# - R4to0 was here...
