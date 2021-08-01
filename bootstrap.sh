# Requirements:
# 1. Internet connection
# 2. Partitioned disks.

set -e


DISK="/dev/sda"

EFI_NUMBER=1
SWAP_NUMBER=2
ROOT_NUMBER=3
ZONE="Europe/Moscow"
POST_PATH="/root/arch-post.sh"

cat $POST_PATH > /dev/null  # Ensure post is present

# Cleanup
umount -R /mnt || echo Not mounted
swapoff -a


timedatectl set-ntp true

# Prepare disks
mkfs.ext4 $DISK$ROOT_NUMBER
mkfs.fat -F 32 $DISK$EFI_NUMBER
mkswap $DISK$SWAP_NUMBER
swapon $DISK$SWAP_NUMBER

mount $DISK$ROOT_NUMBER /mnt
mkdir -p /mnt/efi
mount $DISK$EFI_NUMBER /mnt/efi

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

# CHROOT
arch-chroot /mnt "/bin/bash" $POST_PATH

umount -R /mnt

echo
echo
echo All Done. Type "reboot" to enjoy!
