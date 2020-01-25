#! /bin/bash



function yes-no-input {
#  requires that variables "prompt" "message" and "verify" are set
while true 
   do
     # (1)read command line argument
     printf "$prompt"     
     if [ $verify == "true" ]
     then
        read returnanswer          
        read -p "You entered \" $returnanswer \" is this correct? [y,n,q] :" answer
     else
        read answer
        returnanswer=$answer 
     fi
     # (2) handle the input we were given
     # if y then continue, if n then exit script with $message
     case $answer in
      [yY]* ) printf "\n"
              break;;

      [nN]* ) if [ $verify == "true" ]
              then
                 printf "$message\n"
                 true="false"
              else
                 printf "$message\n"
                 exit
              fi
              ;;

      [qQ]* ) exit
              ;;

      * )     if [ $verify == "true" ]
              then
                 printf "\nTry again.\n"
              else 
                 printf "\nTry again, Enter [y,n] :\n"
              fi
              true="false"
              ;;
   esac
done

}    # end of function yes-no-input


function simple-yes-no {
# requires that the variable "prompt" be set 
while true 
do
      printf "$prompt"
      read answer 
      
      case $answer in

      [yY]* ) returnanswer=$answer
              break
              ;;

       [nN]* ) returnanswer=$answer
              break
              ;;

      [qQ]* ) exit
              ;;  

      * )     printf "\nTry again, Enter [y,n] :\n"
              true="false"
              ;;
   esac
done
}   # end of function  simple-yes-no


#################################################
# beginning of script
#################################################

# Declare following global variables
let uefibootstatus=20
let returnanswer="a"
let prompt="b"
let message="c"
let verify="d"
let devicename="e"
let sshport=3
let username="a"

# determine if msdos or uefi 
ls /sys/firmware/efi/efivars  > /dev/null 2>/dev/null
if [ $? == "0" ]
then
   uefibootstatus=1
else
   uefibootstatus=0
fi

# read in devicename passed by install-base1.sh to /mnt/root
file="/root/device-name"
read -d $'\x04' devicename < "$file"


printf "\033c"; printf "\n"
ls /usr/share/zoneinfo
printf "\n\nCountry codes are CASE SENSITIVE and must be entered exactly as above\n"

prompt="Enter your country code from the above list: "
message="\nTry again."
verify="true"
yes-no-input
country=$returnanswer
file="/root/device-name"
read -d $'\x04' devicename < "$file"

printf "\033c";printf "\n"
ls /usr/share/zoneinfo/$country
printf "\n\nTime Zones are case sensitive and must be entered exactly as above\n"
prompt="Enter your time zone from the above list: "
message="\nTry again."
verify="true"
yes-no-input
zone=$returnanswer

ln -sf /usr/share/zoneinfo/$country/$zone /etc/localtime

hwclock --systohc

sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen
printf "\nLANG=en_US.UTF-8\n\n" > /etc/locale.conf 

prompt="Enter your desired hostname: "
message="\nTry again."
verify="true"
yes-no-input
hostname=$returnanswer

printf "\n\nSetting hostname\n\n"
printf "\n$hostname\n\n" > /etc/hostname

printf "\n\nSetting up /etc/hosts\n\n"
printf "\n127.0.0.1\tlocalhost\n" > /etc/hosts
printf "::1\t\tlocalhost\n" >> /etc/hosts
printf "127.0.1.1\t$hostname.localdomain\t$hostname\n\n" >> /etc/hosts

printf "\n\nRunning mkinitcpio\n\n"
mkinitcpio -P


printf "\nEnter your root password\n\n"

finished=1
while [ $finished -ne 0 ]
do
  if passwd ; then
      finished=0 ; echo
   else
      finished=1 ; printf "\nPassword entry failed, try again\n\n"
   fi
done

# do ENDEAVOUROS BRANDING in the grub menu and console window prompt
sed -i '/^GRUB_DISTRIBUTOR=/c\GRUB_DISTRIBUTOR="EndeavourOS"' /etc/default/grub
sed -i 's/Arch/EndeavourOS/' /etc/issue

printf "\n\nInstalling grub\n\n"

if [ $uefibootstatus == 1 ]
then
   grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=EndeavourOS --recheck
else
   grub-install --target=i386-pc $devicename --recheck
fi
grub-mkconfig -o /boot/grub/grub.cfg

printf "\ninstalling endeavoros-keyring\n\n"

curl https://github.com/endeavouros-team/mirrors/releases/tag/mirror2 |grep endeavouros-keyring |sed s'/^.*endeavouros-keyring/endeavouros-keyring/'g | sed s'/pkg.tar.xz.*/pkg.tar.xz/'g |tail -1 > /root/keys
file="/root/keys"
read -d $'\04' currentkeyring < "$file"
wget https://github.com/endeavouros-team/mirrors/releases/download/mirror2/$currentkeyring
pacman -U $currentkeyring


printf "installing endeavouros-mirrorlist\n\n"

curl https://github.com/endeavouros-team/mirrors/releases/tag/mirror2 |grep endeavouros-mirrorlist |sed s'/^.*endeavouros-mirrorlist/endeavouros-mirrorlist/'g | sed s'/pkg.tar.xz.*/pkg.tar.xz/'g |tail -1 > /root/mirrors

file="/root/mirrors"
read -d $'\x04' currentmirrorlist < "$file"
wget https://github.com/endeavouros-team/mirrors/releases/download/mirror2/$currentmirrorlist
pacman -U $currentmirrorlist

printf "\n[endeavouros]\nSigLevel = PackageRequired\nInclude = /etc/pacman.d/endeavouros-mirrorlist\n\n" >> /etc/pacman.conf

prompt="Important: Did endeavouros-keyring and endeavouros-mirrorlist install correctly [y,n,q] "
simple-yes-no

if [ $returnanswer == "y" ] || [ $returnanswer == "Y" ]
then
   printf "\n\n"
else
   printf "\n\nExiting installer\n\n"
   exit  
fi

pacman -Sq --noconfirm yay

printf "\nCreating ll alias\n"
printf "\nalias ll='ls -l --color=auto'\n\n" >> /etc/bash.bashrc

printf "\nCreating a user\n\n"

prompt="Enter your desired user name: "
message="\nTry again."
verify="true"
yes-no-input
username=$returnanswer

useradd -m -G users -s /bin/bash $username

finished=1
while [ $finished -ne 0 ]
do
  if passwd $username ; then
      finished=0 ; echo
   else
      finished=1 ; printf "\nPassword entry failed, try again\n\n"
   fi
done

# setup static IP address with user supplied static IP

ethernetdevice=$( ip r | grep "default via" | awk '{print $5}')
routerip=$( ip r | grep "default via" | awk '{print $3}')

threetriads=$routerip
xyz=${threetriads#*.*.*.}
threetriads=${threetriads%$xyz}
printf "\nSETTING UP THE STATIC IP ADDRESS FOR THE SERVER\n"
finished=1
while [ $finished -ne 0 ]
do
   printf "\nThe last triad should be between 100 and 245\n"   
   printf "Enter the last triad of the desired static IP address $threetriads"
   read lasttriad
   staticip=$threetriads$lasttriad
   printf "you entered $staticip is that correct? [y/n] "
   read z
   if [ $lasttriad -lt 100 ] || [ $lasttriad -gt 245 ]
   then
      printf "\nYour choice is out of range"
      z=n
   fi
   if [ $z == "y" ] || [ $z == "Y" ]
   then
       finished=0
   else 
       printf "\nPlease try again."
   fi
done

staticip+="/24"
printf "Description='A basic static internet connection'" > /etc/netctl/ethernet-static
printf "\nInterface=$ethernetdevice" >> /etc/netctl/ethernet-static
printf "\nConnection=ethernet\nIP=static" >> /etc/netctl/ethernet-static
printf "\nAddress=('$staticip')"  >> /etc/netctl/ethernet-static
printf "\n#Routes=('192.168.0.0/24 via 192.168.1.2')" >> /etc/netctl/ethernet-static
printf "\nGateway=('$routerip')" >> /etc/netctl/ethernet-static
printf "\nDNS=('$routerip' '8.8.8.8')\n" >> /etc/netctl/ethernet-static
printf "\n## For IPv6 autoconfiguration\n#IP6=stateless\n" >> /etc/netctl/ethernet-static
printf "\n## For IPv6 static address configuration\n#IP6=static"  >> /etc/netctl/ethernet-static
printf "\n#Address6=('1234:5678:9abc:def::1/64' '1234:3456::123/96')" >> /etc/netctl/ethernet-static
printf "\n#Routes6=('abcd::1234')\n#Gateway6='1234:0:123::abcd'\n" >> /etc/netctl/ethernet-static
cd /etc/netctl
netctl start ethernet-static
netctl enable ethernet-static
cd /root


printf "\nEstablish the SSH port number\n\n"
finished=1
while [ $finished -ne 0 ]
do
      
   printf "Enter the desired SSH port between 8000 and 48000: "
   read sshport
   printf "you entered $sshport is that correct? [y/n] "
   read z
   if [ $sshport -lt 8000 ] || [ $sshport -gt 48000 ]
   then
      printf "\nYour choice is out of range"
      z=n
   fi
   if [ $z == "y" ] || [ $z == "Y" ]
   then
       finished=0
   else 
       printf "\nPlease try again."
   fi
done

sed -i "/Port 22/c Port $sshport" /etc/ssh/sshd_config
sed -i '/PermitRootLogin/c PermitRootLogin no' /etc/ssh/sshd_config
sed -i '/PasswordAuthentication/c PasswordAuthentication yes' /etc/ssh/sshd_config
sed -i '/PermitEmptyPasswords/c PermitEmptyPasswords no' /etc/ssh/sshd_config

systemctl disable sshd.service
systemctl enable sshd.service

ufw logging off
ufw default deny
ufw enable
systemctl enable ufw.service

rm /root/install-base2.sh

printf "\n\nInstallation is complete.\n\n"
printf "Pressing any key will exit arch-chroot and terminate the script.\n"
printf "At the liveuser prompt, enter \"sudo umount -a\" to unmount the /mnt filesystem.\n"
printf "Ignore any errors from the umount command.\n"
printf "\nPower off your System, remove install media and boot up\nPress any key to continue \n\n"
read -n1 x
exit
