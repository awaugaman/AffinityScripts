#!/bin/bash

source /home/stack/overcloudrc
echo
echo -e "===============SET UP PHASE===============\n"

#Create Server Groups
echo -e "==========Creating Affinity Group==========\n"

echo nova server-group-create soft-affinity-group soft-affinity
nova server-group-create soft-affinity-group soft-affinity
echo 

#Save ID for later
export AFFINITY_ID=`nova server-group-list | grep soft-affinity-group | awk '{print $2}'`

echo -e "==========Affinity Group Created==========\n"

#Create Flavor
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

#Save ID for later
export FLAVOR_ID=`openstack flavor list | grep m1.small | awk '{print $2}'`

echo -e "==========Flavor Created==========\n"

#Create Image
echo -e "==========Creating Images==========\n"
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

#Save ID for later
export CIRROS_ID=`openstack image list | grep cirros | awk '{print $2}'`

echo -e "==========Image Created==========\n"

echo -e "===============SET UP FINISHED===============\n"

#Begin the test
echo -e "===============TEST PHASE===============\n"

#Boot 2 Affinity Servers on the same host
echo -e "==========Creating Soft-Affinity-Servers==========\n"

#Grab the network to boot the server off of
if [ -z "`openstack network list | grep private`" ];then
  if [ -z "`openstack network list | grep public`" ];then 
   export NETWORK_ID=`openstack network list | grep nova | awk '{print $2}'`
  else
   export NETWORK_ID=`openstack network list | grep public | awk '{print $2}'`
  fi
else
  export NETWORK_ID=`openstack network list | grep private | awk '{print $2}'`

#Boot the servers
echo openstack server create --flavor $FLAVOR_ID --image $CIRROS_ID --hint group=$AFFINITY_ID --nic net-id=$NETWORK_ID soft-affinity-server0
openstack server create --flavor $FLAVOR_ID --image $CIRROS_ID --hint group=$AFFINITY_ID --nic net-id=$NETWORK_ID soft-affinity-server0

export SERVER0_ID=`openstack server list | grep soft-affinity-server0 | awk '{print $2}'`
echo

sleep 60

echo openstack server create --flavor $FLAVOR_ID --image $CIRROS_ID --hint group=$AFFINITY_ID --nic net-id=$NETWORK_ID soft-affinity-server1
openstack server create --flavor $FLAVOR_ID --image $CIRROS_ID --hint group=$AFFINITY_ID --nic net-id=$NETWORK_ID soft-affinity-server1

export SERVER1_ID=`openstack server list | grep soft-affinity-server1 | awk '{print $2}'`
echo

sleep 60

echo -e "==========Soft-Affinity-Servers Created==========\n"

echo -e "===============SET UP FINISHED===============\n"

#Check to make sure they're on the same hypervisor
echo -e "===============PRE-CHECK PHASE===============\n"
export S0_HYPERVISOR=`openstack server show $SERVER0_ID | grep hypervisor_hostname | awk '{print $4}'`
 
echo Server 0 Hypervisor:
echo $S0_HYPERVISOR
echo
 
export S1_HYPERVISOR=`openstack server show $SERVER1_ID | grep hypervisor_hostname | awk '{print $4}'`
 
echo Server 1 Hypervisor:
echo $S1_HYPERVISOR
echo

if [ -z $S0_HYPERVISOR ] || [ -z $S1_HYPERVISOR ];then
  echo At least one server did not boot successfully.  Exiting Script
  exit 1
fi

if [[ $S0_HYPERVISOR = $S1_HYPERVISOR ]];then
  echo "+------------------------------------------------+"
  echo "|      PRE-CHECK PASSED - HYPERVISORS MATCH      |"
  echo "+------------------------------------------------+"

else
  echo "+------------------------------------------------+"
  echo "|   PRE-CHECK FAILED - HYPERVISORS DON'T MATCH   |"
  echo "+------------------------------------------------+"
  exit 1
fi
echo

echo -e "===============PRE-CHECK PHASE FINISHED===============\n"

echo -e "===============TEST PHASE===============\n"

echo -e "===============Testing Evacuate===============\n"

#Get the IDs for the compute nodes to down them for evacuates
export COMPUTE0_ID=`nova service-list | grep compute-0.localdomain | awk '{print $2}'`
export COMPUTE1_ID=`nova service-list | grep compute-1.localdomain | awk '{print $2}'`

#Down the service for the compute node, evacuate the instance, and then bring the service back online
if [[ $S0_HYPERVISOR = "compute-0.localdomain" ]];then
  echo Taking down compute 0
  echo nova service-force-down $COMPUTE0_ID
  nova service-force-down $COMPUTE0_ID
  echo
  
  sleep 30
  
  echo nova evacuate $SERVER0_ID
  nova evacuate $SERVER0_ID
  echo
  
  sleep 60

  echo nova service-force-down --unset $COMPUTE0_ID
  nova service-force-down --unset $COMPUTE0_ID
  echo

else
  echo Taking down compute 1
  echo nova service-force-down $COMPUTE1_ID
  nova service-force-down $COMPUTE1_ID
  echo

  sleep 30

  echo nova evacuate $SERVER0_ID
  nova evacuate $SERVER0_ID 
  echo

  sleep 60 

  echo nova service-force-down --unset $COMPUTE1_ID
  nova service-force-down --unset $COMPUTE1_ID
  echo

fi 

export S0_HYPERVISOR=`openstack server show $SERVER0_ID | grep hypervisor_hostname | awk '{print $4}'`

echo
echo Server 0 Hypervisor:
echo $S0_HYPERVISOR
echo

export S1_HYPERVISOR=`openstack server show $SERVER1_ID | grep hypervisor_hostname | awk '{print $4}'`

echo Server 1 Hypervisor:
echo $S1_HYPERVISOR
echo

if [[ $S0_HYPERVISOR != $S1_HYPERVISOR ]];then
  echo "+------------------------------------------------+"
  echo "|     TEST PASSED - HYPERVISORS DON'T MATCH      |"
  echo "+------------------------------------------------+"

else
  echo "+------------------------------------------------+"
  echo "|        TEST FAILED - HYPERVISORS MATCH         |"
  echo "+------------------------------------------------+"
  exit 1
fi

#Down the service for the compute node, evacuate the instance, and then bring the service back online
if [[ $S1_HYPERVISOR = "compute-0.localdomain" ]];then
  echo Taking down compute 0
  echo nova service-force-down $COMPUTE0_ID
  nova service-force-down $COMPUTE0_ID
  echo

  sleep 30

  echo nova evacuate $SERVER1_ID
  nova evacuate $SERVER1_ID
  echo

  sleep 60

  echo nova service-force-down --unset $COMPUTE0_ID
  nova service-force-down --unset $COMPUTE0_ID
  echo

else
  echo Taking down compute 1
  echo nova service-force-down $COMPUTE1_ID
  nova service-force-down $COMPUTE1_ID
  echo

  sleep 30

  echo nova evacuate $SERVER1_ID
  nova evacuate $SERVER1_ID
  echo

  sleep 60

  echo nova service-force-down --unset $COMPUTE1_ID
  nova service-force-down --unset $COMPUTE1_ID
  echo

fi

export S0_HYPERVISOR=`openstack server show $SERVER0_ID | grep hypervisor_hostname | awk '{print $4}'`

echo
echo Server 0 Hypervisor:
echo $S0_HYPERVISOR
echo

export S1_HYPERVISOR=`openstack server show $SERVER1_ID | grep hypervisor_hostname | awk '{print $4}'`

echo Server 1 Hypervisor:
echo $S1_HYPERVISOR
echo

if [[ $S0_HYPERVISOR = $S1_HYPERVISOR ]];then
  echo "+------------------------------------------------+"
  echo "|        TEST PASSED - HYPERVISORS MATCH         |"
  echo "+------------------------------------------------+"

else
  echo "+------------------------------------------------+"
  echo "|     TEST FAILED - HYPERVISORS DON'T MATCH      |"
  echo "+------------------------------------------------+"
  exit 1
fi


echo -e "===============TEST PHASE FINISHED===============\n"

#Cleanup
echo -e "===============CLEAN UP PHASE===============\n"

echo -e "==========Deleting server-groups==========\n"
if [ "`nova server-group-list | grep soft-affinity-group`" ];then
  nova server-group-delete $AFFINITY_ID
fi
echo -e "==========Server-Groups Deleted==========\n"

echo -e "==========Deleting servers==========\n"
if [ "`openstack server list | grep soft-affinity-server0`" ];then
  openstack server delete $SERVER0_ID
fi

if [ "`openstack server list | grep soft-affinity-server1`" ];then
  openstack server delete $SERVER1_ID
fi
echo -e "==========Servers deleted==========\n"

echo -e "===============CLEAN UP FINISHED===============\n"

