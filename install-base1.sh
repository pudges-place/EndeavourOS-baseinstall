#!/bin/bash

function ok-nok {
# Requires that variables "message" be set
status=$?
if [[ $status -eq 0 ]]
then
  printf "${GREEN}$message OK${NC}\n"
  printf "$message OK\n" >> logfile1
else
  printf "${RED}$message   FAILED${NC}\n"
  printf "$message FAILED\n" >> logfile1
  printf "\n\nLogs are stored in: logfile1\n"
  exit 1
fi
sleep 1
}	# end of function ok-nok

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

function yes-no-input {
# Requires that variables "prompt" "message" and "verify" be set
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

function uefi-header {
   printf "\033c"
   printf "The EndeavourOS Live install ISO has been started in the UEFI mode\n"
   printf "For a UEFI install, create a gpt partition table with 4 partitions as follows:\n\n"
   printf "Partition Table: gpt\n"
   printf "Number  Start   End     Size    File system     Name  Flags\n"
   printf " 1      1074MB  1388MB  315MB   fat32           EFI   boot, esp\n"
   printf " 2      1388MB  2462MB  1074MB  ext4            BOOT\n"
   printf " 3      2462MB  241GB   239GB   ext4            ROOT\n"
   printf " 4      241GB   250GB   8677MB  linux-swap(v1)  SWAP\n\n"
   printf "Only File Format ext4 is allowed for /boot and / \n\n"
}    # end of function uefi-header

function bios-header {
   printf "\033c"
   printf "The EndeavourOS Live install ISO has been started in the msdos mode\n"
   printf "For a msdos install, create a msdos partition table with 3 partitions as follows:\n\n"
   printf "Partition Table: msdos\n"
   printf "Number  Start   End     Size    Type     File system  Flags\n"
   printf " 1      1049kb  1075MB	1074MB  primary  ext4         boot\n"
   printf " 2      1075MB  241GB   240GB   primary  ext4\n"
   printf " 3      241GB   250GB   8860MB  primary  linux-swap(v1)\n\n"
   printf "Only File Format ext4 is allowed for /boot and / \n\n"
}     # end of function bios-header

function headerend {
   printf "Any deviation from this scheme will result in a non working installation\n"
   printf "It is up to you to determine the size of each partition.\n\n"
   printf "I will wait here while you use GParted, hit any key when finished..."
   read -n1 z
   prompt="\n\nAre your SSD partition table and partitions set properly? [y,n] "
   simple-yes-no
   if [ $returnanswer == "n" ]
   then
      printf "\n\nPlease partition your drive as described above\nThen restart this script\n\n"
      exit
   fi
}   # end of function headerend

function uefi-auto-partition {
 parted --script -a minimal $osdevicename \
   mklabel gpt \
   unit mib \
   mkpart EFI fat32 1024MiB 1524MiB \
   set 1 esp on \
   mkpart BOOT 1524MiB 2548MiB \
   mkpart ROOT 2548MiB $osendpart2 \
   mkpart SWAP linux-swap $osendpart2 $osdevicesize \
   quit 
 }     # end of function uefi-auto-partition

function bios-auto-partition {
parted --script -a minimal $osdevicename \
   mklabel msdos \
   unit mib \
   mkpart primary 2MiB 1026MiB \
   set 1 boot on \
   mkpart primary 1026MiB $osendpart2 \
   mkpart primary linux-swap $osendpart2 $osdevicesize \
   quit
}     # end of function bios-auto-partition

function listdevices {
####    fdisk -l | grep 'Disk /dev/sd\|Disk /dev/nvme\|Disk model' > disks
    lineno=$(wc -l disks | awk '{print $1}')
    recordno=$((lineno / 2))
    printf "\033c"
    printf "\nDiscovery found the following devices:\n"
    devno=1
    while [ $devno -le $recordno ]
    do
        printf "${CYAN}\nDevice $devno\n${NC}"
        if [ $devno -eq 1 ]
        then
            st=1
            ((sp=$st+1))  
        else
            ((st=$devno+($devno-1))) 
            ((sp=$st+1)) 
        fi
        cat disks | awk -v a="$st" -v b="$sp" 'NR==a,NR==b'
        devname=$( cat disks | awk -v a="$st" -v b="$sp" 'NR==a,NR==b' | grep "/dev/" | awk '{print $2}')
        devname=("${devname::-1}")
        endvrdev=$(ls -l /dev/disk/by-label | grep ENDEAVOUR | awk '{print $NF}' | awk 'BEGIN {FS = "/"} ; {print $3}')
        endvrdev=("${endvrdev::-1}")
        endvrdev="/dev/"$endvrdev
        if [ $endvrdev == $devname ]
        then
           isodeviceno=$devno
           isodevicename=$endvrdev
           printf "${CYAN}ENDEAVOUROS ISO${NC}\n"
        fi
        ((devno=devno+1)) 
    done
}   # end of function listdevices

function verifydevice {
    zyx="0"
    while [ "$zyx" == "0" ]
    do
      printf "\nEnter the device number on which to install $osordata [1 to $recordno] "
      read devno2
      if [[ $devno2 =~ ^[0-9]+$ ]] 2>/dev/null  
      then
         if [ $devno2 -lt 1 ] || [ $devno2 -gt $recordno ]
         then
            printf "\nYour choice is out of range. Please try again\n"
         else
           if [ $devno2 == $isodeviceno ]
           then
              printf "\nYou have chosen the EndeavourOS ISO device.  Pick a different device\n"
           else
              zyx="1"   
           fi
         fi
      else
         printf "\nYour choice is not a number.  Please try again\n"
      fi
    done

    if [ $devno2 -eq 1 ]
      then
          st=1
          ((sp=$st+1))  
      else
          ((st=$devno2+($devno2-1))) 
          ((sp=$st+1)) 
    fi
}   # end of function verifydevice


function whichdevice  {
##### Determine device name ####
xyz="0"
while [ $xyz == 0 ]
do
    listdevices  # function call
    osordata="Operating System"
    verifydevice  #  function call
    cat disks | awk -v a="$st" -v b="$sp" 'NR==a,NR==b' > devinfo
    osdevicemodel=$(cat devinfo | grep "Disk model" | sed 's/Disk/Device/')
    osdevicename=$(cat devinfo | grep "/dev/" | awk '{print $2}')
    osdevicename=${osdevicename%?}
    osdevicesize=$(cat devinfo | grep "/dev/" | awk '{print $3 " " $4}')
    osdevicesize=${osdevicesize%?}
    printf "\nYou have chosen the following device to recieve the Operating System\n"
    printf "\n$osdevicemodel\nDevice name:  $osdevicename\nDevice size:  $osdevicesize\n"
    printf "\nWARNING: Accepting this will remove ALL data on the device\n"
    prompt="\nDo you accept ${CYAN}$osdevicename${NC} as your OS Device? [y,n,q] "
    simple-yes-no  #function call
    if [ $returnanswer == "y" ]
    then
      xyz="1"
    fi

     datadevicename="none"
    if [ $returnanswer == "y" ] && [ $autopart == "y" ]
    then   #1
       prompt="\nIs there a separate storage device for DATA connected? [y,n,q] "
       simple-yes-no   # function call
       if [ $returnanswer == "y" ]
       then  #2
          prompt="\nDo you want to format, mount, and enter it in /etc/fstab? [y,n,q] "
          simple-yes-no  # function call
          if [ $returnanswer == "y" ]
          then  #3
             listdevices # function call
              printf "__________________________________________________________________\n" 
              printf "\nDevice $osdevicename has been chosen for the Operating System\n"
              osordata="the DATA drive"
              printf "$osdevicemodel\nDevice name:  $osdevicename\nDevice size:  $osdevicesize\n"
             verifydevice  # function call
             cat disks | awk -v a="$st" -v b="$sp" 'NR==a,NR==b' > devinfo2
             datadevicemodel=$(cat devinfo2 | grep "Disk model" | sed 's/Disk/Device/')
             datadevicename=$(cat devinfo2 | grep "/dev/" | awk '{print $2}')
             datadevicename=${datadevicename%?}
             datadevicesize=$(cat devinfo2 | grep "/dev/" | awk '{print $3 " " $4}')
             datadevicesize=${datadevicesize%?}
             printf "\nYou have chosen the following device to store the Data\n"
             printf "\n$datadevicemodel\nDevice name:  $datadevicename\nDevice size:  $datadevicesize\n"
             printf "\nWARNING: Accepting this will remove ALL data on the device\n"
             prompt="\nDo you accept ${CYAN}$datadevicename${NC} as your DATA Device? [y,n,q] "
             simple-yes-no  #function call
                if [ $returnanswer == "n" ]
                then #4
                   datadevicename="none"
                fi #4
             if [ $osdevicename == $datadevicename ]
             then  #5
              printf "\n${RED}ERROR: The Operating System device and the Data device are the same.\n${NC}"
              printf "Different devices must be selected for the OS and the DATA devices\n\n"
              prompt="Try again?  y = redo device selection, n = ignore DATA device [y,n,q] "
              simple-yes-no  # function call
                 if [ $returnanswer == "y" ]
                    then #6
                      xyz="0"
                 else
                    datadevicename="none"
                 fi #6
             fi #5
          fi  #3
       fi  #2
    fi  #1
done
}  # end of function whichdevice


function autopartition {    
    
  ##### Determine device size in MiB, and end of root partition ###
  osdevicesize=$(cat devinfo | grep $osdevicename | awk '{print $5}')
  ((osdevicesize=$osdevicesize/1048576))
  ((osdevicesize=$osdevicesize-1))   # for some reason, necessary for USB thumb drives
  ((osendpart2=$osdevicesize-4096))
  osendpart2=$osendpart2"MiB"
  osdevicesize=$osdevicesize"MiB"
  ##### Call appropriate auto partition function ####
    if [ $uefibootstatus -eq 1 ]
     then
      printf "\n${CYAN}Partitioning $osdevicename UEFI...${NC}"
      message="\nPartitioning $osdevicename UEFI   "
      uefi-auto-partition 2>> logfile1 # function call
      ok-nok  # function call
    else
      printf "\n${CYAN}Partitioning $osdevicename MBR...${NC}"
      message="\nPartitioning $osdevicename MBR   "
      bios-auto-partition 2>> logfile1 # function call
      ok-nok  #function call
    fi
}   # end of function autopartition

function format_uefi {
# format uefi partitions
   n=1
   mkfs.fat -F32 $mntdevice$n 2>> logfile1

   n=2
   mkfs.ext4 $mntdevice$n 2>> logfile1

   n=3
   mkfs.ext4 $mntdevice$n 2>> logfile
 
   n=4
   mkswap $mntdevice$n  2>> logfile1
}  # end of function format_uefi


function mount_uefi {
# mount uefi partitions
   n=3
   mount $mntdevice$n /mnt  2>> logfile1

   mkdir /mnt/boot 2>> logfile1
   n=2
   mount $mntdevice$n /mnt/boot 2>> logfile1

   mkdir /mnt/boot/efi 2>> logfile1
   n=1
   mount $mntdevice$n /mnt/boot/efi 2>> logfile1
  
   n=4
   swapon $mntdevice$n  2>> logfile1

}     # end of function mount_uefi

function format_bios {
# format bios partitions
   n=1
   mkfs.ext4 $mntdevice$n   2>> logfile1
   e2label $mntdevice$n BOOT

   n=2
   mkfs.ext4 $mntdevice$n  2>> logfile1
   e2label $mntdevice$n ROOT

   n=3
   mkswap $mntdevice$n 2>> logfile1
}  # end of function format_bios

function mount_bios {
# mount bios partitions
   n=2
   mount $mntdevice$n /mnt 2>> logfile1

   mkdir /mnt/boot 2>> logfile1
   n=1
   mount $mntdevice$n /mnt/boot 2>> logfile1

   n=3
   swapon $mntdevice$n 2>> logfile1
}    # end of function mount_bios




function currentlts {
prompt="\n\nDo you want the LTS kernel INSTEAD of the current kernel? [y/n/q] "
simple-yes-no
if [ $returnanswer == "q" ]
then
   exit
fi
if [ $returnanswer == "y" ]
then
   lts="y"
else
   lts="n"
fi
}    # end of function currentlts

###############################################
# starting point for script 1
###############################################

# Declare following global variables
readonly scriptversion="Install EndeavourOS base - Version 2020.03.29-x86_64"
uefibootstatus=20
osdevicename="a"
datadevicename="a"
isodeviceno=1
isodevicename="z"
returnanswer="b"
prompt="c"
message="d"
verify="e"
basedevel="f"
lts="g"

# Declare color variables
GREEN='\033[0;32m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

##### check to see if script was run as root #####
if [ $(id -u) -ne 0 ]
then
   printf "\nPLEASE RUN THIS SCRIPT WITH sudo\n\n"
   exit
fi

# create empty logfile1
printf "    LOGFILE 1\n\n" > logfile1


##### check to see if ISO was booted in msdos/MBR mode or UEFI #####
ls /sys/firmware/efi/efivars  > /dev/null 2>/dev/null
if [ $? == "0" ]
then
   uefibootstatus=1
else
   uefibootstatus=0
fi

# unmount all drives, Discover storage devices

umount -a 2>> logfile1
swapoff -a 2>> logfile1
fdisk -l | grep 'Disk /dev/sd\|Disk /dev/nvme\|Disk model' > disks

##### Determine if user wants manual partitioning or auto partitioning #####
printf "\033c"; printf "\n"
printf "$scriptversion\n\n"
printf "This script is offered as FOSS, as usual use at your own risk.\n"
printf "The purpose is to install a base EndeavourOS for use as a server\n\n"
printf "This script is meant for installation in a \"Bare Metal\" situation.\n"
printf "It does not provide for dual booting with another OS.\n"
printf "It does not provide for WiFi connections.\n"
printf "A swap partition is required, default swap size for auto partition is 4 GiB\n"
printf "\nOnly run this script immediately after a reboot of the EndeavourOS ISO.\n"
printf "If the script does not finish, or you interrupt it, PLEASE reboot the ISO\n"
printf "\nThe SSD/HD can be partitioned prior to running this script using GParted.\n"
printf "Or the SSD/HD can be auto-partitioned by the script.\n"
prompt="\nDo you want to use auto-partitioning? [y,n,q] "
simple-yes-no
autopart=$returnanswer
if [ $returnanswer == "n" ]
then
  if [ $uefibootstatus -eq 1 ]
  then
     uefi-header   # function call
     headerend     # function call
     whichdevice   # function call sets global variable osdevicename
     currentlts    # function call
  else
     bios-header   # function call
     headerend     # function call 
     whichdevice   # function call sets global variable osdevicename
     currentlts    # function call 
  fi
else
  whichdevice      # function call sets variable osdevicename & datadevicename
  currentlts       # function call
  autopartition    # function call
fi

### adjust devicename to allow for nvme type devices for formatting and mounting ##

if [[ ${osdevicename:5:4} = "nvme" ]]
then
   mntdevice=$osdevicename"p"
else
   mntdevice=$osdevicename
fi

#################################################################################

printf "\n${CYAN}Formatting partitions...${NC}\n\n"
if [ $uefibootstatus == 1 ]
then 
   message="\nFormatting partitions   "
   format_uefi 2>> logfile1 #function call to format for uefi
   ok-nok  # function call
else
   message="\nFormatting partitions   "  
   format_bios 2>> logfile1 #function call to format for bios   
   ok-nok
fi

############################################################

printf "\n${CYAN}Mounting partitions...${NC}"
if [ $uefibootstatus == 1 ]
then
   message="\nMounting partitions   "
   mount_uefi 2>> logfile1   #function call to mount for uefi
   ok-nok	# function call
else
   message="\nMounting partitions   "
   mount_bios 2>> logfile1   #function call to mount for bios
   ok-nok	# function call
fi

if [ "$datadevicename" != "none" ]
then
  ##### Determine device size in MiB ###
  printf "\n${CYAN}Partitioning, & formatting DATA storage device...${NC}\n"
  datadevicesize=$(cat devinfo2 | grep $datadevicename | awk '{print $5}')
  ((datadevicesize=$datadevicesize/1048576))
  ((datadevicesize=$datadevicesize-1))  # for some reason, necessary for USB thumb drives
  datadevicesize=$datadevicesize"MiB"
  printf "\n${CYAN}Partitioning DATA device $datadevicename...${NC}\n"
  message="\nPartitioning DATA devive $datadevicename  " 
  parted --script -a minimal $datadevicename \
  mklabel msdos \
  unit mib \
  mkpart primary 1MiB $datadevicesize \
  quit
  ok-nok  # function call
  if [[ ${datadevicename:5:4} = "nvme" ]]
  then
     mntname=$datadevicename"p1"
   else
     mntname=$datadevicename"1"
  fi
  printf "\n\ndatadevicename = $mntname\n\n" >> logfile1
  printf "\n${CYAN}Formatting DATA device $mntname...${NC}\n"
  message="\nFormatting DATA device $mntname   "
  mkfs.ext4 $mntname   2>> logfile1
  e2label $mntname DATA
  ok-nok  # function call
fi

############################################################

printf "\n${CYAN}Checking Internet Connection...${NC}"
message="\nChecking Internet Connection   " 
ping -c 3 endeavouros.com -W 5 &>> logfile1
ok-nok		# function call


printf "\n${CYAN}Enabling NTP...${NC}"
message="\nEnabling NTP   "
timedatectl set-ntp true &>> logfile1
timedatectl timesync-status &>> logfile1
ok-nok		# function call
sleep 1

printf "\n${CYAN}Running Reflector....may take a minute or two...${NC}   "
message="\n\nReflector completed  "
reflector --latest 50 --protocol https  --sort rate  --save /etc/pacman.d/mirrorlist
ok-nok	# function call
   
printf "\nPACSTRAP LINUX\n"


if [ $lts == "y" ]
then
   printf "\n\n  ${CYAN}The LTS kernel will be installed${NC}\n\n"
   pacstrap /mnt base base-devel linux-lts linux-lts-headers linux-firmware netctl net-tools grub efibootmgr dosfstools mtools openssh wget intel-ucode amd-ucode htop vi nano ufw rsync 2>> logfile1
else
   printf "\n\n  ${CYAN}The current kernel will be installed${NC}\n\n"
   pacstrap /mnt base base-devel linux linux-headers linux-firmware netctl net-tools grub efibootmgr dosfstools mtools openssh wget intel-ucode amd-ucode htop vi nano ufw rsync 2>> logfile1
fi

printf "\n\n${CYAN}Generating /etc/fstab...${NC}"
message="\nGenerating /etc/fstab   "
genfstab -U /mnt >> /mnt/etc/fstab 2>> logfile1
ok-nok	# function call
sleep 1


############################################################

mkdir /mnt/server /mnt/serverbkup  2>> logfile1
chown root:users /mnt/server /mnt/serverbkup 2>> logfile1
chmod 774 /mnt/server /mnt/serverbkup  2>> logfile1

############################################################


if [ "$datadevicename" != "none" ]
then
   printf "\n${CYAN}Adding DATA storage device to /etc/fstab...${NC}"
   message="\nAdding DATA storage device to /etc/fstab   "
   cp /mnt/etc/fstab /mnt/etc/fstab-bkup
   uuidno=$(lsblk -o UUID $mntname)
   uuidno=$(echo $uuidno | sed 's/ /=/g')
   printf "# $mntname\n$uuidno      /server          ext4            rw,relatime     0 2\n" >> /mnt/etc/fstab
   ok-nok   # function call

   printf "\n${CYAN}Mounting DATA device $mntname on /server...${NC}"
   message="\nMountng DATA device $mntname on /server   "
   mount $mntname /mnt/server 2>> logfile1
   ok-nok   # function call
fi


chown root:users /mnt/server /mnt/serverbkup 2>> logfile1
chmod 774 /mnt/server /mnt/serverbkup  2>> logfile1

printf "$osdevicename" > osdevice-name

cp osdevice-name /mnt/root
cp install-base2.sh /mnt/root/
rm -f devinfo devinfo2 disks

printf "${CYAN}Entering arch-chroot${NC}\n\n"

arch-chroot /mnt /root/install-base2.sh

rm -f osdevice-name
# Combine logfiles
cp /mnt/root/logfile2 .

cat logfile1 logfile2 > logfile
printf "\n${CYAN}If the logfile needs to be displayed, enter\ncat logfile${NC}\n"


exit
