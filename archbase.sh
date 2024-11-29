#!/usr/bin/env bash
# CONFIGURE


install_base() {
    timedatectl set-ntp true
    #pacman -Sy --noconfirm archlinux-keyring
    pacstrap /mnt base base-devel linux-lts linux-firmware nano libnewt

    # memperbaiki gpg key
    if ! [[ $? == 0 ]]; then 
        echo 'memperbaiki gpg key...'
        killall gpg-agent
        rm -rf /etc/pacman.d/gnupg
        pacman-key --init
        pacman-key --populate archlinux

        pacstrap /mnt base base-devel linux-lts linux-firmware-lts nano libnewt

        if ! [[ $? -eq 0 ]]; then
            msg='Tidak dapat menginstall system!\n Pastikan gunakan jaringan internet yang stabil'
            whiptail --title "INSTALLING BASE" --msgbox "$msg" --ok-button 'Exit' 10 70
            exit
        fi
    fi
}

set_fstab() {
    genfstab -U /mnt >> /mnt/etc/fstab
}

set_chroot() {
    cp $(realpath "$BASH_SOURCE") /mnt
    SETUP_FILE="/mnt/archbase.sh"

    sed -i "3ihostName='$hostName'" $SETUP_FILE
    sed -i "4ipassRoot='$passRoot'" $SETUP_FILE
    sed -i "5iuserName='$userName'" $SETUP_FILE
    sed -i "6ipassUser='$passUser'" $SETUP_FILE
    sed -i "7itimeZone='$timeZone'" $SETUP_FILE
    sed -i "8iaddtionalPackages='$(echo -e $addtionalPackages)'" $SETUP_FILE
    sed -i "9ikeyMap='$keyMap'" $SETUP_FILE
    sed -i "10iselectedDrive='$selectedDrive'" $SETUP_FILE
    sed -i "11ipathToInstallGrub='$pathToInstallGrub'" $SETUP_FILE
    sed -i "12iselectedRoot='$selectedRoot'" $SETUP_FILE

    arch-chroot /mnt ./archbase.sh chroot
}

error_message() {
    if [[ -f /mnt/archbase.sh ]];then
        msg='ERROR: Tidak dapat melakukan chroot ke system.'
        msg+='\nKesalah bisa terjadi karena proses install "base" terganggu.'
        msg+='\nPastikan koneksi internet tetap stabil.'
        echo "$msg"
    else
        pathswap=$(lsblk -o path,mountpoint | grep SWAP | awk '{print $1}')
        [[ -n $(echo $pathswap) ]] && swapoff $pathswap

        pathmnt=$(lsblk -o path,mountpoint | grep '/mnt')
        [[ -n $(echo $pathmnt) ]] && umount -a

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
    pacman -Sy
    pacman -S --noconfirm $addtionalPackages
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
    rm /archbase.sh
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
