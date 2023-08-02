#!/usr/bin/bash

# Disks
echo -e "\e[34m---- Disks ----\e[0m"
disks=($(fdisk -l | grep "Disk /" | awk '{print $2}' | rev | cut -c 2- | rev))
while true; do
	for index in "${!disks[@]}"; do
			echo "$index: ${disks[$index]}"
	done
	echo -n "Select a disk: "; read index
	if [ $index -gt -1 ] && [ $index -lt ${#disks[@]} ]; then
		disk=${disks[index]}
		echo -e "\e[32mSelected disk $disk\e[0m\n"
		break
	fi
done

# Partitions
echo -e "\e[34m---- Partitions ----\e[0m"
sector_size=$(fdisk -l $disk | grep optimal | rev | awk '{print $2}' | rev)
boot_end=$(( (268435456 / $sector_size) + 2047 ))
swap_end=$(( ($(free -b | grep Mem: | awk '{print $2}') / $sector_size) + $boot_end ))
(
	echo g; echo n; echo; echo 2048; echo $boot_end; echo t; echo 1;
	echo n; echo; echo $(( $boot_end + 1 )); echo $swap_end; echo t; echo 2; echo 19;
	echo n; echo; echo $(( $swap_end + 1 )); echo -0;
	echo w;
) | fdisk $disk &> /dev/null
echo -e "\e[32mCreated boot partition\e[0m"
echo -e "\e[32mCreated swap partition\e[0m"
echo -e "\e[32mCreated root partition\e[0m\n"

# Filesystems
echo -e "\e[34m---- Filesystems ----\e[0m"
partitions=($(fdisk -l $disk | grep ^/dev | awk '{print $1}'))
mkfs.vfat -F 32 ${partitions[0]}
mkswap ${partitions[1]}
filesystems=(ext4 f2fs xfs)
root_filesystem_command="mkfs -t "
for index in "${!filesystems[@]}"; do
				echo "$index: ${filesystems[$index]}"
done
while true; do
	echo -n "Select a filesystem: "; read index
	if [ $index -gt -1 ] && [ $index -lt ${#filesystems[@]} ]; then
		filesystem=${filesystems[index]}
		root_filesystem_command+="$filesystem "
		break
	fi
done
if [ $filesystem = "ext4" ]; then
	root_filesystem_command+="-F "
else
	root_filesystem_command+="-f "
fi

root_filesystem_command+="${partitions[2]}"
eval $root_filesystem_command
echo -e "\e[32mFormatted partition 1 to vfat\e[0m"
echo -e "\e[32mFormatted partition 2 to swap\e[0m"
echo -e "\e[32mFormatted partition 3 to $filesystem\e[0m\n"

# Installation
echo -e "\e[34m---- Installation ----\e[0m"
mount -L root /mnt
mkdir /mnt/boot
mount -L boot /mnt/boot
source ./configure.sh
for index in "${!presets[@]}"; do
			echo "$index: ${presets[$index]}"
done
while true; do
	echo -n "Select a package preset: "; read index
	if [ $index -gt -1 ] && [ $index -lt ${#presets[@]} ]; then
		preset=${presets[index]}
		break
	fi
done
pacstrap /mnt ${!preset}
echo -e "LABEL=boot\t/boot\tvfat\tnoatime\t0\t2\nLABEL=swap\tnone\tswap\tsw\t0\t0\nLABEL=root\t/\t$filesystem\tnoatime\t0\t1" > /mnt/etc/fstab
echo "en_US.UTF-8 UTF-8" > /mnt/etc/locale.gen
echo LANG=en_US.UTF-8 > /mnt/etc/locale.conf
echo -n "Enter hostname: "; read hostname
echo $hostname > /mnt/etc/hostname
cat << EOF > /mnt/root/continue.sh
ln -sf /usr/share/zoneinfo/US/Arizona /etc/localtime
hwclock --systohc
locale-gen
echo -n "Enter user: "; read user
echo -n "Enter name: "; read name
useradd -c \"$name\" -m -G wheel -s /bin/bash $user
echo "Setting password for $user"
passwd $user
echo "Setting password for root"
passwd
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers
systemctl enable NetworkManager
if [ -e /usr/bin/gdm ]; then
	systemctl enable gdm
elif [ -e /usr/bin/sddm ]; then
	systemctl enable sddm
fi
bootctl install
echo -e "default arch.conf\ntimeout 4\neditor no\nconsole-mode max" > /boot/loader/loader.conf
initrds=($(ls /boot | grep .img | grep -v fallback))
boot_config="title Arch\nlinux /vmlinuz-linux\n"
for index in "${!initrds[@]}"; do
			boot_config+="initrd /${initrds[$index]}\n"
done
boot_config+="options root=LABEL=root resume=LABEL=swap rw quiet"
echo -e $boot_config > /boot/loader/entries/arch.conf
for command in "${commands[@]}"; do
  eval $command
done
exit
EOF
chmod +x /mnt/root/continue.sh
arch-chroot /mnt /root/continue.sh
rm -rf /mnt/root/*
rm -rf /mnt/root/.*
rm -rf /mnt/home/$user/*
rm -rf /mnt/home/$user/.*
umount -R /mnt
echo -e "\e[32mInstallation complete\e[0m"
