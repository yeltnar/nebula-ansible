# -K is used for BECOME (root) password
ansible-playbook -Ki inventory.yml nebula-playbook.yml

# its tricky to update phones' certs. you may want to make a ca just for the phones and add them to each device so it can approve connections 