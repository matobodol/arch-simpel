#!/usr/bin/env bash
# DISK MANAGER

reset_info_disk(){
    unset {iswap,iroot,ihome,isisa}
    unset {freeSize,noSwap,noRoot,noHome,noSisa}
    unset {sizeSwap,sizeRoot,sizeHome,sizeSisa}
    unset {pathSwap,pathRoot,pathHome,pathSisa}
    unset {selectedRoot,selectedRootSize,rootSize}
}

storage_list(){
    lsblk $1 -o path,type | grep "$2" | awk '{print $1}'
}

storage_name(){
    lsblk $1 -o model,type | grep "$2" | awk '{print $1}'
}

storage_size(){
    lsblk $1 -o size,type | grep "$2" | awk '{print $1}'
}

input_path_drive() {
    unset pathToInstallGrub
    while true; do
        storageList=($(storage_list '' 'disk'))
        storageName=($(storage_name '' 'disk'))
        storageSize=($(storage_size '' 'disk' | awk -F[,.G] '{print $1}'))

        i=0
        menu=$(
        while [[ $i -lt "${#storageList[@]}" ]]; do
            echo -e "${storageList[i]} (${storageName[i]}_${storageSize[i]}$unit)"
            (( i++ ))
        done
    )
    msg='Pilih drive:\nDimana system akan di install?\n\n'
    selectedDrive=$(whiptail --title "SELECT DISK" --menu "$msg" --nocancel 12 80 0 ${menu[@]} 3>&1 1>&2 2>&3)
    [[ $? == 0 ]] && break 1
done

storageName=$(storage_name $selectedDrive 'disk')
unset menu
}

input_disklabel_type() {
    local msg=''
    msg+=$(echo -e "\n\tHARAP DI PERHATIKAN.")
    msg+=$(echo -e "\n\tPada tahap ini akan memilih antara membuat partisi table atau melewatinya.")
    msg+=$(echo -e "\n\n\tApabila memilih MBR atau GPT, step selanjutnya akan membuka menu untuk")
    msg+=$(echo -e "\n\tmengatur alokasi size partisi: swap, root, home, dan space yg tersisa.")
    msg+=$(echo -e "\n\n\tSedangkan jika memilih <Lewati> akan membuka menu untuk memilih salah satu")
    msg+=$(echo -e "\n\tpartisi yang ada sebagai /root (target install).")
    msg+=$(echo -e "\n\t")

    diskLabelType=$(
    whiptail --title "DISKLABEL TYPE" --menu "$msg" \
        --ok-button "Select" --cancel-button "Lewati" \
        20 95 0 MBR "(ms-dos)" GPT "(efi)" 3>&1 1>&2 2>&3
    )

    case $diskLabelType in
        MBR)
            diskLabelType='msdos'
            disk_manager ;;
        GPT)
            whiptail --ok-button "Exit" --title "DISKLABEL TYPE" \
                --msgbox "Mohon maaf, Installer ini belum mendukung partisi table GPT!" 7 65
                            exit
                            diskLabelType='gpt'
                            disk_manager ;;
                        *)
                            diskLabelType='default'
                            input_path_root
                            ;;
                    esac
                }

                input_path_root() {
                    while true; do
                        partList=($(storage_list "$selectedDrive" 'part'))
                        partSize=($(storage_size "$selectedDrive" 'part'))

                        i=0
                        menu=$(
                        while [[ $i -lt "${#partList[@]}" ]]; do
                            echo -e "${partList[i]} _(${partSize[i]})"
                            (( i++ ))
                        done
                    )

                    infoDisk="[$selectedDrive] $(storage_name $selectedDrive 'disk') $(storage_size $selectedDrive 'disk')"
                    msg="Pilih partisi untuk root:\nDimana system akan di install?"

                    selectedRoot=$(whiptail --title "$infoDisk" --menu "$msg" \
                        --nocancel 12 80 0 ${menu[@]} 3>&1 1>&2 2>&3
                    )

                    selectedRootSize=$(storage_size $selectedRoot 'part' | awk -FG '{print $1}')

                    if [[ -n $(echo $selectedRootSize | grep 'M') ]]; then
                        whiptail --title "PILIH PARTISI ROOT" --msgbox "Size tidak boleh kurang dari ${sizeRootMinimum}$unit!" 7 60

                    else
                        rootSize=$(echo $(storage_size "$selectedRoot" 'part' | awk -F[,.G] '{print $1}'))

                        if [[ $rootSize -lt $sizeRootMinimum ]]; then
                            whiptail --title "PILIH PARTISI ROOT" --msgbox "Size tidak boleh kurang dari ${sizeRootMinimum}$unit!" 7 60
                        else
                            break
                        fi

                    fi
                done
            }

            disk_manager() {
                reset_info_disk
                nextMenu='[1] SWAP'

                while true; do
                    #storageName=$(storage_name $selectedDrive 'disk')
                    storageSize=$(storage_size $selectedDrive 'disk' | awk -F[,.G] '{print $1}')

                    [[ -z $storageSize || $storageSize -le 0 ]] && exit

                    msg="PERHATIKAN! Jika ada tanda (*) partisi wajib dibuat.\nPilih [SELESAI] untuk menyimpan."
                    diskManager=$(
                    whiptail --title "[$selectedDrive] $storageName $storageSize $unit" --menu "$msg" \
                        --cancel-button 'RESET' --default-item "$nextMenu" 15 80 0 \
                        '[1] SWAP'      "Buat partisi swap : $pathSwap" \
                        '[2] ROOT*   '  "Buat partisi root : $pathRoot" \
                        '[3] HOME'      "Buat partisi home : $pathHome" \
                        '[4] SISA'      "Buat partisi sisa : $pathSisa" \
                        ''              '' \
                        'SELESAI'       '' \
                        3>&1 1>&2 2>&3
                    )

                    case $diskManager in
                        '[1] SWAP')         	#menentukan nilai untuk swap
                            while true; do
                                reset_info_disk		#reset input

          #get user input for swap
          msg="Tentukan size untuk partisi swap:\nKapasitas Tersedia: $storageSize $unit"
          sizeSwap=$(whiptail --title "BUAT PARTISI SWAP" --inputbox "$msg" \
              --nocancel 9 60 4 3>&1 1>&2 2>&3
          )

          if [[ $? == 0 ]]; then

                        #blokir karaktes selain angka
                        if [[ -n $(echo $sizeSwap | grep -E [a-zA-Z.,/-]) ]]; then
                            unset sizeSwap

                        elif [[ $sizeSwap -ge 0 ]] && [[ $sizeSwap -le $storageSize ]]; then
                            #mendapatkan nomor partisi swap
                            if [[ -n $sizeSwap ]]; then
                                noSwap=1
                            fi

              #deklarasi dan inisialisasi hasil input user untuk ditampilksan pada main menu
              pathSwap="${selectedDrive}${noSwap} ${sizeSwap}$unit"

              #mendapatkan sisa kapasitas yg tersedia
              freeSize=$((storageSize - sizeSwap))

              #navigasi ke menu berikutya
              nextMenu='[2] ROOT*   '

              [[ $sizeSwap -le 0 ]] && unset {sizeSwap,pathSwap,noSwap}
              break

          elif [[ $sizeSwap -lt 0 ]]; then
              msg="Ups, kapasitas tidak valid!"
              whiptail --title "BUAT PARTISI SWAP" --msgbox "$msg" 7 75 3>&1 1>&2 2>&3

              unset {sizeSwap,pathSwap,noSwap}
              nextMenu='[1] SWAP'
              break

          elif [[ $sizeSwap -gt $storageSize ]]; then
              msg="Ups, melebihi kapasitas yg tersedia!"
              whiptail --title "BUAT PARTISI SWAP" --msgbox "$msg" 7 75 3>&1 1>&2 2>&3

              unset {sizeSwap,pathSwap,noSwap}
              nextMenu='[1] SWAP'
              break
                        fi
          fi
      done ;;

  '[2] ROOT*   ')
      while true; do
          #reset input
          unset {freeSize,noRoot,noHome,noSisa}
          unset {sizeRoot,sizeHome,sizeSisa}
          unset {pathRoot,pathHome,pathSisa}

                    #mendapatkan sisa kapasitas yg tersedia
                    freeSize=$((storageSize - sizeSwap))

                    #jika kapasitas yg tersedia untuk root kurang dari $sizeRootMinimum
                    if [[ $freeSize -lt $sizeRootMinimum ]]; then
                        msg="Ups, kapasitas yg tersisa tidak cukup!"
                        whiptail --title "BUAT PARTISI ROOT" --msgbox "$msg" 7 75 3>&1 1>&2 2>&3

                        unset {freeSize,sizeSwap,pathSwap}; break
                    fi

                    #get user input untuk root
                    msg="Tentukan size untuk partisi root:\nKapasitas Tersedia: $freeSize $unit"
                    sizeRoot=$(whiptail --title "BUAT PARTISI ROOT" --inputbox "$msg" --nocancel 9 60 $freeSize 3>&1 1>&2 2>&3)

                    if [[ $? == 0 ]]; then

                        #blokir karaktes selain angka
                        if [[ -n $(echo $sizeRoot | grep -E [a-zA-Z.,/-]) ]]; then
                            unset sizeRoot

                        #jika input user adalah valid
                    elif [[ $sizeRoot -ge $sizeRootMinimum ]] && [[ $sizeRoot -le $freeSize ]]; then

                            #mendapatkan nomor partisi root
                            if [[ -n $sizeRoot ]]; then

                                if [[ -n $sizeSwap ]]; then
                                    noRoot=2
                                else
                                    noRoot=1
                                fi

                            else
                                noRoot=1
                            fi

                            #deklarasi dan inisialisasi hasil input user untuk ditampilkan pada main menu
                            pathRoot="${selectedDrive}${noRoot} ${sizeRoot}$unit"

                            #navigasi ke menu berikutnya
                            if [[ $sizeRoot == $freeSize ]]; then
                                nextMenu='SELESAI'
                            else
                                nextMenu='[3] HOME'
                            fi

                            #mendapatkan sisa kapasitas yg tersedia
                            freeSize=$((storageSize - (sizeSwap + sizeRoot)))
                            break

                        #jika input user nilainya terlalu kecil
                    elif [[ $sizeRoot -lt $sizeRootMinimum ]]; then
                        msg="Ups, size minimum untuk root adalah ${sizeRootMinimum}$unit!"
                        whiptail --title "BUAT PARTISI ROOT" --msgbox "$msg" 7 75 3>&1 1>&2 2>&3

                        unset {sizeRoot,pathRoot,freeSize,noRoot}
                        #jika input user nilainya terlalu besar

                    elif [[ $sizeRoot -gt $freeSize ]]; then
                        msg="Ups, melebihi kapasitas yg tersedia!"
                        whiptail --title "BUAT PARTISI ROOT" --msgbox "$msg" 7 75 3>&1 1>&2 2>&3

                        unset {sizeRoot,pathRoot,freeSize,noRoot}
                        fi
                    fi
                done ;;

            '[3] HOME')          #menentukan nilai untuk home
                while true; do
                    #reset input
                    unset freeSize
                    unset {sizeHome,pathHome,noHome}
                    unset {sizeSisa,pathSisa,noSisa}

                    #mendapatkan sisa kapasitas yg tersedia
                    freeSize=$((storageSize - (sizeSwap + sizeRoot)))

                    #jika sisa kapasitas == 0
                    if [[ $freeSize -le 0 ]]; then
                        msg="Ups, tidak ada kapasitas yg tersedia!"
                        whiptail --title "BUAT PARTISI HOME" --msgbox "$msg" 7 75 3>&1 1>&2 2>&3
                        break
                    fi

                    #get user input untuk home
                    msg="Tentukan size untuk partisi home:\nKapasitas Tersedia: $freeSize $unit"

                    sizeHome=$(whiptail --title "BUAT PARTISI HOME" --inputbox "$msg" \
                        --nocancel 9 60 $freeSize 3>&1 1>&2 2>&3
                    )

                    #blokir karaktes selain angka
                    if [[ -n $(echo $sizeHome | grep -E [a-zA-Z.,/-]) ]]; then
                        unset sizeHome

                        #jika input user adalah valid
                    elif [[ $sizeHome -gt 0 ]] && [[ $sizeHome -le $freeSize ]]; then

                        #mendapatkan nomor partisi home
                        if [[ -n $noSwap ]]; then
                            noHome=2

                            if [[ -n $noRoot ]]; then
                                noHome=3
                            fi

                        else
                            noHome=1

                            if [[ -n $noRoot ]]; then
                                noHome=2
                            fi

                        fi

                        #deklarasi dan inisialisasi hasil input untuk ditampilkan pada main menu
                        pathHome="${selectedDrive}$noHome ${sizeHome}$unit"

                        #navigasi ke menu berikutnya
                        if [[ $sizeHome == $freeSize ]]; then
                            nextMenu='SELESAI'
                        else
                            nextMenu='[4] SISA'
                        fi

                        #mendapatkan sisa kapasitas yg tersedia
                        freeSize=$((storageSize - (sizeSwap + sizeRoot + sizeHome)))
                        break

                    #jika input user adalah 0 maka nilai akan direset
                elif [[ $sizeHome -le 0 ]]; then
                    unset {sizeHome,pathHome,noHome}
                    break

                    #jika input user melebihi kapasitas maka nilai akan direset
                elif [[ $sizeHome -gt $freeSize ]]; then
                    msg="Ups, melebihi kapasitas yg tersedia!"
                    whiptail --title "BUAT PARTISI HOME" --msgbox "$msg" 7 75 3>&1 1>&2 2>&3

                    unset {sizeHome,pathHome,noHome}
                    break
                    fi
                done ;;
            '[4] SISA')          #menentukan nilai untuk sisanya
                while true; do
                    #reset input
                    unset {freeSize,sizeSisa,pathSisa,noSisa}

                        #mendapatkan sisa kapasitas yg tersedia
                        freeSize=$((storageSize - (sizeSwap + sizeRoot + sizeHome)))

                        #jika sisa kapasitas == 0
                        if [[ $freeSize -le 0 ]]; then
                            msg="Ups, tidak ada kapasitas yg tersedia!"
                            whiptail --title "BUAT PARTISI SISA" --msgbox "$msg" 7 75 3>&1 1>&2 2>&3
                            break
                        fi

                        #get user input untuk sisa
                        msg="Tentukan size untuk partisi sisa:\nKapasitas Tersedia: $freeSize $unit"

                        sizeSisa=$(
                        whiptail --title "BUAT PARTISI SISA" --inputbox "$msg" \
                            --nocancel 9 60 $freeSize 3>&1 1>&2 2>&3
                        )

                        #blokir karakter selain angka
                        if [[ -n $(echo $sizeSisa | grep -E [a-zA-Z.,/-]) ]]; then
                            unset sizeSisa

                        #jika input user adalah valid
                    elif [[ $sizeSisa -gt 0 ]] && [[ $sizeSisa -le $freeSize ]]; then

                            #mendapatkan nomor urut partisi sisa
                            if [[ -n $noSwap ]]; then
                                noSisa=2

                                if [[ -n $noRoot ]]; then
                                    noSisa=3

                                    if [[ -n $noHome ]]; then
                                        noSisa=4
                                    fi

                                elif [[ -n $noHome ]]; then
                                    noSisa=3
                                fi

                            else
                                noSisa=1

                                if [[ -n $noRoot ]]; then
                                    noSisa=2

                                    if [[ -n $noHome ]]; then
                                        noSisa=3
                                    fi

                                elif [[ -n $noHome ]]; then
                                    noSisa=2
                                fi

                            fi

                            #deklarasi dan inisialisasi hasil input untuk ditampilkan pada main menu
                            pathSisa="${selectedDrive}$noSisa ${sizeSisa}$unit"

                            #navigasi ke menu berikutnya
                            nextMenu='SELESAI'
                            break

                        #jika input user 0 nilai akan di reset
                    elif [[ $sizeSisa -le 0 ]]; then
                        msg="Ups, input invalid!"
                        whiptail --title "BUAT PARTISI SISA" --msgbox "$msg" 7 75 3>&1 1>&2 2>&3

                        unset {sizeSisa,pathSisa,noSisa}
                        break

                        #jika input user lebih besar dari sisa kapasitas maka nilai akan direset
                    elif [[ $sizeSisa -gt $freeSize ]]; then
                        msg="Ups, melebihi kapasitas yg tersedia!"
                        whiptail --title "BUAT PARTISI SISA" --msgbox "$msg" 7 75 3>&1 1>&2 2>&3

                        unset {sizeSisa,pathSisa,noSisa}
                        break
                        fi
                    done ;;
                'SELESAI')
                    #jika sizeRoot belum memiliki nilai
                    if [[ -z $sizeRoot ]]; then
                        msg="UPS, PARTISI ROOT BELUM DI ISI!"
                        whiptail --title "DISK MANAGER : WARNING" --msgbox "$msg" 7 75 3>&1 1>&2 2>&3

                        #navigasi cursor ke menu berikutnya
                        nextMenu='[2] ROOT*   '
                    else
                        break
                    fi
                    ;;
                *)  #tombol reset
                    #jika user memilih tombol reset
                    if [[ $? == 1 ]]; then
                        unset freeSize
                        unset {sizeSwap,sizeHome,sizeRoot,sizeSisa}
                        unset {pathSwap,pathHome,pathRoot,pathSisa}
                        unset {noSwap,noRoot,noHome,noSisa}
                    fi
                    ;;
            esac

            [[ -z $sizeRoot ]] && nextMenu='[2] ROOT*   '
        done
    }

    input_path_grub() {
        while true; do
            storageList=($(storage_list '' 'disk'))
            storageName=($(storage_name '' 'disk'))
            storageSize=($(storage_size '' 'disk' | awk -F[,.G] '{print $1}'))

            i=0
            menu=$(
            while [[ $i -lt "${#storageList[@]}" ]]; do
                echo -e "${storageList[i]} (${storageName[i]}_${storageSize[i]}$unit)"
                (( i++ ))
            done
        )

        msg='Target install grub:\nDimana bootloader akan di install?\n\n'
        pathToInstallGrub=$(
        whiptail --title "GRUB BOOTLOADER" --menu "$msg" --nocancel \
            --default-item "$selectedDrive" 12 80 0 ${menu[@]} 3>&1 1>&2 2>&3
                    ) grubyt=$?

                    [[ $grubyt == 0 ]] && break 1
                done

                storageName=$(storage_name $selectedDrive 'disk')
            }


#FORMAT DISK
unmount_filesystems() {
    pathswap=$(lsblk -o path,mountpoint | grep SWAP | awk '{print $1}')
    if [[ -n $(echo $pathswap) ]]; then
        swapoff $pathswap
    fi

    pathmnt=$(lsblk -o path,mountpoint | grep '/mnt')
    if [[ -n $(echo $pathmnt) ]]; then
        umount -a
    fi
}

creat_disklable() {
    if ! [[ $diskLabelType == 'default' ]]; then
        parted -s $selectedDrive mktable $diskLabelType
    fi
}

creat_swap() {
    if [[ $sizeSwap -gt 0 ]]; then
        parted -s $selectedDrive mkpart primary linux-swap ${START}$a $(( ( sizeSwap * x ) + START ))$a
        START=$(( ( sizeSwap * x ) + START ))

        yes | mkswap ${selectedDrive}$noSwap
        swapon ${selectedDrive}$noSwap
    fi
}

creat_root() {
    if [[ $sizeRoot -gt 0 ]]; then

        if [[ $sizeRoot -lt $((storageSize - sizeSwap)) ]]; then
            endSize=$(echo $(( ( sizeRoot * x ) + START ))$a)
        else
            endSize='100%'
        fi

        parted -s $selectedDrive mkpart primary ${START}$a $endSize
        START=$(( ( sizeRoot * x ) + START ))

        yes | mkfs.ext4 ${selectedDrive}$noRoot
        mount ${selectedDrive}$noRoot /mnt
    fi
}

creat_home() {
    if [[ $sizeHome -gt 0 ]]; then

        if [[ $sizeRoot -lt $((storageSize - sizeSwap - sizeRoot)) ]]; then
            endSize=$(echo $(( ( sizeHome * x ) + START ))$a)
        else
            endSize='100%'
        fi

        parted -s $selectedDrive mkpart primary ${START}$a $endSize
        START=$(( ( sizeHome * x ) + START ))    

        yes | mkfs.ext4 ${selectedDrive}$noHome
        mkdir -p /mnt/home
        mount ${selectedDrive}$noHome /mnt/home
    fi
}

creat_sisa() {
    if [[ $sizeSisa -gt 0 ]]; then
        parted -s $selectedDrive mkpart primary ${START}$a 100% 

        yes | mkfs.ext4 ${selectedDrive}$noSisa
    fi
}

creat_efi() {
    if [[ $diskLabelType == 'gpt' ]]; then
        parted -s $selectedDrive mkpart primary fat32 ${START}$a ${EFI}$a
        START=$EFI

        mkfs.exfat -L efi ${selectedDrive}$x?
    fi
}

format_partisi() {
    unmount_filesystems

    if [[ $diskLabelType == default ]]; then
        yes | mkfs.ext4 ${selectedRoot}
        mount ${selectedRoot} /mnt

    else
        START=1 EFI=512 x=1024 a=MiB
        creat_disklable
        creat_swap
        creat_root
        creat_home
        creat_sisa
    fi
}

