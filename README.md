# AffinityScripts

Scripts to test soft-affinity and soft-anti-affinity features.  Soft Affinity Policies are a downstream only feature so these tests can't be accepted upstream.  

These tests should be run on a deployment with 2 compute nodes (exception - anti-affinity-same-compute.sh needs to be run on a system with only 1 compute node for now).  Flavors may need to be adjusted for the deployment.  m1.small should be small enough that two instances can be created on the same node, whereas m1.large should be large enough that only one instance can be created per node.
