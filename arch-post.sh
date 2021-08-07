set -e

CONFIG_PATH="/root/bootstrap_config"
source $CONFIG_PATH

# Add user and set passwords
setup_user() {
    USERNAME=$USERNAME
    useradd -m -G wheel -s /bin/bash $USERNAME
    echo "Setting password for ROOT"
    echo -e "$PASSWORD\n$PASSWORD" | passwd
    echo "Setting password for $USERNAME"
    echo -e "$PASSWORD\n$PASSWORD" | passwd $USERNAME
    usermod -aG docker $USERNAME
    chsh $USERNAME -s $(which zsh)

    # Sudo
    echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
}

setup_system() {
    HOSTNAME=$USERNAME-pc

    # Setup clock
    ln -sf /usr/share/zoneinfo/$ZONE /etc/localtime
    hwclock --systohc

    # Locale
    echo LANG=en_US.UTF-8 > /etc/locale.conf
    sed --in-place=.bak 's/^#en_US\.UTF-8/en_US\.UTF-8/' /etc/locale.gen
    locale-gen

    echo $HOSTNAME > /etc/hostname

    if ls /sys/firmware/efi/efivars > /dev/null 2>&1; then
        grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ARCH
    else
        ROOT_PARTITION_NAME=$(df -hT | grep /$ | awk '{print $1}')
        ROOT_DISK_NAME="/dev/$(lsblk -no pkname $ROOT_PARTITION_NAME)"
        grub-install --target=i386-pc --recheck $ROOT_DISK_NAME
    fi;

    grub-mkconfig -o /boot/grub/grub.cfg
}

enable_services() {
    # Enable services
    systemctl enable gdm 2> /dev/null || test 1
    systemctl enable bluetooth 2> /dev/null || test 1
    systemctl enable systemd-resolved
    systemctl enable NetworkManager.service
    systemctl enable docker
}

finalize() {
    rm $CONFIG_PATH  || echo "Failed to delete $CONFIG_PATH"
}

setup_user
setup_system
enable_services
finalize

echo "Setup is finished!"
echo "Exiting chroot."
