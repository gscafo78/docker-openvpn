![OpenVPN](https://upload.wikimedia.org/wikipedia/commons/thumb/f/f5/OpenVPN_logo.svg/512px-OpenVPN_logo.svg.png)

# Docker OpenVPN

OpenVPN 2.5.1 built on May 14 2021, container to create Server and or Client VPN. This allows you to use OpenVPN without needing to install it on your computer and regardless of your operating system (Linux or Windows).

# Requirement

Docker must be configured to run Linux Docker containers. If it's not the case already, right click on the Docker icon and then click on "Switch to Linux containers...".

# Build Docker Image

```shell
# Change directory to project folder
cd OpenVPN/build

# Build Docker image
docker build -t 4ss078/docker-openvpn:latest .

```

# Generate OpenVPN configuration files
For generating the configuration file, you can use the environmerts:
* GENERATE_SERVER
* SERVER_PORT (1-65535, 1194 default)
* SERVER_PROTO (TCP/UDP, UDP default)
* REDIRECT_GATEWAY (false default) if true, enable the server to push to clients "redirect-gateway def1 bypass-dhcp"
* GENERATE_CLIENT
  
Remember, without server.conf you do not generate the client file.

```shell
# Make sure you replace `<your_path>` with your target folder, this is the path where files will be created.
# To generate the Certification Authority, Server and Clinet certificate use Docker-openssl 

docker run --rm -v your_path:/opt -e GENERATE_SERVER=true \
                                  -e REDIRECT_GATEWAY=true \
                                  -e GENERATE_CLIENT=true \
                                  -e SERVER_PORT=1195 \
                                  -e SERVER_PROTO=tcp \
                                  4ss078/docker-openvpn:latest

# After this command, you are going to have in your folder the client.conf, server.conf files
```

# Create Docker Container Server Mode

```shell
# Make sure you replace `<your_path>` with your target folder, this is where files will be created.
# In this case the docker runs every .conf file locates in your_path/openvpn
# To generate the Certification Authority, Server and Clinet certificate use Docker-openssl 

docker run --network host -v your_path:/opt --privileged --cap-add=NET_ADMIN --device=/dev/net/tun -e RUN_SERVER=true 4ss078/docker-openvpn:latest
```

# Create Docker Container Client Mode

```shell

# Run Docker container in interactive mode
# In this case the docker runs every .ovpn file locates in your_path/openvpn
# Make sure you replace `<your_path>` with your target folder, this is where the client.conf files will be placed.

docker run --network host -v your_path_of_client.conf:/opt --cap-add=NET_ADMIN --device=/dev/net/tun -e RUN_CLIENT=true 4ss078/docker-openvpn:latest
```
