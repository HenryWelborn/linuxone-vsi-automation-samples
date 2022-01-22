# Deploys web server in zVSI with Ansible

## Preparations

1. Install Python3
2. Install [RedHat Ansible] 2.9+
   - `pip install "ansible>=2.9.2"`
3. Install IBM cloud ansible
   - `ansible-galaxy collection install ibm.cloudcollection`
4. Adjust [ansible settings](group_vars/all.yml)
5. Ensure you have an `IC_API_KEY` environment variable set up with your
   IBM Cloud API key
    - this will likelly require a paying account


## Create

1. `ansible-playbook create.yml`

## Destroy

1. `ansible-playbook destroy.yml`
   - Note: VPC and subnetworks will not be deleted by default - change the `destroy_vpc` value in
     [ansible settings](group_vars/all.yml) if you want them deleted.
   - Note: the SSH public key will not be deleted by default - change the `destroy_ssh_key` value in
     [ansible settings](group_vars/all.yml) if you want it deleted.
2. Delete `.cache` folder
