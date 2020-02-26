#! /bin/bash

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
      printf "\n\nPlease partition your drive as described above\nThen restart this script\n"
      exit
   fi
}   # end of function headerend

function ok-nok {
# Requires that variables "message" be set
status=$?
if [[ $status -eq 0 ]]
then
  printf "${GREEN}$message OK${NC}\n"
  printf "$message OK" >> logfile1
else
  printf "${CYAN}$message   FAILED${NC}\n"
  printf "$message FAILED" >> logfile1
  printf "\n\nLogs are stored in: logfile1/n"
  exit 1
fi
sleep 1
}	# end of function ok-nok


function uefi-auto-partition {
 parted --script -a optimal /$devicename \
   mklabel gpt \
   unit mib \
   mkpart EFI fat32 1024MiB 1524MiB \
   set 1 esp on \
   mkpart BOOT 1524MiB 2548MiB \
   mkpart ROOT 2548MiB $endpart2 \
   mkpart SWAP linux-swap $endpart2 $devicesize \
   quit 
 }     # end of function uefi-auto-partition

function bios-auto-partition {
parted --script -a optimal /$devicename \
   mklabel msdos \
   unit mib \
   mkpart primary 1024MiB 2048MiB \
   set 1 boot on \
   mkpart primary 2048MiB $endpart2 \
   mkpart primary linux-swap $endpart2 $devicesize \
   quit
}     # end of function bios-auto-partition


function whichdevice  {
##### Determine device name ####
xyz="0"
while [ "$xyz" == "0" ]
do
    fdisk -l | grep 'Disk /dev/sd\|Disk /dev/nvme\|Disk model' > disks
    lineno=$(wc -l disks | awk '{print $1}')
    recordno=$((lineno / 2))
    printf "\033c"
    printf "\nDiscovery found the following devices:\n"
    devno=1
    while [ $devno -le $recordno ]
    do
        printf "\nDevice $devno\n"
        if [ $devno -eq 1 ]
        then
            st=1
            ((sp=$st+1))  
        else
            ((st=$devno+($devno-1))) 
            ((sp=$st+1)) 
        fi
        cat disks | awk -v a="$st" -v b="$sp" 'NR==a,NR==b'
        ((devno=devno+1)) 
    done

    zyx="0"
    while [ "$zyx" == "0" ]
    do
      printf "\nEnter the device number on which to install OS [1 to $recordno] "
      read devno
      if [ "$devno" -eq "$devno" ] 2>/dev/null  
      then
         if [ $devno -lt 1 ] || [ $devno -gt $recordno ]
         then
            printf "\nYour choice is out of range. Please try again\n"
         else
            zyx="1"
         fi 
      else
         printf "\nYour choice is not a number.  Please try again\n"
      fi
    done

    if [ $devno -eq 1 ]
      then
          st=1
          ((sp=$st+1))  
      else
          ((st=$devno+($devno-1))) 
          ((sp=$st+1)) 
    fi
    cat disks | awk -v a="$st" -v b="$sp" 'NR==a,NR==b' > devinfo
    devicemodel=$(cat devinfo | grep "Disk model" | sed 's/Disk/Device/')
    devicename=$(cat devinfo | grep "/dev/" | awk '{print $2}')
    devicename=${devicename%?}
    devicesize=$(cat devinfo | grep "/dev/" | awk '{print $3 " " $4}')
    devicesize=${devicesize%?}
    printf "\nYou have chosen the following device to recieve the Operating System\n"
    printf "\n$devicemodel\nDevice name:  $devicename\nDevice size:  $devicesize\n"
    printf "\nWARNING: Acepting this will remove ALL data on the device\n"
    prompt="\nDo you accept $devicename as your OS Device? [y,n,q] "
    simple-yes-no  #function call
    if [ $returnanswer == "y" ] || [ $returnanswer == "Y" ]
    then
      xyz="1"
    fi
done
}   # end of function whichdevice

function autopartition {    
    
  ##### Determine device size in MiB, and end of root partition ###
  devicesize=$(cat devinfo | grep $devicename | awk '{print $5}')
  ((devicesize=$devicesize/1048576))
  ((endpart2=$devicesize-4096))
  endpart2=$endpart2"MiB"
  devicesize=$devicesize"MiB"
 
  ##### Call appropriate auto partition function ####
  # printf "\033c"
    if [ $uefibootstatus -eq 1 ]
     then
      printf "\nPartitioning $devicename UEFI..."
      message="\nPartitioning $devicename UEFI   "
      uefi-auto-partition 2> logfi1e1  # function call
      ok-nok  # function call
    else
      printf "\nPartitioning $devicename MBR..."
      message="\nPartitioning $devicename MBR   "
      bios-auto-partition 2>> logfile1 # function call
      ok-nok  #function call
    fi
}   # end of function autopartition

function format_uefi {
# format uefi partitions
   n=1
   mkfs.fat -F32 $devicename$n 2>> logfile1

   n=2
   mkfs.ext4 $devicename$n 2>> logfile1

   n=3
   mkfs.ext4 $devicename$n 2>> logfile
 
   n=4
   mkswap $devicename$n  2>> logfile1
}  # end of function format_uefi


function mount_uefi {
# mount uefi partitions
   n=3
   mount $devicename$n /mnt  2>> logfile1

   mkdir /mnt/boot 2>> logfile1
   n=2
   mount $devicename$n /mnt/boot 2>> logfile1

   mkdir /mnt/boot/efi 2>> logfile1
   n=1
   mount $devicename$n /mnt/boot/efi 2>> logfile1
  
   n=4
   swapon $devicename$n  2>> logfile1

}     # end of function mount_uefi

function format_bios {
# format bios partitions
   n=1
   mkfs.ext4 $devicename$n   2>> logfile1
   e2label $devicename$n BOOT

   n=2
   mkfs.ext4 $devicename$n  2>> logfile1
   e2label $devicename$n ROOT

   n=3
   mkswap $devicename$n 2>> logfile1
}  # end of function format_bios

function mount_bios {
# mount bios partitions
   n=2
   mount $devicename$n /mnt 2>> logfile1

   mkdir /mnt/boot 2>> logfile1
   n=1
   mount $devicename$n /mnt/boot 2>> logfile1

   n=3
   swapon $devicename$n 2>> logfile1

}    # end of function mount_bios


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
let uefibootstatus=20
let devicename="a"
let returnanswer="b"
let prompt="c"
let message="d"
let verify="e"
let basedevel="f"
let lts="g"
# Declare color variables
GREEN='\033[0;32m'
RED='\033[0;31m'
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

##### Determine if user wants manual partitioning or auto partitioning #####
printf "\033c"; printf "\n"
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
     whichdevice   # function call sets global variable devicename
     currentlts    # function call
  else
     bios-header   # function call
     headerend     # function call 
     whichdevice   # function call sets global variable devicename
     currentlts    # function call 
  fi
else
  whichdevice      # function call sets variable devicename
  currentlts       # function call
  autopartition    # function call
fi

#if [ "$autopart" == "n" ]
#then 
#   currentlts   # function call
#fi

printf "\nChecking Internet Connection..."
message="\nChecking Internet Connection   " 
ping -c 3 endeavouros.com -W 5 &>> logfile1
ok-nok		# function call


printf "\nEnabling NTP..."
message="\nEnabling NTP   "
timedatectl set-ntp true &>> logfile1
timedatectl timesync-status &>> logfile1
ok-nok		# function call
sleep 1

printf "\nFormatting partitions...  "
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

printf "\nMounting partitions...   "
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

printf "\nRunning Reflector....may take a minute or two...   "
message="\n\nReflector completed  "
reflector --latest 50 --protocol https  --sort rate  --save /etc/pacman.d/mirrorlist
ok-nok	# function call
   
printf "\nPACSTRAP LINUX\n"


if [ $lts == "y" ]
then
   printf "\n\n  The LTS kernel will be installed\n\n"
   pacstrap /mnt base base-devel linux-lts linux-lts-headers linux-firmware netctl net-tools grub efibootmgr dosfstools mtools openssh wget intel-ucode amd-ucode htop vi nano ufw rsync 2>> logfile1
else
   printf "\n\n  The current kernel will be installed\n\n"
   pacstrap /mnt base base-devel linux linux-headers linux-firmware netctl net-tools grub efibootmgr dosfstools mtools openssh wget intel-ucode amd-ucode htop vi nano ufw rsync 2>> logfile1
fi

printf "\n\nGenerating /etc/fstab..."
message="\nGenerating /etc/fstab   "
genfstab -U /mnt >> /mnt/etc/fstab 2>> logfile1
ok-nok	# function call
sleep 1

printf "$devicename" > device-name


cp device-name /mnt/root
cp install-base2.sh /mnt/root/


printf "Entering arch-chroot\n\n"

arch-chroot /mnt /root/install-base2.sh

# Combine logfiles
cp /mnt/root/logfile2 .

cat logfile1 logfile2 > logfile
printf "\nIf the logfile needs to be displayed, enter\ncat logfile\n"

exit
