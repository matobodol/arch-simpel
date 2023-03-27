#! /bin/env bash
# INPUT DATA

input_hostname() {
	while true; do
		msg="Nama host/komputer?"
		hostName=$(whiptail --title "HOSTNAME"	--inputbox "$msg" --nocancel 7 70 3>&1 1>&2 2>&3)
		
		if [[ $? == 0 ]]; then 
			hostName=$(echo $hostName | tr '[:upper:]' '[:lower:]')               #convert huruf besar -> kecil
			printf -v hostName '%s' $hostName; hostName=$(echo "$hostName")       #hapus semua spasi atau ruang kosong
			[[ -n $hostName ]] && break
		fi
	done
}

input_root_password() {
	while :; do
		title="PASSWORD ROOT"
		msg="Buat password root."
		passRoot=$(whiptail --title "$title" --passwordbox "$msg" --nocancel 7 70 3>&1 1>&2 2>&3)		#passwordbox
		
		msg="Ulangi masukan password root"
		passRoot1=$(whiptail --title "$title" --passwordbox "$msg" --nocancel 7 70 3>&1 1>&2 2>&3)		#passwordbox
		
		if [[ -z $passRoot ]] || [[ -z $passRoot1 ]]; then
			msg="Password tidak boleh kosong!"
			whiptail --title "$title" --msgbox "$msg" 7 70
		
		elif [[ $passRoot == $passRoot1 ]]; then
			break;
		
		else
			msg="Password tidak sama!"
			whiptail --title "$title" --msgbox "$msg" 7 70
		fi
	done
}

input_timezone() {
	msg="Pilih zona waktu tempat :\nIni akan mengatur waktu ke zona yg dipilih."
	msg+=" Jika tinggal di Indonesia pilih (Asia/Jakarta).\n\n"
	
	menu=(
		$(for i in $(timedatectl list-timezones); do
			echo -e "$i \r"
			done
		)
	)
	
	timeZone=$(whiptail --title "TIME ZONES" --menu "$msg" \
		--nocancel --default-item "Asia/Jakarta" \
		25 100 15 ${menu[@]} 3>&1 1>&2 2>&3
	)
	
	unset menu
}

input_keymap() {
	msg="Atur layout keyboard. jika bingung pilih saja: (us)\n\n"
	menu=(
		$(for i in $(localectl list-keymaps); do
		echo -e "$i \r"
		done
		)
	)
	
	keyMap=$(whiptail --title "KEYMAP" --menu "$msg" --nocancel \
		--default-item "us" 25 100 15 ${menu[@]} 3>&1 1>&2 2>&3
	)
	unset menu
}

input_create_user() {
	while true; do
		msg="Buat user baru:"
		userName=$(whiptail --title "CREAT USER" --inputbox "$msg" \
			--nocancel --default-item "$userName" 7 70 3>&1 1>&2 2>&3
		)
		
		if [[ $? == 0 ]]; then
			userName=$(echo $userName | tr '[:upper:]' '[:lower:]')             #convert huruf besar -> kecil
			printf -v userName '%s' $userName; userName=$(echo "$userName")     #hapus semua spasi atau ruang putih kosong
			
			[[ -n $userName ]] && break
		fi
	done
	
	while :; do
		
		msg="Password untuk user $userName"
		passUser=$(whiptail --title "PASSWORD $userName"	--passwordbox "$msg" \
			--nocancel 7 65 3>&1 1>&2 2>&3
		)
		
		msg="Ulangi masukan password"
		passUser1=$(whiptail --title "PASSWORD $userName" --passwordbox "$msg" \
			--nocancel 7 65 3>&1 1>&2 2>&3
		)
		
		if [[ -z $passUser ]] || [[ -z $passUser1 ]]; then
			whiptail --title "PASSWORD USER" --msgbox "Password tidak boleh kosong!" 7 65
		
		elif [[ $passUser == $passUser1 ]]; then
			break
		
		else
			whiptail --title "PASSWORD USER" --msgbox "Password tidak sama!" 7 65
		fi
		
	done
}

input_pkg_tools() {
	menu=(
		xf86-video-intel "Driver GPU intel" off \
		xf86-video-ati "Driver GPU Radeon" off \
		xf86-video-nouveau "Driver GPU nouveau" off \
		dialog "Dialog interactif di mode cli" on \
		mtools "Utilitas untuk mengakses disk MS-DOS" on \
		ntfs-3g "Dukungan untuk baca/tulis ke filesystem NTFS" on \
		dosfstools "Utilitas untuk emeriksa systemfile MSDOS FAT" on \
		os-prober "Menampilkan OS lain pada grub boot loader" on \
		grub "Boot loader" on \
		xorg-server "Display server" on \
		xorg-xinit "Menjalankan aplikasi GUI" on \
		xdg-user-dirs "Folder hirarki user" on \
		wireless_tools "Dukungan/ekstensi untuk wireless dan jaringan    " on \
		iwd	'alternatif network manager' off \
		dhcpcd 'client' off \
		networkmanager "Penyedia jaringan" on \
		linux-lts-headers "building modules for kernel" on \
	)

	msg=$(echo -e "\nUtilitas-dasar, berfungsi mendukung kinerja system.")
	msg+=$(echo -e "\nHati-hati ketika mengaktifkan driver GPU, pilih salah satu saja yg sesuai.")
	msg+=$(echo -e "\nJika tidak paham, sebaiknya biarkan apa adanya.")
	
	addtionalPackages=$(whiptail --separate-output --title "TOOLS AND UTILITIES" \
		--checklist "$msg" 30 80 18 "${menu[@]}" 3>&1 1>&2 2>&3
	)
	
	unset menu
	
	if [[ $? == 0 ]]; then
		pkgs=($addtionalPackages)
		
		x=0
		packagesList=$(
			for i in ${pkgs[@]}; do
				((x++))
				printf "$x.$i "
			done
		)
		
	fi
}
