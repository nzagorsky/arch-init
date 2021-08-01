read -p 'Enter machine address' MACHINE_ADDRESS

touch /tmp/arch-install-auth-ssh

ssh-copy-id -o UserKnownHostsFile=/tmp/arch-install-auth-ssh root@$MACHINE_ADDRESS

scp -o UserKnownHostsFile=/tmp/arch-install-auth-ssh bootstrap.sh root@$MACHINE_ADDRESS:/root/bootstrap.sh
scp -o UserKnownHostsFile=/tmp/arch-install-auth-ssh arch-post.sh root@$MACHINE_ADDRESS:/root/arch-post.sh

ssh -o UserKnownHostsFile=/tmp/arch-install-auth-ssh root@$MACHINE_ADDRESS 'bash bootstrap.sh'
