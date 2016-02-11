#!/bin/sh

. $('pwd')/config.sh

############################################################################
## check if directory exists

if [ -d "$container_dir" ]; then
 echo "There is a container with name $container_name! exiting.... "
 exit
fi

# LAMP

##############################

# L (linux)
## make project dir
mkdir -p $container_dir/var/lib/rpm
rpm --rebuilddb --root=$container_dir/var/lib/rpm
yumdownloader --destdir=$container_dir/var/lib/rpm centos-release
rpm -ivh --root=$container_dir --nodeps $container_dir/var/lib/rpm/centos-release*.rpm
yum --installroot=$container_dir install -y rpm-build yum
yum --installroot=$container_dir install -y passwd bash centos-release vim git
yum --installroot=$container_dir groupinstall -y "Minimal Install"
yum --installroot=$container_dir install -y openssh-server
echo root:$container_root_password | chroot $container_dir chpasswd



### example install something (httpd)
### yum --installroot=$container_dir install -y httpd

yum --installroot=$container_dir clean all

chroot $container_dir systemctl enable sshd

### Make it as service (in host)

cat > /etc/systemd/system/$container_name\.service <<EOF
[Unit]
Description=Automatic generated container $container_name

[Service]
ExecStart=/usr/bin/systemd-nspawn -bD $container_dir
KillMode=process
EOF

######### SSHD
if [ -z "$container_sshd_port" ]
then
        echo  "No ssh port enabled. skipping...."
else
        echo  "Setting up ssh for the container..."
        echo "Port ${container_sshd_port}" >> ${container_dir}/etc/ssh/sshd_config
fi

################################################

# Enable services

## GENERATING SSH KEY
echo "Generating host-to-container ssh key"
rm -rf .ssh/
mkdir .ssh/
ssh-keygen -t rsa -f .ssh/$container_name -N ''
## Making ssh directory
mkdir $container_dir/root/.ssh/
chmod 700 $container_dir/root/.ssh/
cp .ssh/$container_name.pub $container_dir/root/.ssh/authorized_keys




## Start the service (in host machine)

systemctl daemon-reload
systemctl enable $container_name
systemctl start $container_name


