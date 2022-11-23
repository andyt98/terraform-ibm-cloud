# Configure the IBM Provider
provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region
}

data "ibm_resource_group" "resource_group" {
  name = "default"
}

# Step 1: Create a single zone cluster
# Create an Terraform on IBM Cloud configuration file for your single zone cluster. 
# The following example creates a single zone cluster in the dal10 zone with a default worker pool 
# that consists of 3 worker nodes that are connected to a private and public VLAN in dal10

resource "ibm_container_cluster" "tfcluster" {
  name            = "tfclusterdoc"
  datacenter      = "dal10"
  machine_type    = "b3c.4x16"
  hardware        = "shared"
  public_vlan_id  = "2234945"
  private_vlan_id = "2234947"

  kube_version = "1.21.9"
  # kube_version = "3.11_openshift"

  default_pool_size        = 3
  public_service_endpoint  = "true"
  private_service_endpoint = "true"

  resource_group_id = data.ibm_resource_group.resource_group.id
}

# Step 2: Convert your single zone cluster into a multizone cluster
# Add zones to the default worker pool in your cluster that you created in step 1.
# By adding zones, the same number of worker nodes that you created in step 1 are spread across
# these zones converting your single zone cluster into a multizone cluster.

resource "ibm_container_worker_pool_zone_attachment" "dal12" {
  cluster           = ibm_container_cluster.tfcluster.id
  worker_pool       = ibm_container_cluster.tfcluster.worker_pools.0.id
  zone              = "dal12"
  private_vlan_id   = "<private_vlan_ID_dal12>"
  public_vlan_id    = "<public_vlan_ID_dal12>"
  resource_group_id = data.ibm_resource_group.resource_group.id
}

resource "ibm_container_worker_pool_zone_attachment" "dal13" {
  cluster           = ibm_container_cluster.tfcluster.id
  worker_pool       = ibm_container_cluster.tfcluster.worker_pools.0.id
  zone              = "dal13"
  private_vlan_id   = "<private_vlan_ID_dal13>"
  public_vlan_id    = "<public_vlan_ID_dal13>"
  resource_group_id = data.ibm_resource_group.resource_group.id
}

# Step 3: Add a worker pool to your cluster
# Create another worker pool in your cluster and add zones to the worker pool to add more
# worker nodes to your cluster.

resource "ibm_container_worker_pool" "workerpool" {
  worker_pool_name = "tf-workerpool"
  machine_type     = "u3c.2x4"
  cluster          = ibm_container_cluster.tfcluster.id
  size_per_zone    = 2
  hardware         = "shared"

  resource_group_id = data.ibm_resource_group.resource_group.id
}

resource "ibm_container_worker_pool_zone_attachment" "tfwp-dal10" {
  cluster         = ibm_container_cluster.tfcluster.id
  worker_pool     = element(split("/", ibm_container_worker_pool.workerpool.id), 1)
  zone            = "dal10"
  private_vlan_id = "<private_vlan_ID_dal10>"
}

# Step 4: Remove the default worker pool from your cluster

# resource "null_resource" "delete-default-worker-pool" {
#     provisioner "local-exec" {
#     command = "ibmcloud ks worker-pool rm --cluster ${ibm_container_cluster.tfcluster.id} --worker-pool ${ibm_container_cluster.tfcluster.worker_pools.0.id}"
#     }
# }
