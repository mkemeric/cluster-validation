#!/bin/bash
# jbenninghoff@maprtech.com 2013-Sep-19  vi: set ai et sw=3 tabstop=3:

clush -a -B umount /mapr
clush -a -B service mapr-warden stop
clush -a -B service mapr-zookeeper stop
clush -a -B jps; clush -a -B 'ps ax | grep mapr'
echo Make sure all MapR Hadoop processes have stopped
sleep 9
clush -a -B jps; clush -a -B 'ps ax | grep mapr'

# Edit the url for version and edit the path to the yum repo file as needed
sed -i '/baseurl=.*package.mapr.com/{s,^.*$,baseurl=http://package.mapr.com/releases/v3.0.1/redhat,;q}' /etc/yum.repos.d/mapr.repo
[ $? != 0 ] && { echo "/etc/yum.repos.d/mapr.repo not found or needs hand edit"; exit; }
clush -abc /etc/yum.repos.d/mapr.repo  # Copy the edited mapr.repo file to all the nodes
clush -ab yum clean all

#yum --disablerepo=maprecosystem check-update mapr-\* | grep ^mapr #If you want to preview the updates
clush -ab 'yum -y --disablerepo=maprecosystem update mapr-\*'
clush -ab '/opt/mapr/server/configure.sh -R -u mapr -g mapr' # assuming MapR to be run as mapr user.  Update seems to reset MapR user to root

clush -a -B service mapr-zookeeper start
clush -a -B service mapr-warden start
clush -aB /opt/mapr/server/upgrade2mapruser.sh
sleep 9; clush -a -B mount /mapr
maprcli config save -values {mapr.targetversion:"$(</opt/mapr/MapRBuildVersion)"}  # This can be done through MCS also
maprcli config save -values {"cldb.v3.features.enabled":"1"}

# If CLDB has problems restarting or MapR FS needs rebuilding
#maprcli config save -values {"cldb.ignore.stale.zk":"true"}
#clush -Ba '/opt/mapr/zookeeper/zk_cleanup.sh'
#clush -Ba 'rm -rf /opt/mapr/zkdata/version-2/*'
# After restarting warden run next line
#maprcli config save -values {"cldb.ignore.stale.zk":"false"}

# Rebuild the MapR filesystem, destroys all data, normally not wanted
#clush -a -B service mapr-warden stop
#clush -a -B service mapr-zookeeper stop
#clush -Ba 'rm -f /opt/mapr/conf/disktab'
#clush -Ba "lsblk -id | grep -o ^sd. | grep -v ^sda |sort|sed 's,^,/dev/,' | tee /tmp/disk.list; wc /tmp/disk.list"
#clush -Ba '/opt/mapr/server/disksetup -W $(cat /tmp/disk.list | wc -l) -F /tmp/disk.list'
