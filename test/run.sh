# Script launches SSH with livecd of Arch.

rm -rf /tmp/.archiso.hosts
touch /tmp/.archiso.hosts

ISO=arch.iso
IMAGE=testdisk.img

### FUNCTIONS  ###

get_iso() {
    if ! test -f "$ISO"; then
        wget "https://mirror.yandex.ru/archlinux/iso/2021.08.01/archlinux-2021.08.01-x86_64.iso" -O $ISO
    fi
}

get_disk() {
    if ! test -f "$IMAGE"; then
        qemu-img create -f qcow2 $IMAGE 10G
    fi
}


setup_vm() {
    ( cat ) | qemu-system-x86_64 \
        -boot d \
        -enable-kvm \
        -cdrom $ISO \
        -m 4G \
        -drive file=$IMAGE,format=qcow2 \
        -vga virtio \
        -smp 4 \
        -net user,hostfwd=tcp::10022-:22 \
        -net nic \
        -display default,show-cursor=on \
        -monitor stdio &

    server_pid=$!
    echo $server_pid

    sleep 5  # Wait till it gets to grub
    echo 'sendkey ret' > "/proc/$server_pid/fd/0"
    sleep 30  # Wait till it boots

    # Ugliest possible way to execute `passwd`
    echo 'sendkey e' > "/proc/$server_pid/fd/0"
    echo 'sendkey c' > "/proc/$server_pid/fd/0"
    echo 'sendkey h' > "/proc/$server_pid/fd/0"
    echo 'sendkey o' > "/proc/$server_pid/fd/0"
    echo 'sendkey spc' > "/proc/$server_pid/fd/0"
    echo 'sendkey apostrophe' > "/proc/$server_pid/fd/0"
    echo 'sendkey p' > "/proc/$server_pid/fd/0"
    echo 'sendkey backslash' > "/proc/$server_pid/fd/0"
    echo 'sendkey n' > "/proc/$server_pid/fd/0"
    echo 'sendkey p' > "/proc/$server_pid/fd/0"
    echo 'sendkey apostrophe' > "/proc/$server_pid/fd/0"
    echo 'sendkey spc' > "/proc/$server_pid/fd/0"
    echo 'sendkey shift-backslash' > "/proc/$server_pid/fd/0"
    echo 'sendkey spc' > "/proc/$server_pid/fd/0"
    echo 'sendkey p' > "/proc/$server_pid/fd/0"
    echo 'sendkey a' > "/proc/$server_pid/fd/0"
    echo 'sendkey s' > "/proc/$server_pid/fd/0"
    echo 'sendkey s' > "/proc/$server_pid/fd/0"
    echo 'sendkey w' > "/proc/$server_pid/fd/0"
    echo 'sendkey d' > "/proc/$server_pid/fd/0"
    echo 'sendkey spc' > "/proc/$server_pid/fd/0"
    echo 'sendkey ret' > "/proc/$server_pid/fd/0"
    sleep 5
}

test_setup() {
    read -N 10000000 -t 0.01  # Clean stdio
    echo 
    sshpass -p p ssh-copy-id -p 10022 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/tmp/.archiso.hosts -p 10022 root@localhost
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/tmp/.archiso.hosts -p 10022 root@localhost echo Instance launch success!

    # Copy scripts.
    scp -P 10022 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/tmp/.archiso.hosts  ../bootstrap.sh root@localhost:/root/bootstrap.sh
    scp -P 10022 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/tmp/.archiso.hosts  ../arch-post.sh root@localhost:/root/arch-post.sh
    scp -P 10022 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/tmp/.archiso.hosts  bootstrap_config root@localhost:/root/bootstrap_config

    # ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/tmp/.archiso.hosts -p 10022 root@localhost  #  TODO debug remove me
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/tmp/.archiso.hosts -p 10022 root@localhost "bash bootstrap.sh"


    sleep 36000 || kill $server_pid

}

### SCRIPT ###

get_iso
get_disk
setup_vm
test_setup
