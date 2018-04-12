#Getting network
systemctl enable dhcpcd@eth0.service
ip link | grep -Po "(?<=[0-9]{1}: )[^:]+(?=:)" | dhcpcd #just dhcpcd also works
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
pacman -S —noconfirm lxde xscreensaver ttf-dejavu # the latter 2 can be optional. XFCE default fonts suck at rendering text so you will need to install this package and then change the font on the preferences.
echo “exec startlxde” > /root/.xinitrc
echo “exec startlxde” > /home/sicario/.xinitrc

#Installing some apps
pacman -S —noconfirm chromium
pacman -S alsa-utils #Configure sound

#Configuring sound. Use  aplay -l to check the card id. In my case, it is zero.
cat > /etc/asound.conf << EOF
pcm.!default {
    type hw
    card 1
}

ctl.!default {
    type hw           
    card 1
}
EOF

#Wireless. We create a configuration for each interface. In this way, systemctl service for wpa_supplicant will launch each interface automatically.
for interface in `ip link | grep -Po "(?<=[0-9]{1}: )wl[^:]+(?=:)"`; do 
  cat > /etc/wpa_supplicant/wpa_supplicant-$interface.conf << EOF 
    ctrl_interface=/run/wpa_supplicant
    update_config=1
    network={
        ssid="MYSSID"
        psk=[HEX PASSWORD] #or "PASSWORD" 
  }
  EOF
  systemctl enable wpa_supplicant@$interface.service
  wpa_supplicant -B -i $interface -c /etc/wpa_supplicant/wpa_supplicant.conf
done

#Then we can run wpa_cli. On the prompt run scan and then scan_results to see the APs.
