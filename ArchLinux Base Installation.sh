#ArchLinux script
loadkeys pt-latin9
timedatectl set-ntp true

#Partitioning volumes
sgdisk -Z /dev/nvme0n1
sgdisk -og /dev/nvme0n1
sgdisk -n 1::+512M -n 2::+200M -n 3::+8G -n 4::  -t 1:ef00 -t 2:8300 -t 3:8200  -t 4:8300 -c 1:”EFI Partition” -c 2:”BOOT Partition” -c 3:”SWAP” -c 4:“”
mkfs.fat [-s1 -F32] /dev/nvme0n1p1  
mkfs.ext4 /dev/nvme0n1p2 
mkswap /dev/nvme0n1p3
mkfs.ext4 /dev/nvme0n1p4
swapon /dev/nvme0n1p3
mount /dev/nvme0n1p4 /mnt
mkdir /mnt/boot
mount /dev/nvme0n1p2 /mnt/boot

#Install base packages and generate fstab
pacstrap /mnt base base-devel
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt

#Timezone and stuff
ln -sf /usr/share/zoneinfo/Portugal /etc/localtime
hwclock --systohc
sed -i -e “s/#en_US\.UTF-8 UTF-8/en_US\.UTF-8 UTF-8\g” /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=pt-latin9\nFONT=\nFONT_MAP=" > /etc/vconsole.conf
echo "sicario” > /etc/hostname
echo "127.0.0.1	localhost” >> /etc/hosts
echo "::1 localhost >> /etc/hosts
echo "127.0.1.1	sicario.norse.sec sicario” >> /etc/hosts
echo "root:toor” | chpasswd

# Installing Bootloader
pacman -S —noconfirm grub efibootmgr
mkdir /boot/efi
mount /dev/nvme0n1p1 /boot/efi
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=arch_grub
grub-mkconfig -o /boot/grub/grub.cfg
