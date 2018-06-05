#!/bin/bash

source /home/stack/overcloudrc
echo

#Set up the system before the test
echo -e "===============SET UP PHASE===============\n"

#Create the anti-affinity group
echo -e "==========Creating Anti-Affinity Group==========\n"

echo nova server-group-create soft-anti-affinity-group soft-anti-affinity
nova server-group-create soft-anti-affinity-group soft-anti-affinity
echo 

#Save ID of the anti-affinity group for later
export ANTI_AFFINITY_ID=`nova server-group-list | grep soft-anti-affinity-group | awk '{print $2}'`

echo -e "==========Anti-Affinity Group Created==========\n"

#Create Flavor for servers
echo -e "==========Creating Flavor==========\n"

if [ -z "`openstack flavor list | grep m1.small`" ];then
  echo openstack flavor create --ram 512 --disk 5 --vcpus 1 m1.small
  openstack flavor create --ram 512 --disk 5 --vcpus 1 m1.small
  echo 
else
  echo openstack flavor show m1.small
  openstack flavor show m1.small
  echo 
fi

#Save ID of the flavor for later
export FLAVOR_ID=`openstack flavor list | grep m1.small | awk '{print $2}'`

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

if [ "`nova service-list | grep compute-1.localdomain`" ];then
  export COMPUTE1_ID=`nova service-list | grep compute-1.localdomain | awk '{print $2}'`
  echo Taking down compute 1 
  echo nova service-force-down $COMPUTE1_ID
  nova service-force-down $COMPUTE1_ID
  echo
fi

#Boot 2 Anti-Affinity Servers on the same host
echo -e "==========Creating Soft-Anti-Affinity-Servers==========\n"

#Grab the network to boot the server off of
if [ -z "`openstack network list | grep private`" ];then
  export NETWORK_ID=`openstack network list | grep nova | awk '{print $2}'`
else
  export NETWORK_ID=`openstack network list | grep private | awk '{print $2}'`
fi

#Boot the servers
echo openstack server create --flavor $FLAVOR_ID --image $CIRROS_ID --hint group=$ANTI_AFFINITY_ID --nic net-id=$NETWORK_ID soft-anti-affinity-server1 
openstack server create --flavor $FLAVOR_ID --image $CIRROS_ID --hint group=$ANTI_AFFINITY_ID --nic net-id=$NETWORK_ID soft-anti-affinity-server1
echo

sleep 60

echo openstack server create --flavor $FLAVOR_ID --image $CIRROS_ID --hint group=$ANTI_AFFINITY_ID --nic net-id=$NETWORK_ID soft-anti-affinity-server2
openstack server create --flavor $FLAVOR_ID --image $CIRROS_ID --hint group=$ANTI_AFFINITY_ID --nic net-id=$NETWORK_ID soft-anti-affinity-server2
echo

sleep 60

echo -e "==========Soft-Anti-Affinity-Servers Created==========\n"

if [ "`nova service-list | grep compute-1.localdomain`" ];then
  echo Starting up compute 1 
  echo nova service-force-down --unset $COMPUTE1_ID
  nova service-force-down --unset $COMPUTE1_ID
  echo
fi

#Compare the compute nodes of the servers to make sure they match
echo -e "==========Comparing Hypervisors==========\n"

export S1_HYPERVISOR=`openstack server show soft-anti-affinity-server1 -c OS-EXT-SRV-ATTR:hypervisor_hostname | grep hypervisor_hostname | awk '{print $4}'`

echo Server 1 Hypervisor:
echo $S1_HYPERVISOR
echo
 
export S2_HYPERVISOR=`openstack server show soft-anti-affinity-server2 -c OS-EXT-SRV-ATTR:hypervisor_hostname | grep hypervisor_hostname | awk '{print $4}'`
 
echo Server 2 Hypervisor:
echo $S2_HYPERVISOR
echo

if [ -z $S1_HYPERVISOR ] || [ -z $S2_HYPERVISOR ];then
  echo At least one server did not boot successfully.  Exiting Script
  exit 1
fi

if [[ $S1_HYPERVISOR = $S2_HYPERVISOR ]];then
   echo "+------------------------------------------------+"
   echo "|         TEST PASSED - HYPERVISORS MATCH        |"
   echo "+------------------------------------------------+"

else
   echo "+------------------------------------------------+"
   echo "|      TEST FAILED - HYPERVISORS DON'T MATCH     |"
   echo "+------------------------------------------------+"
fi
echo

echo -e "===============TEST PHASE FINISHED===============\n"

#Cleanup
echo -e "===============CLEAN UP PHASE===============\n"

echo -e "==========Deleting server-groups==========\n"

if [ "`nova server-group-list | grep soft-anti-affinity-group`" ];then
  nova server-group-delete $ANTI_AFFINITY_ID
fi

echo -e "==========Server-Groups Deleted==========\n"

echo -e "==========Deleting servers==========\n"

if [ "`openstack server list | grep soft-anti-affinity-server1`" ];then
  openstack server delete soft-anti-affinity-server1
fi

if [ "`openstack server list | grep soft-anti-affinity-server2`" ];then
  openstack server delete soft-anti-affinity-server2
fi

echo -e "==========Servers deleted==========\n"

echo -e "===============CLEAN UP FINISHED===============\n"
