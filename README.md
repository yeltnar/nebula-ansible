# -K is used for BECOME (root) password
ansible-playbook -Ki inventory.yml nebula-playbook.yml | tee /tmp/ansible-nebula.log

# its tricky to update phones' certs. you may want to make a ca just for the phones and add them to each device so it can approve connections 

# when using the .plist file on MacOS, make sure to run `sudo launchd load com.yeltnar.nebula.plist` so the network interface can be created

# ssh key needs to be in rsa pem format. this is generated in the playbook
# ssh-keygen -t rsa -m PEM
