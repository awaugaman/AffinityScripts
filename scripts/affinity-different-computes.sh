#!/bin/bash

source /home/stack/overcloudrc
echo

#Set up the system before the test
echo -e "===============SET UP PHASE===============\n"

#Create the affinity group
echo -e "==========Creating Affinity Group==========\n"

echo nova server-group-create soft-affinity-group soft-affinity
nova server-group-create soft-affinity-group soft-affinity
echo 

#Save ID of the affinity group for later
export AFFINITY_ID=`nova server-group-list | grep soft-affinity-group | awk '{print $2}'`

echo -e "==========Affinity Group Created==========\n"

#Create Flavor for servers
echo -e "==========Creating Flavor==========\n"

if [ -z "`openstack flavor list | grep m1.large`" ];then
  echo openstack flavor create --ram 1024 --disk 10 --vcpus 1 m1.large
  openstack flavor create --ram 1024 --disk 10 --vcpus 1 m1.large
  echo
else
  echo openstack flavor show m1.large
  openstack flavor show m1.large
  echo 
fi

#Save ID of the flavor for later
export FLAVOR_ID=`openstack flavor list | grep m1.large | awk '{print $2}'`

echo -e "==========Flavor Created==========\n"

#Create Image for servers
echo -e "==========Creating Image==========\n"

if [ -z "`openstack image list | grep cirros`" ];then
  if [ ! -f /home/stack/cirros-0.4.0-x86_64-disk.img ];then
    wget http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img
  fi
  echo openstack image create --file cirros-0.4.0-x86_64-disk.img cirros
  openstack image create --file cirros-0.4.0-x86_64-disk.img cirros
  echo 
else
  echo openstack image show cirros
  openstack image show cirros
  echo
fi

#Save ID of the image for later
export CIRROS_ID=`openstack image list | grep cirros | awk '{print $2}'`

echo -e "==========Image Created==========\n"

echo -e "===============SET UP FINISHED===============\n"

#Begin the test
echo -e "===============TEST PHASE===============\n"

#Boot 2 Affinity Servers on different hosts
echo -e "==========Creating Soft-Affinity-Servers==========\n"

#Grab the network to boot the server off of
if [ -z "`openstack network list | grep private`" ];then
  if [`openstack network list | grep public` ];then 
   export NETWORK_ID=`openstack network list | grep public | awk '{print $2}'`
  else
   export NETWORK_ID=`openstack network list | grep nova | awk '{print $2}'`
  fi
else
  export NETWORK_ID=`openstack network list | grep private | awk '{print $2}'`
fi

#Boot the servers
echo openstack server create --flavor $FLAVOR_ID --image $CIRROS_ID --hint group=$AFFINITY_ID --nic net-id=$NETWORK_ID soft-affinity-server1 
openstack server create --flavor $FLAVOR_ID --image $CIRROS_ID --hint group=$AFFINITY_ID --nic net-id=$NETWORK_ID soft-affinity-server1
echo

sleep 60

echo openstack server create --flavor $FLAVOR_ID --image $CIRROS_ID --hint group=$AFFINITY_ID --nic net-id=$NETWORK_ID soft-affinity-server2
openstack server create --flavor $FLAVOR_ID --image $CIRROS_ID --hint group=$AFFINITY_ID --nic net-id=$NETWORK_ID soft-affinity-server2
echo

sleep 60

echo -e "==========Soft-Affinity-Servers Created==========\n"

#Compare the compute nodes of the servers to make sure they match
echo -e "==========Comparing Hypervisors==========\n"

export S1_HYPERVISOR=`openstack server show soft-affinity-server1 -c OS-EXT-SRV-ATTR:hypervisor_hostname | grep hypervisor_hostname | awk '{print $4}'`

echo Server 1 Hypervisor:
echo $S1_HYPERVISOR
echo
 
export S2_HYPERVISOR=`openstack server show soft-affinity-server2 -c OS-EXT-SRV-ATTR:hypervisor_hostname | grep hypervisor_hostname | awk '{print $4}'`
 
echo Server 2 Hypervisor:
echo $S2_HYPERVISOR
echo

if [ -z $S1_HYPERVISOR ] || [ -z $S2_HYPERVISOR ];then
  echo At least one server did not boot successfully.  Exiting Script
  exit 1
fi

if [[ $S1_HYPERVISOR != $S2_HYPERVISOR ]];then
   echo "+------------------------------------------------+"
   echo "|      TEST PASSED - HYPERVISORS DON'T MATCH     |"
   echo "+------------------------------------------------+"

else
   echo "+------------------------------------------------+"
   echo "|        TEST FAILED - HYPERVISORS MATCH         |"
   echo "+------------------------------------------------+"
fi
echo

echo -e "===============TEST PHASE FINISHED===============\n"

#Cleanup
echo -e "===============CLEAN UP PHASE===============\n"

echo -e "==========Deleting server-groups==========\n"

if [ "`nova server-group-list | grep soft-affinity-group`" ];then
  nova server-group-delete $AFFINITY_ID
fi

echo -e "==========Server-Groups Deleted==========\n"

echo -e "==========Deleting servers==========\n"

if [ "`openstack server list | grep soft-affinity-server1`" ];then
  openstack server delete soft-affinity-server1
fi

if [ "`openstack server list | grep soft-affinity-server2`" ];then
  openstack server delete soft-affinity-server2
fi

echo -e "==========Servers deleted==========\n"

echo -e "===============CLEAN UP FINISHED===============\n"
