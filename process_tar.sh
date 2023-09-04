#!/bin/bash
if [ -z "$NOT_ROOT" ]; then
    export NOT_ROOT='false';
fi

# vars from ansible 
if [ -z "$nebula_config_client_folder" ]; then
  nebula_config_client_folder="/etc/nebula";
fi
if [ -z "$var_dir" ]; then 
  var_dir="/var/yeltnar-nebula";
fi

if [ -z "$SUDO_USER" ]; then # not running as root, use current info 
  BASHRC_HOME="$HOME";
  REAL_USER="$USER"
else
  REAL_USER=$SUDO_USER
  BASHRC_HOME=$(su $REAL_USER -c 'echo $HOME')
fi

localDecrypt(){

  mkdir -p "$workdir" # this will fail if var_dir is not there 

  $BASHRC_HOME/playin/custom_bashrc/bin/rsa_enc decrypt
}

extractContent(){
  cd "$tar_location"
  $BASHRC_HOME/playin/custom_bashrc/bin/extract out.tar

  chown "$REAL_USER" *
}

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

joinCaCrts(){
  # TODO there are some rotten vars here 
  # need root 
  cd "$nebula_config_client_folder"

  out_file="$nebula_config_client_folder/ca.crt"

  printf "" > "$out_file" # clear the current file

  ls inputfiles | awk '/ca.crt/{print "cat inputfiles/" $1 " >> ca.crt"}' | bash
}

# checks if provided function is in the lit of functions
if [ "true" = "$NOT_ROOT" ]; then

  if [ -z "$PRIVKEY" ]; then
    export PRIVKEY=$PWD/id_rsa
  fi
  if [ -z "$AES_KEY_ENC" ]; then
    export AES_KEY_ENC=$PWD/out.pass.enc;
  fi
  if [ -z "$ENCRYPTED_FILE" ]; then
    export ENCRYPTED_FILE=$PWD/out.tar.enc;
  fi
  if [ -z "$DECRYPTED_FILE" ]; then
    export DECRYPTED_FILE=$PWD/out.tar; 
  fi
  if [ -z "$workdir" ]; then
    export workdir="$PWD"
  fi
  if [ -z "$tar_location" ]; then
    export tar_location="$PWD";
  fi

  localDecrypt
  extractContent
else 
  export PRIVKEY=$var_dir/id_rsa          
  export AES_KEY_ENC=$var_dir/tar_stuff/out.pass.enc;
  export ENCRYPTED_FILE=$var_dir/tar_stuff/out.tar.enc;
  export DECRYPTED_FILE=$var_dir/tar_stuff/out.tar; 
  export workdir="$var_dir/workdir";

  if [ -z "$tar_location" ]; then
    export tar_location="$var_dir/tar_stuff";
  fi

  localDecrypt
  extractContent
  moveFiles
  joinCaCrts
fi
