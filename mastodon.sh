#!/bin/bash

###
# MASTODON.SH
ver="unreleased"
# Experimental bash implementation of the Mastodon API.
###

mdsh-debug() {
    # Usage: mdsh-debug type "message"
    echo "$1 $2"
}

# Init

client_id="$1"
client_secret="$2"
auth_token="$3"

if [ -z "$client_id" ] || [ -z "$client_secret" ] || [ -z $auth_token ]; then 
    fail="true"
    mdsh-debug error "You're missing the client ID, client secret or auth token!";
    mdsh-debug cont "Please supply the credentials while running mastodon.sh."
    mdsh-debug cont "Usage: mastodon.sh client_id client_secret auth_token"
    mdsh-debug cont "Mastodon.sh will NOT work. Exiting..."
    exit 1
fi

if [ -z $instance ]; then
    mdsh-debug note "No instance specified! To select an instance, create a variable called 'instance' with the instance domain (without the ending slash or http/https prefix)."
    mdsh-debug cont "Defaulting to mastodon.social..."
    instance="mastodon.social"
fi

dependencies="curl wget"

for dependency in $dependencies; do 
    if ! hash $dependency 2>/dev/null; then 
    mdsh-debug error "$dependency not found! Please install $dependency for mastodon.sh to work. Exiting..."
    exit 1  
    fi
done

mdsh-debug note "mastodon.sh version $ver started up."

func_cleanup() {
    # Clean up after functions.
    fail=""
    media=""
    content=""
    request=""
}


#############################
#       READ FUNCTIONS      #
#############################

read_status() {
    if [ -z $1 ]; then mdsh-debug error "No ID specified, nothing to read!"; fail="true"; else fail="false"; fi
    
    if [ $fail = "false" ]; then
    # Send the request
    printf "$(curl https://$instance/api/v1/statuses/$1 --silent -X GET | grep -Po '"$2":.*?[^\\]"')" | sed "s/&apos;/'/g" #somehow it works, without the ending curly brace and without the ending quote.
    fi
}

read_status_full() {
    if [ -z $1 ]; then mdsh-debug error "No ID specified, nothing to read!"; fail="true"; else fail="false"; fi
    
    if [ $fail = "false" ]; then
    # Send the request
    printf "$(curl https://$instance/api/v1/statuses/$1 --silent -X GET)" #somehow it works, without the ending curly brace and without the ending quote.
    fi
}

#############################
#      WRITE FUNCTIONS      #
#############################

write_status() {
    if [ -z "$media1" ] && [ -z "$content" ]; then mdsh-debug error "Nothing to post!"; fail="true"; else fail="false"; fi
    if [ $fail = "false" ]; then
        if [ -z "$media1" ]
        then
            mdsh-debug note "Media 1 not specified."
            mdsh-debug cont "There will be no media in the final call."
        fi
        if [ -z "$content" ]; then mdsh-debug note "No content, only media will be posted."; fi
        if [ -z "$content_warning" ]; then mdsh-debug note "No content warning."; fi
        # Prepare the request
        if [ -z $sensitive ]; then mdsh-debug note "No sensitive variable! Post will be marked as non-sensitive."; sensitive="false"; fi
        request="sensitive=$sensitive&status=$content"

        # Send the request
        curl https://$instance/api/v1/statuses -X POST -d "$request&access_token=$auth_token"
    fi
    func_cleanup
}

write_media() {

    #def media_post(self, media_file, mime_type=None, description=None, focus=None):
        
    if [ -z $1 ]; then mdsh-debug error "No file specified!"; fail="true"; else fail="false"; fi
    if [ "$fail" = "false" ]; then
        mime_type="$(file -b --mime-type $1)"
        image_filename="mastodonsh_$(date +"%H%M%S")_$(cat /dev/urandom | tr -dc 'A-Z0-9' | fold -w 10 | head -n 1).png"
        echo "$image_filename"  
        media_file_description="('$image_filename', '$1', '$mime_type')"
        request="{'file': $media_file_description, 'description': $image_description, 'focus': None, 'access_token': $auth_token}"
        
        #return self.__api_request('POST', '/api/v1/media',
        #                          files={'file': media_file_description},
        #                          params={'description': description, 'focus': focus})

        curl -i \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -X POST -d "files={'file': $media_file_description},
params={'description': $image_description, 'focus': 0}" "https://$instance/api/v1/media"
    fi
    func_cleanup
}