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
	echo p; echo q; # change to write later
) | fdisk $disk &> /dev/null
echo -e "\e[32mCreated boot partition\e[0m"
echo -e "\e[32mCreated swap partition\e[0m"
echo -e "\e[32mCreated root partition\e[0m\n"

# Filesystems
echo -e "\e[34m---- Filesystems ----\e[0m"
partitions=($(fdisk -l $disk | grep ^/dev | awk '{print $1}'))
# mkfs.vfat -F 32 -n boot ${partitions[0]} # uncomment later
# mkswap -L swap ${partitions[1]}          # uncomment later
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
if [ $filesystem = "f2fs" ]; then
	root_filesystem_command+="-l root "
else
	root_filesystem_command+="-L root "
fi
root_filesystem_command+="${partitions[2]}"
echo $root_filesystem_command # change to eval later
echo -e "\e[32mFormatted partition 1 to vfat\e[0m"
echo -e "\e[32mFormatted partition 2 to swap\e[0m"
echo -e "\e[32mFormatted partition 3 to $filesystem\e[0m\n"

# Installation
echo -e "\e[34m---- Installation ----\e[0m"
# mount -L root /mnt # uncomment later
# mkdir /mnt/boot    # uncomment later
# mount -L boot /mnt/boot # uncomment later