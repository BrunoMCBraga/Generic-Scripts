#Getting network
systemctl enable dhcpcd@eth0.service
ip link | grep -Po “(?<=[0-9]{1}: )[^:]+(?=:)” | dhcpcd #just dhcpcd also works
pacman -S linux-headers # Needed for the next step
pacman -S --noconfirm broadcom-wl-dkms #may not be necessary
pacman -S --noconfirm wpa_supplicant #may not be necessary

#Adding new user to sudoers
pacman -S —noconfirm sudo
useradd -m -s lbin/bash sicario
usermod -a -G wheel sicario
echo "sicario ALL=(ALL) ALL" >> /etc/sudoers
echo “sicario:sicario” | chpasswd

#Installing GUI
sudo pacman -S —noconfirm xorg-server xorg-xinit
pacman -S —noconfirm lxde
echo “exec startlxde” > /root/.xinitrc
echo “exec startlxde” > /home/sicario/.xinitrc
