#!/bin/bash

# Made by Raul Gavris <http://raulgavris.com>

pacman -Syy --noconfirm dialog || { echo "Error at script start: Are you sure you're running this as the root user? Are you sure you have an internet connection?"; exit; }

dialog --defaultno --title "Arch Linux install\!" --yesno "Are you sure you want to wipe out your entire hard disk and install Arch from zero?"  7 50 || exit

dialog --no-cancel --inputbox "Enter partition size in GB (swap)" 10 65 2>psize

IFS=' ' read -ra SIZE <<< $(cat psize)

# Windows -> command prompt installation -> BootRec.exe /FixMbr -> overwrites(deletes) grub
ls /usr/share/kbd/keymaps/**/*.map.gz # checks for keyboars layouts
# shift + pgup / pgdown for navigation
loadkeys ro
ls /sys/firmware/efi/efivars # checks if it is a uefi installation, this should be none
timedatectl set-ntp true
timedatectl status

# fdiks -l -> lsblk
# BOOT -> 200M
# SWAP -> (150/100)G of RAM
# ROOT -> the difference

printf "d\nd\nd\nd\nw\n" | fdisk /dev/nvme0n1
printf "g\nn\n1\n\n+512M\nn\n2\n\n+${SIZE[0]}G\nn\n3\n\n\nt\n1\n1\nt\n2\n19\nt\n3\n23\nw\n" | fdisk /dev/nvme0n1
partprobe

yes | mkfs.fat -F32 /dev/nvme0n1p1
yes | mkfs.ext4 /dev/nvme0n1p3
mkswap /dev/nvme0n1p2
swapon /dev/nvme0n1p2
mount /dev/nvme0n1p3 /mnt
mkdir -p /mnt/boot/efi
mount /dev/nvme0n1p1 /mnt/boot/efi

pacman -Sy --noconfirm archlinux-keyring

echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "ro_RO.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US ISO-8859-1" >> /etc/locale.gen
echo "ro_RO ISO-8859-2" >> /etc/locale.gen
locale-gen

pacstrap /mnt base base-devel linux linux-firmware vim dialog git iwd iw networkmanager man-db man-pages intel-ucode

genfstab -U /mnt >> /mnt/etc/fstab # again after mounting the boot partition and clean fstab

cp chroot.sh /mnt

arch-chroot /mnt bash chroot.sh && rm /mnt/chroot.sh
