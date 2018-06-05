# AffinityScripts

Scripts to test soft-affinity and soft-anti-affinity features.  Soft Affinity Policies are a downstream only feature so these tests can't be accepted upstream.  

These tests should be run on a deployment with 2 compute nodes.  Flavors may need to be adjusted for the deployment.  m1.small should be small enough that two instances can be created on the same node, whereas m1.large should be large enough that only one instance can be created per node.

Each script should be run on by itself.  They all have setup and cleanup stages so nothing should need to be done before or after execution.  If a test happens to fail, the script will exit to skip cleanup and allow debugging.
