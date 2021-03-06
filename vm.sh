#!/usr/bin/bash
VERSION="0.1.3"

#################################################
# Depends on:                                   #
# jq                                            #
# python3                                       #
#################################################

#################################################
# Help                                          #
#################################################
Help()
{
  # Display Help
  echo "Used to create a new vm"
  echo
  echo "Example usage:"
  echo "./vm.sh -e ./.nuc.env -n bd-test-1"
  echo
  echo "Syntax: vm.sh [-e|h|i|n|o|V]"
  echo "Options:"
  echo "e environment variables to use" #ToDo: Show what they are.
  echo "h Print this help."
  echo "i What image to download"
  echo "Example: https://cloud-images.ubuntu.com/releases/20.04/reease/ubuntu-20.04-server-cloudimg-amd64.ova"
  echo "n VM Name"
  echo "o Output file name for image"
  echo "V Print software version and exit"
  echo
}

################################################
# Variable Management                          #
################################################
VM="foobar"
ENV=".env"
IMG="https://cloud-images.ubuntu.com/releases/20.04/reease/ubuntu-20.04-server-cloudimg-amd64.ova"
JELLY_IMG="https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.ova"
JSON="ubuntu.json"
OUTPUT="20.04-cloud.ova"
JELLY_OUTPUT="22.04-cloud.ova"
ADDR='169.0.0.1'


#################################################
# Download                                      #
#################################################
Download()
{
  source $ENV
  curl -L -C - $JELLY_IMG --output ./images/$JELLY_OUTPUT
}

#################################################
# Update JSON                                   #
#################################################
JSON()
# Will be creating temp.json right now just based
# off of ubuntu.json, obvs needs to be more dynamic
{
  /usr/bin/python3 ./cloud-json-update.py $VM
}

################################################
# Address                                      #
# Need to make it so that it only outputs the  #
# Info on debug                                #
################################################
Address()
{
  until govc vm.info -json $VM | jq -r --exit-status '.VirtualMachines[].Guest.IpAddress != ""';
  do
    echo "Not address yet, sleeping for ten seconds"; # move to debug only
    sleep 10;
  done
  ADDR=$(govc vm.info -json $VM | jq -r '.VirtualMachines[].Guest.IpAddress')
  echo "Address is: $ADDR"
}

#################################################
# Menu                                          #
#################################################
while getopts ":e:h:i:j:n:o:V" option; do
  case $option in
    h) # display help
       Help
       exit;;
    i) IMG=$OPTARG;;
    e) #Environment file to use default to .env
       ENV=$OPTARG;;
    n) #VMName
       VM=$OPTARG;;
    o) OUTPUT=$OPTARG;;
    V) echo $VERSION
       exit;;
   \?) # Invalid option
       echo "Error: Invalid option"
       exit;;
  esac
done

#################################################
# Main                                          #
#################################################
source $ENV
JSON
echo "Attempting to: govc import.ova --options=./temp.json ./images/$OUTPUT" #move to debug only
# cat temp.json should only happen during debug
pwd
govc import.ova --options=temp.json ./images/$OUTPUT
govc device.remove -vm $VM cdrom-3002
govc device.cdrom.add -vm $VM -controller ide-200
govc device.cdrom.insert -vm $VM -device cdrom-3000 seed.iso
govc vm.power -on $VM
Address
ssh -o StrictHostKeyChecking=no $ADDR "sudo hostnamectl set-hostname $VM; sudo shutdown -h now"
until govc vm.info -json $VM | jq -r --exit-status '.VirtualMachines[].Runtime.PowerState == "poweredOff"';
do
  echo "VM Not yet shutdown, sleeping for five seconds"; # move to debug only
  sleep 5;
done
govc device.remove -vm $VM cdrom-3000
govc vm.power -on $VM
Address
govc vm.info $VM #This should display at the end, but suprress the output from Address normally.
# Cleanup, cleanup, everybody do your share
# Also, just to be  sure sensitive things do not accidentally end up in env variables when we don't expect them
rm temp.json
unset GOVC_INSECURE
unset GOVC_URL
unset GOVC_USERNAME
unset GOVC_PASSWORD
