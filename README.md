# pyunramura/openvpn
[![](https://images.microbadger.com/badges/image/pyunramura/openvpn:2.4.6.svg)](https://hub.docker.com/r/pyunramura/openvpn "Link to Docker Hub project")
[![](https://images.microbadger.com/badges/version/pyunramura/openvpn:2.4.6.svg)](https://microbadger.com/images/pyunramura/openvpn:2.4.6 "MicroBadger.com info on my Docker image")
[![](https://images.microbadger.com/badges/commit/pyunramura/openvpn:2.4.6.svg)](https://hub.docker.com/u/pyunramura "Link to my Docker Hub profile")
[![](https://img.shields.io/github/license/pyunramura/docker-openvpn.svg?logo=github&logoColor=white)](https://github.com/pyunramura/docker-openvpn/blob/master/LICENSE "Link to the license")
[![](https://img.shields.io/github/languages/top/pyunramura/docker-openvpn.svg?colorB=green&logo=gnu&logoColor=white)](https://github.com/pyunramura/docker-openvpn "Link to my Github project")

## How to use this image

This container provides the openvpn service coupled with a simple, versatile, and robust firewall that will block all outgoing data except to one vpn provider's address, port and protocol that is taken automatically from your provided `client.ovpn` file. 

[![](https://i.imgur.com/l0FyCJ9.png)](https://openvpn.net/ "Link to OpenVPN.com website")

The container is configured for out-of-the-box for port-forwarding when used with a capable [private internet access](https://www.privateinternetaccess.com/pages/client-support/) server. *Other providers can be added by request.*

It is based on Alpine Linux, a streamlined distribution tailored for Docker then augmented with [s6-overlay](https://github.com/just-containers/s6-overlay) to utilize its advanced process management capabilities.

The goal is to start this container first then run another container within the vpn container's network with `--net=container:openvpn`, or as part of a docker-compose stack with `network_mode: service:openvpn`.

## Usage Example with Transmission

```
docker run -d --rm \
	--name openvpn \
	--cap-add=NET_ADMIN \
	--device /dev/net/tun \
	--net=vpn_network \
	-e LAN_NET=1.2.3.4\24 \
	-v path/to/ovpn/config:/config \
	-v vpn_port:/var/run/ovpn \
	-p 9091:9091 \
	pyunramura/openvpn
```

# Parameters

`The parameters are split into two halves, separated by a colon, the left hand side representing the host and the right the container side.`

For example with `-p external:internal` - what this shows is the port mapping from external to internal of the container.
So `-p 80:9091` would expose port 9091 from inside the container to be accessible from the host's IP on port 80. http://192.168.x.x:80 would show you what's running INSIDE the container on port 9091.

  * `--dns` - needed by the firewall for internet address resolution; see below for explanation
  * `-p 9091` - the mapped port for the service(s) you wish to access, in this example transmission-web
  * `-v /config` - where openvpn will look for its ovpn configuration files at **`/config/client.ovpn`**
  * `-v vpn_port` - a docker volume for the the forwarded port for other containers that access the vpn tunnel
  * `-e LAN_NET` - the local subnet you will be accessing services from; remote access is untested at time of writing

#### Notes from above
* Due to the nature of the ovpn client, this container must be started with some additional privileges. `--cap-add=NET_ADMIN` makes sure that the tunnel can be created from within the container.

* The `--device /dev/net/tun` command will allow the container access to your host's tunnel adapter. This could be automated, but would require unconfined privileges to your host which would go against the principal of least authority, and so is intentionally omitted.

* The `vpn_port` volume is made with `docker create volume vpn_port`. It is used by the service to announce the forwarded port to other containers behind the vpn tunnel. This is configured for private internet access servers that allow port forwarding; with additional providers planned for future releases. A current list an be found on their [client support page](https://www.privateinternetaccess.com/pages/client-support/) under *Port Forwarding*.

* *DNS NOTE:* In most cases, you will want a DNS server to be specified using `--dns <ip-address>`. It is recommended to use a secure DNS server that is **not from your ISP** as it can result in [DNS leakage](https://en.wikipedia.org/wiki/DNS_leak) that could expose your identity even behind a vpn tunnel. One recommended option is to use the PIA DNS servers which can be found on their [client support page](https://www.privateinternetaccess.com/pages/client-support/) under *DNS Leak Protection*.

## Info

* For shell access while the container is running

   `docker exec -it openvpn /bin/sh`

* Monitor the logs of the container in realtime

   `docker logs -f openvpn`

* For the container version number

   `docker inspect -f '{{ index .Config.Labels "build_version" }}' openvpn`

* For the image version number

   `docker inspect -f '{{ index .Config.Labels "build_version" }}' pyunramura/openvpn`

# Advanced usage

## Connection between containers behind the vpn tunnel
A container started with `--net=container:<vpn>` will use the same network stack as the `<vpn>` container, and will share the same container IP subnet. In addition with docker-compose the command would read `network_mode: service:<vpn>` to get the same result. A compose file is provided in the git repository for reference.

[Since Docker 1.9](https://docs.docker.com/engine/userguide/networking/dockernetworks/), it is recommended to use a non-default network allowing containers to address each other by name.

### Creation of a network
```Shell
docker network create vpn_network
```

This creates a network called `vpn_network` in which containers can address each other by name; the `/etc/hosts` is updated automatically for each container added to the network.

### Start the openvpn container in the vpn_network
```Shell
docker run ... --net=vpn_network --name=openvpn -p 9091:9091 pyunramura/openvpn
```

Within the `vpn_network` there is now a resolvable name `openvpn` that points to that newly created container.

### Create a container behind the vpn's tunnel
This step is the same as the earlier one
```Shell
# Create the transmission service that listens on port 9091
docker run ... --net=container:openvpn --name=transmission transmission
```

This container is not addressable by name outside the `vpn_network`, but given that the network stack used by `transmission` is the same as the `openvpn` container, they have the same IP address outside the docker network. The service running in this container will be accessible at `http://openvpn:9091`.

# Troubleshooting
If there are errors in `docker logs -f openvpn` on container start that show failure to create a tunnel, check that the `address`, `port`, and `protocol` are given in the `/config/client.ovpn` file. For example, you should see:

```
   remote <address> <port> <proto>

   or

   remote <address>
   port <port>
   proto <protocol>
```
or any combination of the above three values.

Additional values for `ca`, `crl-verify`, or `auth-*` will either need to be specified in-line in the file, or referenced by the file. For example:

```
   auth-user-pass <path/to/credentials file>
   ca <path/to/ca.crt file>
   crl-verify <path/to/crl.pem file>

   or 

   auth-user-pass

   <ca>
   .............
   </ca>

   <crl-verify>
   .............
   </crl-verify>
```
The structure of these files are highly variable and dependant on how your provider creates them. Make any referenced authentication or kty-files only have read/write permissions for the owner with `chmod 600 <files>`. For additional information on the ovpn file, consult the [OpenVPN Reference Manual](https://openvpn.net/community-resources/reference-manual-for-openvpn-2-4/).

### PIA port forwarding

If you are using private internet access as a provider, and are **not** able to open a port for forwarding, you will see an error on container start in the Docker logs as shown below. To correct this, connect to one of the port-forwarding providers listed on their [client support page](https://www.privateinternetaccess.com/pages/client-support/) under *Port Forwarding*.

```
[cont.init.d] [INFO] Port forwarding is already activated on this connection, has expired, or you are not connected to a provider that supports port forwarding'
```
Otherwise you will see a output in the Docker logs similar to:

```
[cont.init.d] [INFO] Forwarding {"port":12345}
```
* If you have any other problems or comments about using this container, please reach out to me through the "Issues" tab as feedback and bug reports are welcome and encouraged.

## Versions

+ **2.4.6-r3** Initial release.

