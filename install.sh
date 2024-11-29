#!/usr/bin/env bash
# MAIN MENU

real_dir=$(realpath $(dirname "$BASH_SOURCE"))
chmod +x $real_dir/*.sh

sizeRootMinimum=4 unit='GB'
source $real_dir/diskmanager.sh
source $real_dir/setup.sh
source $real_dir/archbase.sh

display_info() {
    case $diskLabelType in

        default)
            msg=$(
            echo "Apakah data dibawah sudah benar ?\n"
            echo -e "\tSELECTED DRIVE          : [$selectedDrive] $storageName $storageSize $unit"
            echo -e "\tTarget Install Arch     : [$selectedRoot] ${selectedRootSize} $unit"
            echo -e "\tTarget Install Grub     : [$pathToInstallGrub]\n"
            echo -e "\tHost Name               : $hostName"
            echo -e "\tUser Name               : $userName"
            echo -e "\tTime Zone               : $timeZone"
            echo -e "\tLayout Keyboard         : $keyMap\n"
            echo -e "[${#pkgs[@]}] Optional akan di install:"
            echo "${packagesList[@]}"
        )

        whiptail --title "DISPLAY INFO" --msgbox "$msg" 22 100
        targetInstall=$(echo "[$selectedRoot]")

        msg="\n"
        nextMenu='[0] INSTALL'
        ;;

    msdos | gpt)
        #show data
        if [[ -z $sizeSwap ]];then newline=''; else newline="\n"; fi
        [[ -n $sizeSwap ]] && iswap=$(echo -e "\t /swap     ${selectedDrive}$noSwap     ${sizeSwap} $unit")
        [[ -n $sizeRoot ]] && iroot=$(echo -e "$newline\t /root     ${selectedDrive}$noRoot     ${sizeRoot} $unit")
        [[ -n $sizeHome ]] && ihome=$(echo -e "\n\t /home     ${selectedDrive}$noHome     ${sizeHome} $unit")
        [[ -n $sizeSisa ]] && isisa=$(echo -e "\n\t /free     ${selectedDrive}$noSisa     ${sizeSisa} $unit")

        msg=$(
        echo -e "Pastikan informasi dibawah sudah diatur dengan benar.\n"
        echo -e "\tSELECTED DRIVE          : [$selectedDrive] $storageName ${storageSize} $unit"
        echo -e "\tTarget Install Arch     : [${selectedDrive}$noRoot] ${sizeRoot} $unit"
        echo -e "\tTarget Install Grub     : [$pathToInstallGrub]\n"
        echo -e "\t[MOUNT]      [PATH]      [SIZE]"
        echo -e "${iswap}${iroot}${ihome}${isisa}\n"
        echo -e "\tHost Name               : $hostName"
        echo -e "\tUser Name               : $userName"
        echo -e "\tTime Zone               : $timeZone"
        echo -e "\tLayout Keyboard         : $keyMap\n"
        echo -e "[${#pkgs[@]}] Optional akan di install:"
        echo "${packagesList[@]}"
    )

    whiptail --title "DISPLAY INFO" --msgbox "$msg" 27 100
    targetInstall=$(echo "[$selectedDrive] $storageName ${storageSize} $unit")

    msg="\n"
    nextMenu='[0] INSTALL'
    ;;

*)
    msg='[9] DISPLAY INFO : Belum ada data untuk ditampilkan.'
    nextMenu='[1] DISK MANAGER'
    ;;
esac
}

#WARNING
confirm_to_format() {
    while true; do
        msgs='\nMohon periksa kembali data sebelum melanjutkan install!'
        [[ -z $pathToInstallGrub ]] && msg="[8] GRUB BOOTLOADER : Belum diatur! $msgs" && nextMenu='[8] GRUB BOOTLOADER'
        [[ -z $userName ]] && msg="[6] CREAT USER : Belum diatur! $msgs" && nextMenu='[6] CREAT USER'
        [[ -z $keyMap ]] && msg="[5] KEYMAP : Belum diatur! $msgs" && nextMenu='[5] KEYMAP'
        [[ -z $timeZone ]] && msg="[4] TIMEZONE : Belum diatur! $msgs" && nextMenu='[4] TIMEZONE'
        [[ -z $passRoot ]] && msg="[3] ROOT PASSWORD : Belum diatur! $msgs" && nextMenu='[3] ROOT PASSWORD'
        [[ -z $hostName ]] && msg="[2] HOSTNAME : Belum diatur! $msgs" && nextMenu='[2] HOSTNAME'
        [[ -z $selectedDrive ]] && msg="[1] DISK MANAGER : Belum diatur! $msgs" && nextMenu='[1] DISK MANAGER'

        if [[ -z $targetInstall ]] || [[ -z $pathToInstallGrub ]] || \
            [[ -z $keyMap ]] || [[ -z $timeZone ]] || \
            [[ -z $passRoot ]] || [[ -z $hostName ]] || \
            [[ -z $selectedDrive ]] || [[ -z $userName ]]; then
                    break 2
                else
                    msg=$(
                    echo -e "\t!PERHATIAN: Setelah memilih <YA> proses install tidak dapat dibatalkan!\n"
                    echo -e "\tProses ini akan menghapus seluruh data pada drive: ${targetInstall}."
                    echo -e "\tSebelum melanjutkan, cadangkan dulu data-data pentingnya.\n\n\n\n"
                    echo -e "\tTekan <YA> jika sudah yakin, atau <BACK> untuk kembali ke main menu."
                )

                whiptail --clear --title "INSTALL!" --yesno "$msg" --yes-button "YA" \
                    --no-button "BACK" 16 95 3>&1 1>&2 2>&3; GASPOL=$?
        fi

        msg="\n\n"
        break 2
    done
}

main_menu() {
    nextMenu='[1] DISK MANAGER';	msg="\n"

    while true; do

        if [[ $diskLabelType == 'default' ]]; then
            pathToInstallSystem=$selectedRoot
        else
            pathToInstallSystem=$selectedDrive
        fi

        [[ -z $pathToInstallGrub ]] && pathToInstallGrub=$selectedDrive

        mainMenu=$(whiptail --title "ARCHLINUX SIMPEL INSTALLER" --menu "$msg" --default-item "$nextMenu" \
            --ok-button 'SELECT' --cancel-button 'EXIT' 20 100 0 \
            '[1] DISK MANAGER' 						": Atur partisi [$pathToInstallSystem]" \
            '[2] HOSTNAME' 								": Atur nama host/komputer [$hostName]" \
            '[3] ROOT PASSWORD' 					": Atur password root" \
            '[4] TIMEZONE' 								": Atur zona waktu tempat [$timeZone]" \
            '[5] KEYMAP' 									": Atur layout keyboard [$keyMap]" \
            '[6] CREAT USER' 							": Buat akun user [$userName]" \
            '[7] OPTIONAL PACKAGES     ' 	": Pilih paket tambahan [${#pkgs[@]}]" \
            '[8] GRUB BOOTLOADER'					": Ubah path untuk install grub [$pathToInstallGrub]" \
            '[9] DISPLAY INFO' 						": Periksa informasi sebelum install" \
            ''														'' \
            '[0] INSTALL' 								'' \
            3>&1 1>&2 2>&3
        )

        [[ $? == 1 ]] && exit

        case $mainMenu in
            \[1\]*)
                input_path_drive
                input_disklabel_type
                msg="\n"; nextMenu='[2] HOSTNAME'
                ;;

            \[2\]*)
                input_hostname
                msg="\n";	nextMenu='[3] ROOT PASSWORD'
                ;;

            \[3\]*)
                input_root_password
                msg="\n"; nextMenu='[4] TIMEZONE'
                ;;

            \[4\]*)
                input_timezone
                msg="\n"; nextMenu='[5] KEYMAP'
                ;;

            \[5\]*)
                input_keymap
                msg="\n"; nextMenu='[6] CREAT USER'
                ;;

            \[6\]*)
                input_create_user
                msg="\n"; nextMenu='[7] OPTIONAL PACKAGES     '
                ;;

            \[7\]*)
                input_pkg_tools
                msg="\n"; nextMenu='[8] GRUB BOOTLOADER'
                ;;

            \[8\]*)
                input_path_grub
                msg="\n"; nextMenu='[9] DISPLAY INFO'
                ;;

            \[9\]*)
                display_info
                ;;

            '[0] INSTALL'*)
                confirm_to_format

                if [[ $GASPOL == 0 ]]; then
                    format_partisi
                    install_base
                    set_fstab
                    set_chroot
                    error_message
                    break
                fi

                ;;

            esac
        done
    }

    main_menu


