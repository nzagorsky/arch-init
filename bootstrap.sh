# Requirements:
# 1. Internet connection
# 2. Partitioned disks.
set -e

ZONE="Europe/Moscow"
POST_PATH="/root/arch-post.sh"

# Ensure arch-post.sh is present
cat $POST_PATH > /dev/null

echo "Prior to running this script please partition disk like following"
echo "    EFI partition: /dev/sda1"
echo "    swap partition: /dev/sda2"
echo "    root partition: /dev/sda3"
echo
echo "OR in case of no EFI support"
echo "    swap partition: /dev/sda1"
echo "    root partition: /dev/sda2"
echo
echo "Now enter disk root name (example /dev/sda):"
read -p ">>> " DISK
echo "Will be using $DISK"
echo "$DISK will be wiped in 10 seconds. Press Ctrl + C if want to cancel."
sleep 10


init() {
    timedatectl set-ntp true
}

prepare_disk() {
    # Cleanup from previous runs if there were any.
    umount -R /mnt || test 1
    swapoff -a || test 1

    PARTITIONS_LIST=$(fdisk -l $DISK -o Device | grep $DISK | grep -v "Disk\|Sectors")
    PARTITION_TYPE=$(parted /dev/sda print | grep "Partition Table" | awk '{print $3}')

    if ls /sys/firmware/efi/efivars > /dev/null 2>&1; then
        EFI_PARTITION=$(echo "$PARTITIONS_LIST" | grep 1$)
        SWAP_PARTITION=$(echo "$PARTITIONS_LIST" | grep 2$)
        ROOT_PARTITION=$(echo "$PARTITIONS_LIST" | grep 3$)
        mkfs.fat -F 32 $EFI_PARTITION
    else
        if [ "$PARTITION_TYPE" = "gpt" ]; then
            echo "You're trying to use GPT on non-EFI system, this is not supported"
            exit 1
        fi;

        SWAP_PARTITION=$(echo "$PARTITIONS_LIST" | grep 1$)
        ROOT_PARTITION=$(echo "$PARTITIONS_LIST" | grep 2$)
    fi;

    mkfs.ext4 $ROOT_PARTITION
    mkswap $SWAP_PARTITION
    swapon $SWAP_PARTITION

    # Mount
    mount $ROOT_PARTITION /mnt
    mkdir -p /mnt/efi

    if ls /sys/firmware/efi/efivars > /dev/null 2>&1; then
        mount $EFI_PARTITION /mnt/efi
    fi;


}

bootstrap() {
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
        which \
        efibootmgr \
        htop \
        networkmanager \
        alacritty \
        lm_sensors \
        stress \
        tmux \
        zsh \
        docker

    genfstab -U /mnt >> /mnt/etc/fstab
    cp $POST_PATH /mnt$POST_PATH
}

finalize() {
    umount -R /mnt

    echo
    echo
    echo All Done. Type "reboot" to enjoy!
}


### ACTUAL SCRIPT ###

init
prepare_disk
bootstrap

arch-chroot /mnt "/bin/bash" $POST_PATH

finalize
