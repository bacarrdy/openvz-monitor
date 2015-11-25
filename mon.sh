#!/bin/bash

#openvz containers main directory (by default /var/lib/vz or /vz)
maindir=/vz

for veid in $(/usr/sbin/vzlist -o veid -H)
do

  declare -a readas_first
  declare -a readas_second
  declare -a writas_first
  declare -a writas_second

  for i in $(ls $maindir/root/$veid/proc/ | grep -o '[0-9]*')
  do
    if [ -d "$maindir/root/$veid/proc/$i/" ]; then
      read_temp=`cat $maindir/root/$veid/proc/$i/io | grep read_bytes: | awk '{print $2}'`
      readas_first+=($read_temp)
      write_temp=`cat $maindir/root/$veid/proc/$i/io | grep '^write_bytes:' | awk '{print $2}'`
      writas_first+=($write_temp)
    fi
  done

  sleep 1

  for i in $(ls $maindir/root/$veid/proc/ | grep -o '[0-9]*')
  do
    if [ -d "$maindir/root/$veid/proc/$i/" ]; then
      read_temp=`cat $maindir/root/$veid/proc/$i/io | grep read_bytes: | awk '{print $2}'`
      readas_second+=($read_temp)
      write_temp=`cat $maindir/root/$veid/proc/$i/io | grep '^write_bytes:' | awk '{print $2}'`
      writas_second+=($write_temp)
    fi
  done

  read_f=0
  for ((i=0;i<${#readas_first[*]};i++)); 
  do
    read_f=$(($read_f + ${readas_first[$i]}))
  done
  read_s=0
  for ((i=0;i<${#readas_second[*]};i++)); 
  do
    read_s=$(($read_s + ${readas_second[$i]}))
  done

  write_f=0
  for ((i=0;i<${#writas_first[*]};i++)); 
  do
    write_f=$(($write_f + ${writas_first[$i]}))
  done
  write_s=0
  for ((i=0;i<${#writas_second[*]};i++)); 
  do
    write_s=$(($write_s + ${writas_second[$i]}))
  done

  read_t=$(($read_s - $read_f))
  write_t=$(($write_s - $write_f))
  
  mem_total=`vzctl exec $veid free -b |grep Mem:|cut -d":" -f2|awk '{print $1}'`
  mem_usage=`vzctl exec $veid free -b |grep cache:|cut -d":" -f2|awk '{print $1}'`
  loadave=`vzctl exec $veid cat /proc/loadavg | cut -d"/" -f1 |sed 's/.$//'`
  hdduse=`df -h $maindir/root/$veid/ | grep root/$veid | awk '{print $5}'`
  hddtotal=`df -h $maindir/root/$veid/ | grep root/$veid | awk '{print $2}'`
  cpuusage=`vzctl exec $veid top -bn2 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%\id.*/\1/" | sed "s/.*, *\([0-9.]*\) \id.*/\1/" | tail -n1 | awk '{print 100-$1}'`
  mem_total=$(($mem_total /1024 /1024))
  mem_usage=$(($mem_usage /1024 /1024))
  

  echo "VEID: $veid  --- Read: $(($read_t / 1048576))MB/s Write: $(($write_t / 1048576))MB/s CPuUsage: $cpuusage% MemTotal: $mem_total MB MemUsed: $mem_usage MB LoadAverages: $loadave HddUsage: $hdduse HddTotal: $hddtotal"
  unset readas_first
  unset readas_second
  unset writas_first
  unset writas_second
done
