#Partitioning constants
MAIN_VOLUME="/dev/nvme0n1"
EFI_PARTITION="/dev/nvme0n1p1"
EFI_PARTITION_NAME="EFI"
BOOT_PARTITION="/dev/nvme0n1p2"
BOOT_PARTITION_NAME="Boot"
SWAP_PARTITION="/dev/nvme0n1p3"
SWAP_PARTITION="Swap"
DATA_PARTITION="/dev/nvme0n1p4"
DATA_PARTITION_NAME="Data"


#Other variables
HOSTNAME="SICARIO"
FQHN="SICARIO.NORSE.SEC"

#Accounts and credentials
ROOT_PASSWORD="toor"

#ArchLinux script
loadkeys pt-latin9
timedatectl set-ntp true

#Partitioning volumes
sgdisk -Z "$MAIN_VOLUME"
sgdisk -og "$MAIN_VOLUME"
sgdisk -n 1::+512M -n 2::+200M -n 3::+8G -n 4::  -t 1:ef00 -t 2:8300 -t 3:8200  -t 4:8300 -c 1:"$EFI_PARTITION_NAME" -c 2:"$BOOT_PARTITION_NAME" -c 3:"SWAP_PARTITION_NAME" -c 4:"$DATA_PARTITION_NAME"
mkfs.fat [-s1 -F32] "$EFI_PARTITION" 
mkfs.ext4 "$BOOT_PARTITION" 
mkswap "$SWAP_PARTITION"
mkfs.ext4 "$DATA_PARTITION"
swapon "$SWAP_PARTITION"
mount "$DATA_PARTITION" /mnt
mkdir /mnt/boot
mount "$BOOT_PARTITION" /mnt/boot

#Install base packages and generate fstab
pacstrap /mnt base base-devel
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt

#Timezone and stuff
ln -sf /usr/share/zoneinfo/Portugal /etc/localtime
hwclock --systohc
sed -i -e "s/#en_US\.UTF-8 UTF-8/en_US\.UTF-8 UTF-8\g" /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo -e "KEYMAP=pt-latin9\nFONT=\nFONT_MAP=" > /etc/vconsole.conf
echo "$HOSTNAME" > /etc/hostname
echo "127.0.0.1	localhost" >> /etc/hosts
echo "::1 localhost >> /etc/hosts
echo "127.0.1.1	$FQHN $HOSTNAME" >> /etc/hosts
echo "root:$ROOT_PASSWORD" | chpasswd

# Installing Bootloader
pacman -S —noconfirm grub efibootmgr
mkdir /boot/efi
mount "$EFI_PARTITION" /boot/efi
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=arch_grub
grub-mkconfig -o /boot/grub/grub.cfg
