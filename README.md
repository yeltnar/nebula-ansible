# -K is used for BECOME (root) password
ansible-playbook -Ki inventory.yml nebula-playbook.yml | tee /tmp/ansible-nebula.log

# just do generation for 'other hosts' 
ansible-playbook -Ki inventory.small.yml --tags on_orch nebula-playbook.yml | tee /tmp/ansible-nebula.log

# its tricky to update phones' certs. you may want to make a ca just for the phones and add them to each device so it can approve connections 

# start mac service
sudo launchctl load com.yeltnar.nebula.plist

# ssh key needs to be in rsa pem format. this is generated in the playbook
# ssh-keygen -t rsa -m PEM
