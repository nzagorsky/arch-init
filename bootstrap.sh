# Requirements:
# 1. Internet connection
# 2. Partitioned disks.
set -e

ZONE="Europe/Moscow"
POST_PATH="/root/arch-post.sh"
CONFIG_PATH="/root/bootstrap_config"

# Ensure arch-post.sh is present
cat $POST_PATH > /dev/null

update_mirrors_and_install_deps() {
    # Set mirrors
    rm -rf /var/lib/pacman/sync/
    reflector -c Russia > /etc/pacman.d/mirrorlist
    pacman -Syy

    pacman -S --needed --noconfirm dialog
}

gather_config() {
	name=$(dialog --inputbox "First, please enter a name for the user account." 10 60 3>&1 1>&2 2>&3 3>&1) || exit 1
	while ! echo "$name" | grep -q "^[a-z_][a-z0-9_-]*$"; do
		name=$(dialog --no-cancel --inputbox "Username not valid. Give a username beginning with a letter, with only lowercase letters, - or _." 10 60 3>&1 1>&2 2>&3 3>&1)
	done;

	pass1=$(dialog --no-cancel --passwordbox "Enter a password for that user." 10 60 3>&1 1>&2 2>&3 3>&1)
	pass2=$(dialog --no-cancel --passwordbox "Retype password." 10 60 3>&1 1>&2 2>&3 3>&1)
	while ! [ "$pass1" = "$pass2" ]; do
		unset pass2
		pass1=$(dialog --no-cancel --passwordbox "Passwords do not match.\\n\\nEnter password again." 10 60 3>&1 1>&2 2>&3 3>&1)
		pass2=$(dialog --no-cancel --passwordbox "Retype password." 10 60 3>&1 1>&2 2>&3 3>&1)
	done ;

    disk=$(dialog --inputbox "Enter disk name to destroy and install stuff to.\\n\\nExample: /dev/sda" 10 60 3>&1 1>&2 2>&3 3>&1)
	while ! ls $disk; do
		disk=$(dialog --no-cancel --inputbox "Disk path is not valid. \\n\\nProper disk example: /dev/sda OR /dev/nvme0n1" 10 60 3>&1 1>&2 2>&3 3>&1)
    done;

    printf "export USERNAME=$name\nexport PASSWORD=$pass1\nexport DISK=$disk" > $CONFIG_PATH
}

get_disk() {
    echo
    echo "'$DISK' will be wiped in 10 seconds. Press Ctrl + C if you want to cancel."
    sleep 10
}


init() {
    timedatectl set-ntp true
}

# TODO calculate swap size automatically or take as a user input
prepare_disk() {
    # Cleanup from previous runs if there were any.
    umount -R /mnt || test 1
    swapoff -a || test 1

    if ls /sys/firmware/efi/efivars > /dev/null 2>&1; then
        wipefs -a $DISK
        yes | parted $DISK mklabel gpt
        yes | parted $DISK mkpart P1 fat32 1MiB 257MiB
        yes | parted $DISK set 1 esp on
        yes | parted $DISK mkpart P2 linux-swap 257MiB 2305MiB
        yes | parted $DISK mkpart P3 ext4 2305MiB 100%

        PARTITIONS_LIST=$(fdisk -l $DISK -o Device | grep $DISK | grep -v "Disk\|Sectors")
        EFI_PARTITION=$(echo "$PARTITIONS_LIST" | grep 1$)
        SWAP_PARTITION=$(echo "$PARTITIONS_LIST" | grep 2$)
        ROOT_PARTITION=$(echo "$PARTITIONS_LIST" | grep 3$)
        mkfs.fat -F 32 $EFI_PARTITION
    else
        wipefs -a $DISK
        yes | parted $DISK mklabel msdos
        yes | parted $DISK mkpart primary linux-swap 257MiB 2305MiB
        yes | parted $DISK mkpart primary ext4 2305MiB 100%

        PARTITIONS_LIST=$(fdisk -l $DISK -o Device | grep $DISK | grep -v "Disk\|Sectors")
        SWAP_PARTITION=$(echo "$PARTITIONS_LIST" | grep 1$)
        ROOT_PARTITION=$(echo "$PARTITIONS_LIST" | grep 2$)
    fi;

    mkfs.ext4 $ROOT_PARTITION
    mkswap $SWAP_PARTITION
    swapon $SWAP_PARTITION

    # Mount
    mount $ROOT_PARTITION /mnt
    mkdir -p /mnt/boot/efi

    if ls /sys/firmware/efi/efivars > /dev/null 2>&1; then
        mount $EFI_PARTITION /mnt/boot/efi
    fi;


}

bootstrap() {
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
        gnome \
        gnome-extra \
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
update_mirrors_and_install_deps
echo "Starting gathering"
if [ ! -f $CONFIG_PATH ]; then
    echo "Started gathering"
    gather_config
fi
source $CONFIG_PATH
init
get_disk
prepare_disk
bootstrap

arch-chroot /mnt "/bin/bash" $POST_PATH

finalize
