presets=(base gnome plasma)
base="base linux linux-firmware power-profiles-daemon sudo" # essential shared
extras="amd-ucode fakeroot fish" # non-essential, potentially unique
gnome="$base gdm gnome-bluetooth-3.0 gnome-console network-manager-applet $extras" # essential for gnome
plasma="$base bluedevil konsole kscreen kwallet-pam plasma-desktop plasma-nm plasma-pa plasma-wayland-session powerdevil sddm-kcm $extras" # essential for plasma


locale="en_US.UTF-8 UTF-8" # used for locale-gen and locale.conf
timezone="US/Arizona" # relative to /usr/share/zoneinfo/
commands=(
	"echo \"exec fish\" >> /etc/bash.bashrc"
	"echo \"blacklist pcspkr\" > /etc/modprobe.d/blacklist.conf"
) # additional commands to execute within chroot