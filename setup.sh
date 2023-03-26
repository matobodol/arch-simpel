#! /bin/env bash
# CONFIGURE

install_base() {
	pacman -Sy --noconfirm archlinux-keyring
	pacstrap /mnt base base-devel linux-lts linux-firmware nano libnewt
	
	# memperbaiki gpg key
	if ! [[ $? == 0 ]]; then 
		echo 'memperbaiki gpg key...'
		killall gpg-agent
		rm -rf /etc/pacman.d/gnupg
		pacman-key --init
		pacman-key --populate archlinux
		
		pacstrap /mnt base base-devel linux-lts linux-firmware nano libnewt
		
		! [[ $? == 0 ]] && exit
	fi
}

set_fstab() {
	genfstab -U /mnt >> /mnt/etc/fstab
}

set_chroot() {
	isetup="/mnt/setup.sh"
	cp setup.sh /mnt
	
	sed -i "3ihostName='$hostName'" $isetup
	sed -i "4ipassRoot='$passRoot'" $isetup
	sed -i "5iuserName='$userName'" $isetup
	sed -i "6ipassUser='$passUser'" $isetup
	sed -i "7itimeZone='$timeZone'" $isetup
	sed -i "8iaddtionalPackages='$(echo -e $addtionalPackages)'" $isetup
	sed -i "9ikeyMap='$keyMap'" $isetup
	sed -i "10iselectedDrive='$selectedDrive'" $isetup
	sed -i "11ipathToInstallGrub='$pathToInstallGrub'" $isetup
	sed -i "12iselectedRoot='$selectedRoot'" $isetup
	
	arch-chroot /mnt ./setup.sh chroot
}

error_message() {
	if [[ -f /mnt/setup.sh ]];then
		msg='ERROR: Tidak dapat melakukan chroot ke system.'
		msg+='\nKesalah bisa terjadi karena proses install "base" terganggu.'
		msg+='\nPastikan koneksi internet tetap stabil.'
		echo "$msg"
	else
		unmount_filesystems
		msg='Installation is complete.'
		echo "$msg"
  fi
}

set_grub() {
	if [[ $grubyt -eq 0 ]]; then
		grub-install --target=i386-pc $pathToInstallGrub
		else
		grub-install --target=i386-pc $selectedDrive
	fi
	
	echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
	grub-mkconfig -o /boot/grub/grub.cfg
}

set_hostname() {
	echo "$hostName" > /etc/hostname
	cat >> /etc/hosts <<EOF
127.0.0.1	localhost 
::1		localhost
127.0.1.1	${hostName}.localdomain	$hostName 
EOF
}

set_root_password() {
	echo -en "$passRoot\n$passRoot" | passwd
}

set_timezone() {
	ln -sf "/usr/share/zoneinfo/$timeZone" /etc/localtime
	hwclock --systohc
}

set_keymap() {
	echo "KEYMAP=$keyMap" > /etc/vconsole.conf
}

create_user() {
	useradd -m -G wheel $userName
	echo -en "$passUser\n$passUser" | passwd $userName
}

install_pkg_tools() {
	seluruhPaket=($(pacman -Si $addtionalPackages | grep 'Depends On' | awk -F: '{print $2}'))
	jumlahSeluruhPaket=${#seluruhPaket[@]}

	# deklarasi array
	pkgs=($addtionalPackages)

	# menghitung elemen array
	jumlahPaket=${#pkgs[@]}

	currentTask=0 i=0

	
	for package in "${pkgs[@]}"; do
		((i++)); n=0
		
		# daftar dependensi
		dependensiList=($(pacman -Si $package | grep 'Depends On' | awk -F: '{print $2}'))
		# jumlah dependensi
		jumlahDependesi=${#dependensiList[@]}
 
		for dependensi in "${dependensiList[@]}"; do
			[[ i == 0 ]] && pacman -Sy
			# menghitung persen
			((n++)); ((currentTask++))

# menampilkan proses
cat <<EOF
XXX
$((currentTask*100/jumlahSeluruhPaket))
Installing [${i}/${jumlahPaket}] : ${package} 
XXX
EOF
			pacman -S --needed  --noprogressbar --quite --noconfirm --asdeps $dependensi
		done
		
		pacman -S --needed --noprogressbar --quite --noconfirm --asexplicit $package
		
	done | whiptail --title "Addtional Packages" --gauge "Please wait..." 8 80 0
}

set_locale() {
	echo "LANG=en_US.UTF-8" > /etc/locale.conf
	echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
	locale-gen
}

set_sudoers() {
	echo "%wheel ALL=(ALL) ALL" | tee -a /etc/sudoers &>/dev/null
}

clean_packages() {
	yes | pacman -Scc
	rm /setup.sh
}

if [[ $1 == chroot ]]; then

	install_pkg_tools
	set_hostname
	set_timezone
	set_keymap
	set_root_password
	set_locale
	create_user
	set_sudoers
	set_grub
	clean_packages

fi
