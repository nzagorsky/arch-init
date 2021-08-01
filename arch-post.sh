set -e

echo "Enter your username"
read -p ">>> " user
HOSTNAME=$user-pc
USERNAME=$user

# Add user and set passwords
useradd -m -G wheel -s /bin/bash $USERNAME
echo "Setting password for ROOT"
passwd
echo "Setting password for $USERNAME"
passwd $USERNAME

# Setup clock
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

# Enable services
systemctl enable gdm 2> /dev/null || test 1
systemctl enable bluetooth 2> /dev/null || test 1
systemctl enable systemd-networkd
systemctl enable systemd-resolved
systemctl enable NetworkManager.service
systemctl enable docker

echo "Setup is finished"
echo "Exiting chroot"
