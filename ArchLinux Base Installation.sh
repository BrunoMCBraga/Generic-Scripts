#Partitioning constants
MAIN_VOLUME="/dev/nvme0n1"
EFI_PARTITION="/dev/nvme0n1p1"
EFI_PARTITION_NAME="EFI"
BOOT_PARTITION="/dev/nvme0n1p2"
BOOT_PARTITION_NAME="Boot"
LVM_PARTITION="/dev/nvme0n1p4"
LVM_PARTITION_NAME="LVMSSD"
LVM_DATA_PARTITION_NAME="LVMDataSSD"
LVM_DATA_PARTITION_MOUNT_POINT="/mnt"
LVM_SWAP_PARTITION_NAME="LVMSWAP"
LVM_VOLUME_GROUP_NAME="MainVolGroup"

LUKS_PASSPHRASE="toor"

SECONDARY_VOLUME="/dev/[WHATEVER]"
SECONDARY_LVM_PARTITION="/dev/[WHATEVER]"
SECONDARY_LVM_PARTITION_NAME="LVMHDD"
SECONDARY_LVM_DATA_PARTITION_NAME="LVMDataHDD"
SECONDARY_LVM_DATA_PARTITION_MOUNT_POINT="/mnt/hdd"
SECONDARY_VOLUME_GROUP_NAME="SecondaryVolGroup"
SECONDARY_LVM_VOLUME_GROUP_NAME="SecondaryVolGroup"

LUKS_KEY_FILE="/root/keyfile"

#Other variables
HOSTNAME="SICARIO"
FQHN="SICARIO.NORSE.SEC"

#Accounts and credentials
ROOT_PASSWORD="toor"

#ArchLinux script
loadkeys pt-latin9
timedatectl set-ntp true

#Partitioning volumes and partition mounting (LVM on LUKS) for main hard drive (e.g. ssd)
sgdisk -Z -og "$MAIN_VOLUME"
sgdisk -n 1::+512M -n 2::+200M -n 3::+8G -n 4::  -t 1:ef00 -t 2:8300 -t 3:8200  -t 4:8e00 -c 1:"$EFI_PARTITION_NAME" -c 2:"$BOOT_PARTITION_NAME" -c 3:"$LVM_PARTITION_NAME"

cryptsetup luksFormat --type luks2 "$LVM_PARTITION" #Create the LUKS encrypted container. 
echo "$LUKS_PASSPHRASE" | cryptsetup luksOpen "$LVM_PARTITION" "$LVM_PARTITION_NAME"  -d - #Open the container. The decrypted container is now available at /dev/mapper/$LVM_PARTITION_NAME
pvcreate /dev/mapper/"$LVM_PARTITION_NAME" #Create a physical volume on top of the opened LUKS container
vgcreate "$LVM_VOLUME_GROUP_NAME" /dev/mapper/"$LVM_PARTITION_NAME" #Create the volume group named X, adding the previously created physical volume to it

lvcreate -L 8G "$LVM_VOLUME_GROUP_NAME" -n "$LVM_SWAP_PARTITION_NAME"
lvcreate -l 100%FREE "$LVM_VOLUME_GROUP_NAME" -n "$LVM_DATA_PARTITION_NAME"

# Formatting and mounting SWAP and data partitions
mkfs.fat [-s1 -F32] "$EFI_PARTITION" 
mkfs.ext4 /dev/"$LVM_VOLUME_GROUP_NAME"/"$LVM_DATA_PARTITION_NAME"
mkswap /dev/"$LVM_VOLUME_GROUP_NAME"/"$LVM_SWAP_PARTITION_NAME"

mount /dev/"$LVM_VOLUME_GROUP_NAME"/"$LVM_DATA_PARTITION_NAME" /mnt
swapon /dev/"$LVM_VOLUME_GROUP_NAME"/"$LVM_SWAP_PARTITION_NAME"

# Formatting and mounting boot partition
mkfs.ext4 "$BOOT_PARTITION" 

mkdir /mnt/boot
mount "$BOOT_PARTITION" /mnt/boot


#Create key file for second volume
dd if=/dev/urandom of="$LUKS_KEY_FILE" bs=1024 count=4
chmod 0400 "$LUKS_KEY_FILE"

#Partitioning volumes and partition mounting (LVM on LUKS) for main hard drive (e.g. hdd)
sgdisk -Z -og "$SECONDARY_VOLUME"
sgdisk -n 1:: -t 1:8e00 -c 1:"$SECONDARY_LVM_PARTITION_NAME"
cryptsetup luksFormat --type luks2 "$SECONDARY_LVM_PARTITION"
cryptsetup open "$SECONDARY_LVM_PARTITION" "$SECONDARY_LVM_PARTITION_NAME" -d "$LUKS_KEY_FILE"
pvcreate /dev/mapper/"$SECONDARY_LVM_PARTITION_NAME" #Create a physical volume on top of the opened LUKS container
vgcreate "$SECONDARY_LVM_VOLUME_GROUP_NAME" /dev/mapper/"$SECONDARY_LVM_PARTITION_NAME" #Create the volume group named X, adding the previously created physical volume to it

lvcreate -l 100%FREE "$SECONDARY_LVM_VOLUME_GROUP_NAME" -n "$SECONDARY_LVM_DATA_PARTITION_NAME"

# Formatting partitions
mkfs.ext4 /dev/"$SECONDARY_LVM_VOLUME_GROUP_NAME"/"$SECONDARY_LVM_DATA_PARTITION_NAME"

# Mounting secondary hard drive data
mkdir "$SECONDARY_LVM_DATA_PARTITION_MOUNT_POINT"
mount /dev/"$SECONDARY_LVM_VOLUME_GROUP_NAME"/"$SECONDARY_LVM_DATA_PARTITION_NAME" "$SECONDARY_LVM_DATA_PARTITION_MOUNT_POINT"

echo "$SECONDARY_LVM_PARTITION_NAME $SECONDARY_LVM_PARTITION $LUKS_KEY_FILE luks" >> /etc/crypttab

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
echo "::1 localhost" >> /etc/hosts
echo "127.0.1.1	$FQHN $HOSTNAME" >> /etc/hosts
echo "root:$ROOT_PASSWORD" | chpasswd

#mkinitcpio.conf config
echo "HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt lvm2 filesystems fsck)" > /etc/mkinitcpio.conf
mkinitcpio -p linux

#Installing Bootloader
pacman -S —noconfirm grub efibootmgr
mkdir /boot/efi
mount "$EFI_PARTITION" /boot/efi
echo -e "GRUB_CMDLINE_LINUX=\"cryptdevice=/dev/$LVM_VOLUME_GROUP_NAME/$LVM_PARTITION:$LVM_PARTITION_NAME root=/dev/mapper/$LVM_PARTITION_NAME\"\nGRUB_ENABLE_CRYPTODISK=y" > /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=arch_grub --recheck

#Cleanup
exit
umount -R /mnt/boot
umount -R /mnt
cryptsetup close "$LVM_PARTITION_NAME"
cryptsetup close "$SECONDARY_LVM_PARTITION_NAME"
systemctl reboot
