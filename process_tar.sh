#!/bin/bash

# vars from ansible 
if [ -z "$nebula_config_client_folder" ]; then
  nebula_config_client_folder="/etc/nebula";
fi
if [ -z "$var_dir" ]; then 
  var_dir="/var/yeltnar-nebula";
fi

SUDO_USER_HOME=$(su $SUDO_USER -c 'echo $HOME')

localDecrypt(){
  export PRIVKEY=$var_dir/id_rsa          
  export AES_KEY_ENC=$var_dir/tar_stuff/out.pass.enc;
  export ENCRYPTED_FILE=$var_dir/tar_stuff/out.tar.enc;
  export DECRYPTED_FILE=$var_dir/tar_stuff/out.tar; 
  export workdir="$var_dir/workdir"

  mkdir -p "$workdir" # this will fail if var_dir is not there 

  $SUDO_USER_HOME/playin/custom_bashrc/bin/rsa_enc decrypt
}
localDecrypt

extractContent(){
  cd $var_dir/tar_stuff/
  $SUDO_USER_HOME/playin/custom_bashrc/bin/extract out.tar

  chown "$SUDO_USER" *
}
extractContent

moveFiles(){
  #  TODO ignore errors when copying 
  # need root
  cp "$nebula_config_client_folder/inputfiles/ansible.ca.crt.new" "$nebula_config_client_folder/inputfiles/ansible.ca.crt.old" 

  # need root
  declare -a str_arr=("host.crt" "host.key" "config.yml")

  for val in ${str_arr[@]}; do
      cp "$var_dir/tar_stuff/$val" "$nebula_config_client_folder/$val"
  done

  # need root 
  cp "$var_dir/tar_stuff/ca.crt" "$nebula_config_client_folder/inputfiles/ansible.ca.crt.new"
}
moveFiles

joinCaCrts(){
  # TODO need root 
  cd "$nebula_config_client_folder"

  out_file="$nebula_config_client_folder/ca.crt"

  printf "" > "$out_file" # clear the current file

  ls inputfiles | awk '/ca.crt/{print "cat inputfiles/" $1 " >> ca.crt"}' | bash
}
joinCaCrts

