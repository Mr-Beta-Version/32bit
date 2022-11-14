#!/bin/bash

case "$(getprop ro.build.version.release)" in
	5*|6*)
		echo "Android 5/6 isn't supported"
		exit 2
		;;
	*) ;;
esac

unset LD_PRELOAD

TEMPDIR="$(mktemp -d)"

print-help(){
	cat <<- EOM
	 Options:
	 help - show this help
	 small - 32-bit Mode
	 big - 64 bit mode
	EOM
}

small(){
	case "$(uname -m)" in
		armv8*|armv7*|i*86)
			cat <<- EOM
			 Your device is already in 32-bit small
			EOM
			exit 2
			;;
		*) ;;
	esac
	# Print some warning message
	cat <<- EOM
	Running Started....
	EOM
	sleep 5.5
	case "$(uname -m)" in
		aarch64)
			printf '[+] Installing 32bit '
			;;
		x86_64)
			curl --fail --location --output $TEMPDIR/termux-bootstrap.zip.part "$BOOTSTRAP_INTEL"
			;;
		*)
			exit 2
	esac

	echo "[*] Unpacking 32-bit termux bootstrap"
	sleep 1
	chmod 755 usr -R ||:
	# Create Second Stage Script
	echo "[*] Doing Second Stage Setup"
	cat > $PREFIX/../secondstage-setup.sh <<- EOM
	#!/system/bin/sh
	echo "[*] Creating Backup"
	mv usr usr64-backup
	echo "[*] Switching"
	mv 32bit-backup usr
	rm secondstage-setup.sh
	echo "[✓] Done, Please Close and Reopen the app"
	sleep 2
	kill -KILL $PPID
	EOM
	chmod 755 $PREFIX/../secondstage-setup.sh
	cd $PREFIX/..

	# Kill Current Process and Do Second Stage Setup
	exec /system/bin/env -i ./secondstage-setup.sh
}

big(){
	case "$(uname -m)" in
		aarch64|x86_64)
			echo "This option is used to switching back to 64-bit, you're already 64-bit"
			exit 2
			;;
		*) ;;
	esac

	read -p "Do You Want 64 Bit Termux (y,N) >>  " answer

	case "$answer" in
		Y*|y*) ;;
		*) echo "Aborting...."; exit 2 ;;
	esac

	cd $PREFIX/..

	if [ ! -e usr64-backup ]; then
		echo "[!] The Backup Directory isn't exists.. Continuing Anyway!"
	fi

	echo "[*] Running 64 bit "
	cat > purge-prefix.sh <<- EOM
	#!/system/bin/sh
	chmod 755 usr -R ||:
	mv usr 32bit-backup

	# Restore Backup directory if possible"
	if [ -e usr64-backup ]; then
		mv usr64-backup usr
	fi

	rm -rf purge-prefix.sh

	echo "[✓] Done, Please Close and Reopen the app"
	sleep 2
	kill -KILL $PPID
	EOM
	chmod 755 purge-prefix.sh

	# Kill Current Process and Purge 32-bit prefix
	exec /system/bin/env -i ./purge-prefix.sh
}

args="$1"

if [ -z "$args" ]; then
	print-help
	exit 2
fi

case "$args" in
	help)
		print-help
		;;
	small)
		small
		;;
	big)
		big
		;;
	*)
		cat <<- EOM
		Unknown Argument: $args

		See "termux-prefix-switcher help" for more information
		EOM
		;;
esac

# END OF MESSAGE EOM
