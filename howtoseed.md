# How to seed

## Code dumps

Downloading and then pulling the json for import

```bash
curl -L -C - https://cloud-images.ubuntu.com/releases/20.04/reease/ubuntu-20.04-server-cloudimg-amd64.ova --output 20.04-cloud.ova
govc import.spec ./20.04-cloud.ova | python -m json.tool > 2004.json
```

Seed.iso setup

```bash
mkdir seedconfig
mv user-data.yml seedconfig/user-data
touch seedconfig/meta-data # see example down below
cd seedconfig
genisoimage -output seed.iso -volid cidata -joliet -rock user-data meta-data
govc datastore.upload ./seed.iso ./seed.iso #see govc datastore.upload -h for more info or just upload the seed image to the datastore manually
```

Importing and configuring the VM

```bash
govc import.ova --options=ubuntu.json ./20.04-cloud.ova
# Remove the OG cdrom because it doesn't work right if we attach the seed iso to that drive...
govc device.remove -vm $VM cdrom-3002
govc device.cdrom.add -vm $VM -controller ide-200
# Might be prudent to do a govc device.ls -vm $VM
govc device.cdrom.insert -vm $VM -device cdrom-3000 seed.iso
govc vm.power -on $VM
govc vm.info #until it gets an IP
ssh $IP
sudo hostnamectl set-hostname $NAME
sudo shutdown -h now
watch govc vm.info until Power state == poweredOff
govc device.remove -vm $VM cdrom-3000 
# Obviously if the device is needed, then just eject the cd rather than removing the device.
# If you leave the seed in though, and don't make the changes to disable seed being executed, it will run again on next boot.
govc vm.power -on $VM
```

### Example meta-data contents

```

local-hostname: ubuntu-cloud-img

# ens192 is the default network interface enabled in the image. You can configure
# static network settings with an entry like below.
#network-interfaces: |
#  iface ens192 inet static
#  address 192.168.1.10
#  network 192.168.1.0
#  netmask 255.255.255.0
#  broadcast 192.168.1.255
#  gateway 192.168.1.254

```

### Example user-data contents

```yaml
#cloud-config
#vim:syntax=yaml
groups:
  - contoso
users:
# You don't have to keep the default user if you don't want it
  - default 
# This is where you set your user stuff
  - name: jdoe
    ssh-authorized-keys:
      - ssh-rsa $YOUR-RSA-KEY jdoe@contoso
# This eliminates the need for password when doing sudo
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: false
    groups: admin, sudo, nzdotech
    shell: /bin/bash
    primary_group: contoso
# Hashed passwords can be generated with:
# python -c 'import crypt,getpass; print crypt.crypt(getpass.getpass())'
    passwd: $6$SecretHashHere
# If you do keep that default user, probably a good idea to make them change their password.
# Note, for Ubuntu cloud-img the default is ubuntu, other distros will have something else.
chpasswd:
  list: |
    ubuntu:ubuntu

```

### Example Ubuntu.json

```json
{
    "DiskProvisioning": "thin",
    "PowerOn": false,
    "Name": "pg-1",
    "PropertyMapping": [
        {
            "Key": "instance-id",
            "Value": "id-ovf"
        },
        {
            "Key": "hostname",
            "Value": "pg-1"
        },
        {
            "Key": "seedfrom",
            "Value": ""
        },
        {
            "Key": "public-keys",
            "Value": ""
        },
        {
            "Key": "user-data",
            "Value":""
        },
        {
            "Key": "password",
            "Value": ""
        }
    ],
    "InjectOvfEnv": false,
    "MarkAsTemplate": false,
    "WaitForIP": false,
    "IPAllocationPolicy": "dhcpPolicy",
    "IPProtocol": "IPv4",
    "NetworkMapping": [
        {
            "Name": "VM Network",
            "Network": "VM Network"
        }
    ]
}
```
