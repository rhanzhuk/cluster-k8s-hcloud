Command for start
touch terraform.tfvars >>
hcloud_token = "<HCLOUD_TOKEN>"

cd terraform

terraform init
terraform apply
cd ../ansible
ansible-playbook -i inventory.ini playbooks/pre-install.yml











