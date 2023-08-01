presets=(base gnome plasma)
base="base linux linux-firmware power-profiles-daemon sudo" # essential
extras="amd-ucode fakeroot fish" # non-essential
gnome="$base gdm gnome-console network-manager-applet $extras" # essential for gnome
plasma="$base konsole kscreen kwallet-pam plasma-desktop plasma-nm plasma-pa plasma-wayland-session powerdevil sddm-kcm $extras" # essential for plasma
commands=(
	"echo \"exec fish\" >> /etc/bash.bashrc"
) # additional commands to execute within chroot