#!/bin/bash

# this needs to be run as root for non-phones... like not with sudo, but change to the root user... for some reason 
# ie sudo su -c './compare_date.sh'

# https://hot.mini.lan/nebula/pixel6.date
# https://hot.mini.lan/nebula/pixel6.pass.enc
# https://hot.mini.lan/nebula/pixel6.tar.enc

if [ -e '.env' ]; then
    source .env;
fi

if [ -z "$DEVICE_NAME" ]; then
    echo "\$DEVICE_NAME is not defined; Exiting";
    exit -1;
fi
if [ -z "$DATE_FILE_PATH" ]; then
    echo "\$DATE_FILE_PATH is not defined; Exiting";
    exit -1;
fi

if [ -z "$NOT_ROOT" ]; then
    export NOT_ROOT='false';
fi

if [ "$NOT_ROOT" = 'false' ]; then
    if [ -z "$var_dir" ]; then
        echo "var_dir is not defined; exiting"
        exit -1;
    fi
fi

  export tar_location="$var_dir/tar_stuff"; # this will fail if the tar dir does not exsist 

download(){
    echo "downloading $DEVICE_NAME files from $BASE_URI";
    mkdir -p $tar_location
    set -x
    curl $CURL_OPTIONS -o "$tar_location/out.pass.enc" "$BASE_URI/$DEVICE_NAME.pass.enc"
    curl $CURL_OPTIONS -o "$tar_location/out.tar.enc" "$BASE_URI/$DEVICE_NAME.tar.enc"
    curl $CURL_OPTIONS -o "$tar_location/remote_updated.date" "$BASE_URI/$DEVICE_NAME.date"
    set +x
}

restartNebula(){
    echo 'waiting to restarting nebula';
    sleep 15;
    echo 'restarting nebula';
    systemctl restart nebula && echo 'nebula restarted' || echo 'nebula could not restart'
}

process(){
    echo process
    ./process_tar.sh 
}

notifyNewVersion(){
    if [ -z "$SUDO_USER" ]; then # not running as root, use current info 
        BASHRC_HOME="$HOME";
        REAL_USER="$USER"
    else
        REAL_USER=$SUDO_USER
        BASHRC_HOME=$(su $REAL_USER -c 'echo $HOME')
        export bashrc_folder="$BASHRC_HOME/playin/custom_bashrc"
    fi

    PATH="$PATH:$BASHRC_HOME/playin/custom_bashrc/bin"

    send_push "New nebula config" "$DEVICE_NAME - `date`";
}

takeActions(){
    # TODO make sure we're not a phone for restartNebula
    download &&
    notifyNewVersion && 
    process && 
    restartNebula

    # TODO notify it got a new config 
}

changeHost(){
    export HOST=$SECONDARY_HOST;
    export PORT=$SECONDARY_PORT;
    echo "changed to $SECONDARY_HOST:$SECONDARY_PORT";
}

date

ping -c1 $HOST || changeHost;

echo "HOST is $HOST"
echo "PORT is $PORT"

export BASE_URI="https://$HOST:$PORT/nebula"

if [ -e "$DATE_FILE_PATH" ]; then

    set -x
    echo "$BASE_URI/$DEVICE_NAME.date"
    remote_date=$(curl $CURL_OPTIONS "$BASE_URI/$DEVICE_NAME.date" 2>/dev/null )
    local_date=$(cat "$DATE_FILE_PATH")
    set +x

    if [ -z "$remote_date" ]; then
        echo "\$remote_date is empty">&2
        exit -1;
    fi

    if [ -z "$local_date" ]; then
        echo "\$local_date is empty">&2
        exit -1;
    fi

    # test "$remote_date" > "$local_date" && echo true || echo false

    # if test file is not found
    # if test file is old 

    if [ "$remote_date" -gt "$local_date" ]; then
        echo 'New version found';
        takeActions
    else
        echo 'No new version found';
        exit -1;
    fi

else
    echo 'old file missing... downloading';
    takeActions
fi
