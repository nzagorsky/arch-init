set -e

read -p "Enter your username" user
HOSTNAME=$user-pc
USERNAME=$user


useradd -m -G wheel -s /bin/bash $USERNAME
echo "Setting password for ROOT"
passwd
echo "Setting password for $USERNAME"
passwd $USERNAME

# Clock
ln -sf /usr/share/zoneinfo/$ZONE /etc/localtime
hwclock --systohc

# Locale
echo LANG=en_US.UTF-8 > /etc/locale.conf
sed --in-place=.bak 's/^#en_US\.UTF-8/en_US\.UTF-8/' /etc/locale.gen
locale-gen

# Hostname
echo $HOSTNAME > /etc/hostname

# Bootloader
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg


# Sudo
echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
usermod -aG docker $USERNAME

# mkinitcpio -P

# Enable services
systemctl enable gdm
systemctl enable bluetooth || echo "No bluetooth"
systemctl enable systemd-networkd
systemctl enable systemd-resolved
systemctl enable NetworkManager.service
systemctl enable docker
