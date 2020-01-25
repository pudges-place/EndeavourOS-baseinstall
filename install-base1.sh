#! /bin/bash

function uefi-header {
   printf "The EndeavourOS Live install ISO has been started in the UEFI mode\n"
   printf "For a UEFI install, create a gpt partition table with 4 partitions as follows:\n\n"

   printf "Partition Table: gpt\n"
   printf "Number  Start   End     Size    File system     Name  Flags\n"
   printf " 1      1074MB  1388MB  315MB   fat32           EFI   boot, esp\n"
   printf " 2      1388MB  2462MB  1074MB  ext4            BOOT\n"
   printf " 3      2462MB  241GB   239GB   ext4            ROOT\n"
   printf " 4      241GB   250GB   8677MB  linux-swap(v1)  SWAP\n\n"
}    # end of function uefi-header

function bios-header {
   printf "The EndeavourOS Live install ISO has been started in the msdos mode\n"
   printf "For a msdos install, create a msdos partition table with 3 partitions as follows:\n\n"

   printf "Partition Table: msdos\n"
   printf "Number  Start   End     Size    Type     File system  Flags\n"
   printf " 1      1049kb  1075MB	1074MB  primary  ext4         boot\n"
   printf " 2      1075MB  241GB   240GB   primary  ext4\n"
   printf " 3      241GB   250GB   8860MB  primary  linux-swap(v1)\n\n"
}     # end of function bios-header

function uefi-instruction {
   printf "\033c"
   printf "    Create UEFI partition table on target drive\n\n"

   printf "Adjust width and height of this window for best viewing.\n"
   printf "Start an additional terminal window, for inputting  these instructions.\n\n"
   printf "$ lsblk     (determine the device name of your mass storage device)\n"
   printf "$ sudo parted /dev/sda   (or your /dev/name such as /dev/sdb or /dev/nvme0n1) \n"
   printf "(parted) mklabel gpt      (CAUTION as soon as you press Enter, all data will be gone)\n"
   printf "(parted) unit mib\n"
   printf "(parted) print free    (my SSD - Disk /dev/sda: 238475Mib total space. Write that down.\n"
   printf "                       (and a Partition table: gpt)\n"
   printf "(parted) mkpart\n"
   printf "  Partition name? EFI\n"
   printf "  File system type? fat32\n"
   printf "  Start? 1024                  (start point of partition in Mib)\n"
   printf "  End? 1524                    (end point 1524Mib - start point 1024Mib = 500Mib)\n"
   printf "(parted) set 1 esp on          (sets partition 1 flag to esp)\n"
   printf "(parted) print                 (check progress so far)\n"
   printf "(parted) mkpart\n"
   printf "  Partition name? BOOT\n"
   printf "  File system type? ext4\n"
   printf "  Start? 1524                 (start point of part 2 same as end point of part 1)\n"
   printf "  End? 2548                   ( creates a partition of 2548 - 1524 = 1024 Mib or 1 Gib)\n"
   printf " print free         (at bottom, note end column of free space - 238475Mib - in my case)\n"
   printf "                    ( multiply 1024 x 8 = 8192mib for 8Gib of swap. Adjust as needed)\n"      
   printf "(parted) mkpart\n"
   printf "   Partition name? ROOT\n"
   printf "   File system type? ext4\n"
   printf "   Start? 2548                 (same as end point of previous partition)\n"
   printf "   End? 230283           (free space 238475Mib - 8192Mib for swap = 230283 for end)\n"    
   printf "(parted) print free      (should show 8192Mib free space for swap)\n"
   printf "(parted) mkpart\n"
   printf "   Partition name: SWAP\n"
   printf "   File System type: linux-swap\n"
   printf "   Start? 230283     (start point of part 4 same as end point of part 3 adjust as nesessary)\n"
   printf "   End? 238475       (end point same as end point of Free Space from print free command.)\n"
   printf "(parted) print       (should be what you want)\n"
   printf "(parted) quit        (ignore you may need to update /etc/fstab as we haven't made one yet)\n"  

   printf "\nPress any key to continue "
   read -n1 x
 }     # end of function uefi-instruction


function bios-instruction {
   printf "\033c"
   printf "    Create Bios MBR partition table on target drive\n\n"

   printf "Adjust width and height of this window for best viewing.\n"
   printf "Start an additional terminal window, for inputting these instructions.\n\n"
   printf "$ lsblk     (determine the device name of your mass storage device)\n"
   printf "$ sudo parted /dev/sda   (or your /dev/name such as /dev/sdb or /dev/nvme0n1) \n"
   printf "(parted) mklabel msdos      (CAUTION as soon as you press Enter, all data will be gone)\n"
   printf "(parted) unit mib\n"
   printf "(parted) print free    (my SSD - Disk /dev/sda: 238475Mib total space. Write that down.\n"
   printf "                       (and a Partition table: msdos)\n"
   printf "(parted) mkpart\n"
   printf "  Partition type? primary/extended? primary\n"
   printf "  File system type? ext4\n"
   printf "  Start? 1024                 (start point of partition in Mib)\n"
   printf "  End? 2048                   (end point 2048Mib - start point 1024Mib = 1024Mib or 1Gib)\n"
   printf "(parted) set 1 boot on        (sets partition 1 flag to boot)\n"
   printf "(parted) print free           (check progress so far (at bottom, note \"end column\" of\n"
   printf "                              (free space - 238475Mib - in my case))\n"
   printf "                              (Leave space for swap, 1024 * 8 = 8192 for 8Gib of swap)\n" 
   printf "(parted) mkpart\n"
   printf "  Partition type? primary/extended? primary\n"
   printf "  File system type? ext4\n"
   printf "  Start? 2048                 (start point of part 2 same as end point of part 1)\n"
   printf "  End? 230283                 (free space 238475Mib - 8192Mib for swap = 230283 for end)\n"
   printf " print free                   (should show 8192Mib free for swap, note end of free space)\n"
   printf "(parted) mkpart\n"
   printf "   Partition type? primary/extended? primary\n"
   printf "   File System type: linux-swap\n"
   printf "   Start? 230283     (start point of part 3 same as end point of part 2)\n"
   printf "   End? 238475       (same as end point of Free Space from print free command.)\n"
   printf "(parted) print       (should be what you want)\n"
   printf "(parted) quit        (ignore you may need to update /etc/fstab as we haven't made one yet)\n"  

   printf "\nPress any key to continue "
   read -n1 x
}     # end of function bios-instruction


function format_mount_uefi {

#  format partitions

   n=1
   mkfs.fat -F32 $devicename$n

   n=2
   mkfs.ext4 $devicename$n

   n=3
   mkfs.ext4 $devicename$n

   n=4
   mkswap $devicename$n

# mount partitions

   n=3
   mount $devicename$n /mnt

   mkdir /mnt/boot
   n=2
   mount $devicename$n /mnt/boot

   mkdir /mnt/boot/efi

   n=1
   mount $devicename$n /mnt/boot/efi

   n=4
   swapon $devicename$n

}     # end of function format_mount_uefi


function format_mount_bios {

#  format partitions
   
   n=1
   mkfs.ext4 $devicename$n
   e2label $devicename$n BOOT

   n=2
   mkfs.ext4 $devicename$n
   e2label $devicename$n ROOT

   n=3
   mkswap $devicename$n

# mount partitions

   n=2
   mount $devicename$n /mnt

   mkdir /mnt/boot
   n=1
   mount $devicename$n /mnt/boot

   n=3
   swapon $devicename$n

}    # end of function format_mount_bios


function simple-yes-no {
# Requires that variable "prompt" be set
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

printf "\033c"; printf "\n"
printf "This script is meant for installation in a \"Bare Metal\" situation.\n"
printf "It does not provide for dual booting with another OS.\n"
printf "It assumes that the SSD/HD has been partitioned prior to running this script.\n"
printf "File Format ext4 is used for /boot and / \n"

ls /sys/firmware/efi/efivars  > /dev/null 2>/dev/null

if [ $? == "0" ]
then
   uefibootstatus=1
   uefi-header     # function call
else
   uefibootstatus=0
   bios-header     # function call
fi

printf "Any deviation from this scheme will result in a non working installation\n"
printf "It is up to you to determine the size of each partition.\n\n"
prompt="Do you require assistance with partitioning your Mass Storage Device? [y,n,q] "
simple-yes-no

if [ $returnanswer == "y" ] || [ $returnanswer == "Y" ]
then
  if [ $uefibootstatus == 1 ]
  then
     uefi-instruction
   else
     bios-instruction
  fi
fi


prompt="\nIs your SSD partition table and partitions set properly? [y,n] "
message="\nPlease partition your drive as described above\nThen restart this script\n"
verify="false"
yes-no-input       # function call



printf "\033c"; printf "\nCheck Internet Connection\n"
ping -c 3 endeavouros.com
printf "\n"
prompt="Do you see \"3 packets transmitted, 3 recieved, 0 packet loss\" [y,n] "
message="\nThe ping command failed, check network status\n"
verify="false"
yes-no-input

printf "\033c"; printf "\nEnable NTP\n\n"
timedatectl set-ntp true
printf "Timedatectl status\n" 
timedatectl status
printf "\n"
prompt="Does \"NTP service: active\" appear in status output? [y,n] "
message="\nThe command \"timedatectl set-ntp true\" failed\n"
verify="false"
yes-no-input


xyz="0"
while [ "$xyz" == "0" ]
do
   printf "\033c"; printf "\n"
   lsblk

   printf "\nUse the information from lsblk to determine the device name of your drive\n"
   printf "Enter in the format of /dev/sda or /dev/sdb or /dev/nvme0n1 or something similar\n\n"
   prompt="Enter the device name of your drive: "
   message="\nTry again."
   verify="true"
   yes-no-input
   
   if [ "${returnanswer:0:5}" != "/dev/" ]
#   while [ "${return:0:5}" != "/dev/" ]
   then
      printf "\nYour answer must be in the format /dev/sda or /dev/sdb or /dev/nvme0n1\n"
      printf "Try again ... Press any key to continue"
      read -n1 x
      xyz="0"
   else
      devicename="$returnanswer"
      xyz="1"
   fi
done


printf "\033c";
printf "\nFormatting and Mounting partitions\n"
if [ $uefibootstatus == 1 ]
then
   format_mount_uefi    #function call to format and mount for uefi
else
   format_mount_bios    #function call to format and mount for bios
fi

printf "\nRunning Reflector....may take a minute or two\n"
reflector --latest 50 --protocol https  --sort rate  --save /etc/pacman.d/mirrorlist

printf "\nPACSTRAP LINUX\n"

prompt="\nDo you want the LTS kernel INSTEAD of the current kernel? [y/n/q] "
simple-yes-no

if [ $returnanswer == "q" ] || [ $returnanswer == "Q" ]
then
   exit
fi

if [ $returnanswer == "y" ] || [ $returnanswer == "Y" ]
then
   lts="y"
else
   lts="n"
fi

if [ $lts == "y" ]
then
   printf "\n\n  The LTS kernel will be installed\n\n"
   pacstrap /mnt base base-devel linux-lts linux-lts-headers linux-firmware netctl net-tools grub efibootmgr dosfstools mtools openssh wget intel-ucode amd-ucode htop vi nano ufw rsync
else
   printf "\n\n  The current kernel will be installed\n\n"
   pacstrap /mnt base base-devel linux linux-headers linux-firmware netctl net-tools grub efibootmgr dosfstools mtools openssh wget intel-ucode amd-ucode htop vi nano ufw rsync
fi

printf "Generate /etc/fstab\n\n"
genfstab -U /mnt >> /mnt/etc/fstab

printf "$devicename" > device-name


cp device-name /mnt/root
cp install-base2.sh /mnt/root/


printf "Entering arch-chroot\n\n"

arch-chroot /mnt /root/install-base2.sh

exit
