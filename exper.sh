#!/bin/bash


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

###############################################
# starting point for script 
###############################################
if [ $(id -u) -ne 0 ]
then
   printf "\nPLEASE RUN THIS SCRIPT WITH sudo\n\n"
   exit
fi

xyz="0"
while [ "$xyz" == "0" ]
do
  fdisk -l | grep 'Disk /dev/sd\|Disk /dev/nvme\|Disk model' > disks
  lineno=$(wc -l disks | awk '{print $1}')
  recordno=$((lineno / 2))

  printf "\nlineno $lineno  recordno $recordno"

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
    if [ $devno -lt 0 ] || [ $devno -gt $recordno ]
    then
       printf "\nYour choice is out of range. Please try again\n"
    else
       zyx="1"   
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

  #devicemodel=$(echo -n $devicemodel | head -c -2)

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


