# Usage: 
# curl -sfL git.io/JB9ki > run.sh
# bash run.sh

curl --silent https://raw.githubusercontent.com/nzagorsky/arch-init/master/bootstrap.sh --output /root/bootstrap.sh
curl --silent https://raw.githubusercontent.com/nzagorsky/arch-init/master/arch-post.sh --output /root/arch-post.sh

bash bootstrap.sh
