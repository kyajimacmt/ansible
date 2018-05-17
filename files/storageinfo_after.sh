#!/bin/sh
# `basename $0`
# Ver1.0 --- 2010/06/25 for RHEL5U4
# Ver2.0 --- 2011/11/21 add xpinfo/evainfo
# Ver3.0 --- 2012/05/11 for RHEL6U2
# Ver4.0 --- 2012/08/22 for evainfo
# Ver5.0 --- 2015/06/10 add HP3PARInfo / don't use "hostname" command
# Ver6.0 --- 2016/09/16 for RHEL7U2

TIME=`date +'%Y%m%d%H%M'`
DATE=`date +'%Y%m%d'`
#EXT=`basename $0 .sh`
EXT=after  ###change
#HOME=./${EXT}
BASEDIR=/tmp/hp/storage/
HOMEDIR=${BASEDIR}/`uname -n`_${DATE}/${EXT}
TOOLDIR=${BASEDIR}/tools/

echo "#### start ####"
echo "`date +'%Y/%m/%d %T'`"

if [ ! -d ${HOMEDIR} ] ; then
    mkdir -p ${HOMEDIR}
fi 
cd ${HOMEDIR}

echo "#### collect information ####"
uname -a > ./uname-a.${EXT} 2>&1
fdisk -l > ./fdisk-l.${EXT} 2>&1
df -k > ./df-k.${EXT} 2>&1
lssd > ./lssd.${EXT} 2>&1
lssd -l > ./lssd-l.${EXT} 2>&1
lssg > ./lssg.${EXT} 2>&1
ls -l /dev/disk/by-path > ./by-path.${EXT} 2>&1
rpm -qa | sort > ./rpm-qa.${EXT} 2>&1
multipath -ll > ./multipath-ll.${EXT} 2>&1
multipath -ll | grep mpath | sort -k2 > multipath-ll_grep_mpath.${EXT} 2>&1
chkconfig --list multipathd > chkconfig_--list_multipathd
adapter_info > ./adapter_info.${EXT} 2>&1
adapter_info -l > ./adapter_info-l.${EXT} 2>&1
adapter_info -v > ./adapter_info-v.${EXT} 2>&1
dmsetup ls --tree > ./dmsetup-ls-tree.${EXT} 2>&1

# for RHEL7
systemctl is-enabled multipathd.service
systemctl list-unit-files --no-pager | grep multipathd.service

# echo "#### evainfo ####"
which evainfo >> ./evainfo-which.${EXT} 2>&1
#${TOOLDIR}/evainfo -v > ./evainfo-v.${EXT} 2>&1
#${TOOLDIR}/evainfo -a -l > ./evainfo-al.${EXT} 2>&1
#${TOOLDIR}/evainfo -a -l -u GB > ./evainfo-aluGB.${EXT} 2>&1
#${TOOLDIR}/evainfo -a -l -f csv -u GB > ./evainfo-aluGB.csv.${EXT} 2>&1
evainfo -v > ./evainfo-v.${EXT} 2>&1
evainfo -a -l > ./evainfo-al.${EXT} 2>&1
evainfo -a -l -u GB > ./evainfo-aluGB.${EXT} 2>&1
evainfo -a -l -f csv -u GB > ./evainfo-aluGB.csv.${EXT} 2>&1

# echo "#### xpinfo ####"
which xpinfo >> xpinfo-which.${EXT} 2>&1
#${TOOLDIR}/xpinfo -v > ./xpinfo-v.${EXT} 2>&1
#${TOOLDIR}/xpinfo > ./xpinfo.${EXT} 2>&1
#${TOOLDIR}/xpinfo -i > ./xpinfo-i.${EXT} 2>&1
#${TOOLDIR}/xpinfo -il > ./xpinfo-il.${EXT} 2>&1
#${TOOLDIR}/xpinfo -m > ./xpinfo-m.${EXT} 2>&1
xpinfo -v > ./xpinfo-v.${EXT} 2>&1
xpinfo > ./xpinfo.${EXT} 2>&1
xpinfo -i > ./xpinfo-i.${EXT} 2>&1
xpinfo -il > ./xpinfo-il.${EXT} 2>&1
xpinfo -m > ./xpinfo-m.${EXT} 2>&1

# echo "#### HP3PARInfo ####"
which HP3PARInfo >> ./HP3PARInfo-which.${EXT} 2>&1
HP3PARInfo -v > ./HP3PARInfo-v.${EXT} 2>&1
HP3PARInfo -i > ./HP3PARInfo-i.${EXT} 2>&1
HP3PARInfo -ea > ./HP3PARInfo-ea.${EXT} 2>&1

# for RHEL5
#cp -p /proc/scsi/scsi ./scsi
#cp -p /etc/rc.local ./rc.local
#cp -p /etc/multipath.conf ./multipath.conf
#cp -p /var/lib/multipath/bindings ./bindings
#cp -p /etc/scsi_id.config ./scsi_id.config
#cp -pr /etc/iscsi ./iscsi
#cp -p /etc/modprobe.conf ./modprobe.conf
#cp -pr /etc/udev ./udev
#cp -p /var/log/messages ./messages
#cp -p /boot/grub/grub.conf ./grub.conf

# for RHEL6
#cp -p /proc/scsi/scsi ./scsi
#cp -p /etc/rc.local ./rc.local
#cp -p /etc/multipath.conf ./multipath.conf
#cp -p /etc/multipath/bindings ./bindings
#cp -p /etc/scsi_id.config ./scsi_id.config
#cp -pr /etc/iscsi ./iscsi
#cp -pr /etc/modprobe.d ./modprobe.d
#cp -pr /etc/udev ./udev
#cp -p /var/log/messages ./messages
#cp -p /boot/grub/grub.conf ./grub.conf

# for RHEL7
cp -p /proc/scsi/scsi ./scsi
cp -p /etc/rc.local ./rc.local
cp -p /etc/multipath.conf ./multipath.conf
cp -p /etc/multipath/bindings ./bindings
cp -p /etc/scsi_id.config ./scsi_id.config
cp -pr /etc/iscsi ./iscsi
cp -pr /etc/modprobe.d ./modprobe.d
cp -pr /etc/udev ./udev
cp -p /var/log/messages ./messages
cp -p /etc/grub2-efi.cfg ./grub2-efi.cfg

# for Qlogic FC-HBA Driver
cat /sys/module/qla2xxx/parameters/ql2xmaxqdepth >> ./ql2xmaxqdepth.${EXT} 2>&1
cat /sys/module/qla2xxx/parameters/qlport_down_retry >> ./qlport_down_retry.${EXT} 2>&1
cat /sys/module/qla2xxx/parameters/ql2xloginretrycount >> ./ql2xloginretrycount.${EXT} 2>&1

# echo "#### RMXP ####"
cp -p /etc/services ./services
cp -p /etc/horcm*.conf .

pwd
ls -l ${HOMEDIR}

echo "`date +'%Y/%m/%d %T'`"
echo "#### done ####"
