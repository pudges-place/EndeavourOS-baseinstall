#!/bin/bash

function ok-nok {
# Requires that variables "message" be set
status=$?
if [[ $status -eq 0 ]]
then
  printf "${GREEN}$message OK${NC}\n"
  printf "$message OK\n" >> logfile2
else
  printf "${RED}$message   FAILED${NC}\n"
  printf "$message FAILED\n" >> logfile2
  printf "\n\nLogs are stored in: logfile2/n"
  exit 1
fi
sleep 1
}	# end of function ok-nok

function gettzentry {
# requires that the variable directory be set prior to call
# after call data needs to be pulled from entry after the call
if [ "$directory" != "$tzsource" ]
then
   printf "\033c"; printf "\n"
fi
ls $directory
finished=1
while [ $finished -ne 0 ]
do
   printf "\nTime Zone entries are case sensitive and must be entered exactly as above\n"
   printf "Enter your time zone item from the above list: "
   read entry
   if [ "$entry" == "" ] ; then entry="emptyentry" ; fi
   xyz=$(ls $directory | grep -x $entry) 
   if [ "$entry" == "$xyz" ]
   then
      finished=0
      timezonepath=$directory/$entry
      printf "\n"
   else
      printf "\nYour entry did not match an item in the list. Please try again\n"
   fi
done
}   # end of function gettzentry


function simple-yes-no {
# Requires that variable "prompt" be set
while true 
do
      printf "$prompt"
      read answer 
      answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
      case $answer in

      [y]* ) returnanswer=$answer
              break
              ;;

       [n]* ) returnanswer=$answer
              break
              ;;

      [q]* ) exit
              ;;  

      * )     printf "\nTry again, Enter [y,n] :\n"
              true="false"
              ;;
   esac
done
}   # end of function  simple-yes-no


#################################################
# beginning of script 2
#################################################


# Declare following global variables
uefibootstatus=20
returnanswer="a"
prompt="b"
message="c"
verify="d"
osdevicename="e"
sshport=3
username="a"

# Declare color variables
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# create emppy logfile2
printf "    LOGFILE 2\n\n" > logfile2


# determine if msdos or uefi 
ls /sys/firmware/efi/efivars  > /dev/null 2>/dev/null
if [ $? == "0" ]
then
   uefibootstatus=1
else
   uefibootstatus=0
fi

# read in devicename passed by install-base1.sh to /mnt/root
file="/root/osdevice-name"
read -d $'\x04' osdevicename < "$file"

################   Begin user input  #######################
userinputdone=1
while [ $userinputdone -ne 0 ]
do 

   printf "\033c"; printf "\n"
   printf "Tip: When entering a Time Zone item, hover the mouse over the desired entry,\n"
   printf "double left click on the item to highlight it, then center click.\n"
   printf "This is not only faster, but eliminates typing errors.\n\n"
   country=""; zone=""; city=""; city2=""
   
   tzsource=/usr/share/zoneinfo

   directory=$tzsource
   if [ -d $directory ]
   then
      gettzentry   # function call
      country=$entry    
   fi

   directory=$tzsource/$country
   if  [ -d $directory ]
   then   
      gettzentry   # function call
      zone=$entry
   fi

   directory=$tzsource/$country/$zone
   if [ -d $directory ]
   then
      gettzentry   # function call
      city=$entry
   fi

   directory=$tzsource/$country/$zone/$city
   if [ -d $directory ]
   then
      gettzentry   # function call
      city2=$entry
   fi 

   finished=1
   while [ $finished -ne 0 ]
   do
      printf "\nEnter your desired hostname: "
      read host_name
      if [ "$host_name" == "" ] 
      then
         printf "\nEntry is empty, try again\n"
      else
          finished=0
      fi  
   done

   finished=1
   while [ $finished -ne 0 ]
   do 
      printf "\nEnter your desired user name: "
      read username
      if [ "$username" == "" ]
      then
         printf "\nEntry is empty, try again\n"
      else     
         finished=0
      fi
   done

   finished=1
   while [ $finished -ne 0 ]
   do
      printf "\nEnter the desired SSH port between 8000 and 48000: "
      read sshport
   if [ "$sshport" -eq "$sshport" ] # 2>/dev/null
      then
           if [ $sshport -lt 8000 ] || [ $sshport -gt 48000 ]
           then
              printf "\nYour choice is out of range, try again\n"
           else
              finished=0
           fi
      else
           printf "\nYour choice is not a number, try again\n"
      fi
   done

   ethernetdevice=$(ip r | awk 'NR==1{print $5}')
   routerip=$(ip r | awk 'NR==1{print $3}')
   threetriads=$routerip
   xyz=${threetriads#*.*.*.}
   threetriads=${threetriads%$xyz}
   printf "\nSETTING UP THE STATIC IP ADDRESS FOR THE SERVER\n"
   finished=1
   while [ $finished -ne 0 ]
   do
      printf "\nThe last octet should be between 101 and 250\n"   
      printf "Enter the last octet of the desired static IP address $threetriads"
      read lasttriad
      if [ "$lasttriad" -eq "$lasttriad" ] # 2>/dev/null
      then
         if [ $lasttriad -lt 101 ] || [ $lasttriad -gt 250 ]
         then
            printf "\n\nYour choice is out of range. Please try again\n"
         else         
            finished=0
         fi
      else
         printf "\n\nYour choice is not a number.  Please try again\n"
      fi
   done
   staticip=$threetriads$lasttriad
   staticipbroadcast+=$staticip"/24"

   printf "\033c"; printf "\n"
   printf "\nTo review, you entered the following information:\n"
   printf "\nTime Zone = $country $zone $city $city2"
   printf "\nHost Name = $host_name"
   printf "\nUser Name = $username"
   printf "\nSSH  port = $sshport"
   printf "\nStatic IP = $staticip"
   prompt="\n\nIs this informatin correct? [y,n,q] "
   simple-yes-no
   if [ $returnanswer == "y" ]
   then
      userinputdone=0
   fi
done
###################   end user input  ######################

# create /etc/netctl/ethernet-static file with user supplied static IP
printf "\n${CYAN}Creating configuration file for static IP address...${NC}"
message="\nCreating configuration file for static IP address "
printf "Description='A basic static internet connection'" > /etc/netctl/ethernet-static
printf "\nInterface=$ethernetdevice" >> /etc/netctl/ethernet-static
printf "\nConnection=ethernet\nIP=static" >> /etc/netctl/ethernet-static
printf "\nAddress=('$staticipbroadcast')"  >> /etc/netctl/ethernet-static
printf "\n#Routes=('192.168.0.0/24 via 192.168.1.2')" >> /etc/netctl/ethernet-static
printf "\nGateway=('$routerip')" >> /etc/netctl/ethernet-static
printf "\nDNS=('$routerip' '8.8.8.8')\n" >> /etc/netctl/ethernet-static
printf "\n## For IPv6 autoconfiguration\n#IP6=stateless\n" >> /etc/netctl/ethernet-static
printf "\n## For IPv6 static address configuration\n#IP6=static"  >> /etc/netctl/ethernet-static
printf "\n#Address6=('1234:5678:9abc:def::1/64' '1234:3456::123/96')" >> /etc/netctl/ethernet-static
printf "\n#Routes6=('abcd::1234')\n#Gateway6='1234:0:123::abcd'\n" >> /etc/netctl/ethernet-static
ok-nok

printf "\n${CYAN}Enable ethernet static IP...${NC}\n"
message="\nEnable ethernet static IP "
cd /etc/netctl
netctl start ethernet-static 2>/dev/null
netctl enable ethernet-static 2>/dev/null
cd /root
ok-nok  # function call

############################################################

ln -sf $timezonepath /etc/localtime 2>> logfile2

hwclock --systohc 2>> logfile2

printf "\n${CYAN}Setting Locale...${NC}\n"
message="\nSetting locale "
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen 2>> logfile2
printf "\nLANG=en_US.UTF-8\n\n" > /etc/locale.conf 
ok-nok   # function call

printf "\n${CYAN}Setting hostname...${NC}"
message="\nSetting hostname "
printf "\n$host_name\n\n" > /etc/hostname
ok-nok   # function call

printf "\n${CYAN}Configuring /etc/hosts...${NC}"
message="\nConfiguring /etc/hosts "
printf "\n127.0.0.1\tlocalhost\n" > /etc/hosts
printf "::1\t\tlocalhost\n" >> /etc/hosts
printf "127.0.1.1\t$host_name.localdomain\t$host_name\n\n" >> /etc/hosts
ok-nok  # function call

printf "\n${CYAN}Running mkinitcpio...${NC}\n"
message="\nRunning mkinitcpio "
mkinitcpio -P  2>> logfile2
ok-nok

printf "\nEnter your ${CYAN}ROOT${NC} password\n\n"
finished=1
while [ $finished -ne 0 ]
do
  if passwd ; then
      finished=0 ; echo
   else
      finished=1 ; printf "\nPassword entry failed, try again\n\n"
   fi
done

printf "\n${CYAN}Creating a user...${NC}"
message="Creating a user "
useradd -m -G users -s /bin/bash $username 2>> logfile2
printf "\nEnter ${CYAN}USER${NC} password.\n\n"
finished=1
while [ $finished -ne 0 ]
do
  if passwd $username ; then
      finished=0 ; echo
   else
      finished=1 ; printf "\nPassword entry failed, try again\n\n"
   fi
done
ok-nok 

# do ENDEAVOUROS BRANDING in the grub menu and console window prompt
sed -i '/^GRUB_DISTRIBUTOR=/c\GRUB_DISTRIBUTOR="EndeavourOS"' /etc/default/grub
sed -i 's/Arch/EndeavourOS/' /etc/issue

printf "\n${CYAN}Installing grub...${NC}"
message="\nInstalling grub "
if [ $uefibootstatus == 1 ]
then
   grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=EndeavourOS --recheck 2>> logfile2
else
   grub-install --target=i386-pc $osdevicename --recheck 2>> logfile2
fi
grub-mkconfig -o /boot/grub/grub.cfg 2>> logfile2
ok-nok  # function call

############################################################

printf "\n${CYAN}Find current endeavouros-keyring...${NC}\n\n"
message="\nFind current endeavouros-keyring "
sleep 1
curl https://github.com/endeavouros-team/repo/tree/master/endeavouros/x86_64 |grep endeavouros-keyring |sed s'/^.*endeavouros-keyring/endeavouros-keyring/'g | sed s'/pkg.tar.zst.*/pkg.tar.zst/'g | tail -1 > keys 2>> logfile2


file="keys"
read -d $'\04' currentkeyring < "$file"

if [[ $currentkeyring =~ "sig" ]]    # check if currentkeyring contains sig
then
curl https://github.com/endeavouros-team/repo/tree/master/endeavouros/x86_64 |grep endeavouros-keyring |sed s'/^.*endeavouros-keyring/endeavouros-keyring/'g | sed s'/pkg.tar.xz.*/pkg.tar.xz/'g |tail -1 > keys 2>> logfile
file="keys"
read -d $'\04' currentkeyring < "$file"
fi


printf "\n${CYAN}Downloading endeavouros-keyring...${NC}"
message="\nDownloading endeavouros-keyring "
wget https://github.com/endeavouros-team/repo/raw/master/endeavouros/x86_64/$currentkeyring 2>> logfile2
ok-nok		# function call

printf "\n${CYAN}Installing endeavouros-keyring...${NC}\n"
message="Installing endeavouros-keyring "
pacman -U --noconfirm $currentkeyring &>> logfile2
ok-nok		# function call
# cleanup
if [ -a $currentkeyring ]
then
   rm -f $currentkeyring
fi

############################################################

printf "\n${CYAN}Find current endeavouros-mirrorlist...${NC}\n\n"
message="\nFind current endeavouros-mirrorlist "
sleep 1
curl https://github.com/endeavouros-team/repo/tree/master/endeavouros/x86_64 | grep endeavouros-mirrorlist |sed s'/^.*endeavouros-mirrorlist/endeavouros-mirrorlist/'g | sed s'/pkg.tar.zst.*/pkg.tar.zst/'g |tail -1 > mirrors

file="mirrors"
read -d $'\x04' currentmirrorlist < "$file"


printf "\n${CYAN}Downloading endeavouros-mirrorlist...${NC}"
message="\nDownloading endeavouros-mirrorlist "
wget https://github.com/endeavouros-team/repo/raw/master/endeavouros/x86_64/$currentmirrorlist 2>> logfile2
ok-nok      # function call

printf "\n${CYAN}Installing endeavouros-mirrorlist...${NC}\n"
message="\nInstalling endeavouros-mirrorlist "
pacman -U --noconfirm $currentmirrorlist &>> logfile2
ok-nok    # function call

printf "\n[endeavouros]\nSigLevel = PackageRequired\nInclude = /etc/pacman.d/endeavouros-mirrorlist\n\n" >> /etc/pacman.conf

# cleanup
if [ -a $currentmirrorlist ]
then
   rm -f $currentmirrorlist
fi

############################################################

printf "\n${CYAN}Installing yay from EndeavourOS...${NC}"
message="\nInstalling yay from EndeavourOS "
pacman -Sq --noconfirm yay &>> logfile2
ok-nok    # function call

############################################################

printf "\n${CYAN}Creating ll alias...${NC}"
message="\nCreating ll alias "
printf "\nalias ll='ls -l --color=auto'\n\n" >> /etc/bash.bashrc
ok-nok  # function call

#### re-establish ownership & permissions after fstab config messes it up ###

   chown root:users /server /serverbkup
   chmod 774 /server /serverbkup

############################################################

printf "\n${CYAN}Configure SSH...${NC}"
message="\nConfigure SSH "
# ethernetdevice=$(ip r | awk 'NR==1{print $5}')
# routerip=$(ip r | awk 'NR==1{print $3}')
sed -i "/Port 22/c Port $sshport" /etc/ssh/sshd_config
sed -i '/PermitRootLogin/c PermitRootLogin no' /etc/ssh/sshd_config
sed -i '/PasswordAuthentication/c PasswordAuthentication yes' /etc/ssh/sshd_config
sed -i '/PermitEmptyPasswords/c PermitEmptyPasswords no' /etc/ssh/sshd_config
systemctl disable sshd.service 2>> logfile2
systemctl enable sshd.service 2>>/dev/null
ok-nok    # function call

#############################################################
printf "\n${CYAN}Enable ufw firewall...${NC}\n"
message="\nEnable ufw firewall "
ufw logging off 2>/dev/null
ufw default deny 2>/dev/null
ufw enable 2>/dev/null
systemctl enable ufw.service 2>/dev/null #throws error code because in chroot env, send error to dev null
ok-nok  # function call

printf "\n\n${CYAN}Installation is complete!${NC}\n\n"
printf "Pressing any key will exit arch-chroot and terminate the script.\n\n"
printf "After exiting from arch-chroot, to add any additional packages\n"
printf "to your new system with pacman, enter\n"
printf "sudo arch-chroot /mnt\n"
printf "to re-enter the chroot environment\n\n"
printf "At the liveuser prompt, enter \"sudo umount -a\" to unmount the /mnt filesystem.\n"
printf "Ignore any errors from the umount command.\n"
printf "\nPower off your System, remove install media and boot up\nPress any key to continue \n\n"
read -n1 x
exit
