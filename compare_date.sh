#!/bin/bash

# this needs to be run as root for non-phones... like not with sudo, but change to the root user... for some reason 
# ie sudo su -c './compare_date.sh'

# https://hot.mini.lan/nebula/pixel6.date
# https://hot.mini.lan/nebula/pixel6.pass.enc
# https://hot.mini.lan/nebula/pixel6.tar.enc

if [ -e '.env' ]; then
    source .env;
fi

if [ -z "$BASE_URI" ]; then
    echo "\$BASE_URI is not defined; Exiting";
    exit -1;
fi
if [ -z "$DEVICE_NAME" ]; then
    echo "\$DEVICE_NAME is not defined; Exiting";
    exit -1;
fi
if [ -z "$TEST_FILE_PATH" ]; then
    echo "\$TEST_FILE_PATH is not defined; Exiting";
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

if [ "true" = "$NOT_ROOT" ]; then
  export tar_location="$PWD";
else
  export tar_location="$var_dir/tar_stuff"; # this will fail if the tar dir does not exsist 
fi

download(){
    # TODO !!! remove `-k`
    curl -k -o "$tar_location/out.pass.enc" "$BASE_URI/$DEVICE_NAME.pass.enc"
    curl -k -o "$tar_location/out.tar.enc" "$BASE_URI/$DEVICE_NAME.tar.enc"
}

restartNebula(){
    echo 'restarting nebula';
    systemctl restart nebula && echo 'nebula restarted' || echo 'nebula could not restart'
}

process(){
    ./process_tar.sh 
}

takeActions(){
     # TODO make sure we're not a phone for restartNebula
    download &&
    process && 
    restartNebula

    # TODO notify it got a new config 
}

changeHost(){
    export HOST=$SECONDARY_HOST;
    export PORT=$SECONDARY_PORT;
    echo "changed to $SECONDARY_HOST:$SECONDARY_PORT";
}

if [ -e "$TEST_FILE_PATH" ]; then

    ping -c1 $HOST || changeHost;

    echo "HOST is $HOST"
    echo "PORT is $PORT"

    export BASE_URI="https://$HOST:$PORT/nebula"

    echo "$BASE_URI/$DEVICE_NAME.date"
    remote_date=$(curl -k "$BASE_URI/$DEVICE_NAME.date" 2>/dev/null )
    local_date=$(date -r "$TEST_FILE_PATH" "+%s")

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
