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

EFI_NUMBER=1
SWAP_NUMBER=2
ROOT_NUMBER=3
ZONE="Europe/Moscow"
POST_PATH="/root/arch-post.sh"

# Ensure arch-post is present
cat $POST_PATH > /dev/null

# Cleanup from previous runs if there were any.
umount -R /mnt || test 1
swapoff -a || test 1

timedatectl set-ntp true

# Prepare disks
mkfs.ext4 $DISK$ROOT_NUMBER
mkfs.fat -F 32 $DISK$EFI_NUMBER
mkswap $DISK$SWAP_NUMBER
swapon $DISK$SWAP_NUMBER

# Mount
mount $DISK$ROOT_NUMBER /mnt
mkdir -p /mnt/efi
mount $DISK$EFI_NUMBER /mnt/efi


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
    npm \
    htop \
    networkmanager \
    gdm \
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
