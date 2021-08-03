# Requirements:
# 1. Internet connection
# 2. Partitioned disks.
set -e

ZONE="Europe/Moscow"
POST_PATH="/root/arch-post.sh"
CONFIG_PATH="/root/bootstrap_config"

# Ensure arch-post.sh is present
cat $POST_PATH > /dev/null
source $CONFIG_PATH || echo No config found

get_disk() {
    if [ -z ${DISK+x} ];
    then
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
    else
        echo "Disk name taken from config";
    fi

    echo "Will be using $DISK"
    echo "$DISK will be wiped in 10 seconds. Press Ctrl + C if want to cancel."
    sleep 10
}


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

        # TODO calculate swap size automatically
        wipefs -a $DISK
        yes | parted $DISK mklabel gpt
        yes | parted $DISK mkpart P1 fat32 1MiB 257MiB
        yes | parted $DISK set 1 esp on
        yes | parted $DISK mkpart P2 linux-swap 257MiB 2305MiB
        yes | parted $DISK mkpart P3 ext4 2305MiB 100%

        mkfs.fat -F 32 $EFI_PARTITION
    else
        wipefs -a $DISK
        yes | parted $DISK mklabel msdos
        yes | parted $DISK mkpart primary linux-swap 257MiB 2305MiB
        yes | parted $DISK mkpart primary ext4 2305MiB 100%

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

# TODO add xfce4 and startx config
bootstrap() {
    # Set mirrors
    rm -rf /var/lib/pacman/sync/
    reflector -c Russia > /etc/pacman.d/mirrorlist
    pacman -Syy

    # Bootstrap
    pacstrap /mnt \
        base \
        linux \
        linux-firmware \
        reflector \
        neovim \
        git \
        stow \
        wget \
        curl \
        xorg \
        xorg-xinit \
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
    cp $CONFIG_PATH /mnt$CONFIG_PATH
}

finalize() {
    umount -R /mnt
    rm $POST_PATH
    rm $CONFIG_PATH

    echo
    echo
    echo All Done. Type "reboot" to enjoy!
}


### ACTUAL SCRIPT ###

init
get_disk
prepare_disk
bootstrap

arch-chroot /mnt "/bin/bash" $POST_PATH

finalize
