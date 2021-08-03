# Requirements:
# 1. Internet connection
# 2. Partitioned disks.

set -e

echo "Prior to running this script please partition disk like following"
echo "    EFI partition: /dev/sda1"
echo "    swap partition: /dev/sda2"
echo "    root partition: /dev/sda3"
echo
echo "Now enter disk root name (example /dev/sda):"
read -p ">>> " DISK
echo "Will be using $DISK"
echo "$DISK will be wiped in 10 seconds. Press Ctrl + C if want to cancel."
sleep 10

PARTITIONS_LIST=$(fdisk -l $DISK -o Device | grep $DISK | grep -v "Disk\|Sectors")
EFI_NUMBER=1
SWAP_NUMBER=2
ROOT_NUMBER=3
EFI_PARTITION=$(echo "$PARTITIONS_LIST" | grep "$EFI_NUMBER"$)
SWAP_PARTITION=$(echo "$PARTITIONS_LIST" | grep "$SWAP_NUMBER"$)
ROOT_PARTITION=$(echo "$PARTITIONS_LIST" | grep "$ROOT_NUMBER"$)

ZONE="Europe/Moscow"
POST_PATH="/root/arch-post.sh"

# Ensure arch-post is present
cat $POST_PATH > /dev/null

# Cleanup from previous runs if there were any.
umount -R /mnt || test 1
swapoff -a || test 1

timedatectl set-ntp true

# Prepare disks
mkfs.ext4 $ROOT_PARTITION
mkfs.fat -F 32 $EFI_PARTITION
mkswap $SWAP_PARTITION
swapon $SWAP_PARTITION

# Mount
mount $ROOT_PARTITION /mnt
mkdir -p /mnt/efi
mount $EFI_PARTITION /mnt/efi


# Bootstrap
pacstrap /mnt \
    base \
    linux \
    linux-firmware \
    neovim \
    git \
    stow \
    wget \
    curl \
    xorg \
    sudo \
    grub \
    efibootmgr \
    htop \
    networkmanager \
    alacritty \
    lm_sensors \
    stress \
    deja-dup \
    rustup \
    go \
    tmux \
    zsh \
    docker

genfstab -U /mnt >> /mnt/etc/fstab

cp $POST_PATH /mnt$POST_PATH

# chroot and execute chroot script.
arch-chroot /mnt "/bin/bash" $POST_PATH

umount -R /mnt

echo
echo
echo All Done. Type "reboot" to enjoy!
