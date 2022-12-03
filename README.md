# [pyunramura/microw](https://github.com/pyunramura/microw)
***The w stands for web!***

[![Release Ship](https://github.com/pyunramura/microw/actions/workflows/semver-build-push-release.yaml/badge.svg)](https://github.com/pyunramura/microw/actions/workflows/semver-build-push-release.yaml) [![Validate Dockerfile](https://github.com/pyunramura/micro-test/actions/workflows/validate-dockerfile.yaml/badge.svg)](https://github.com/pyunramura/micro-test/actions/workflows/validate-dockerfile.yaml)
---

This project's home is located at https://github.com/pyunramura/microw

Find this image on the Github container registry at [pyunramura/microw](https://github.com/users/pyunramura/packages/container/package/microw)

or in the Dockerhub registry at [ghcr.io/pyunramura/microw](https://hub.docker.com/r/pyunramura/microw).

### About the project
This image is builds on top of the amazing __[Micro](https://github.com/zyedidia/micro)__ and __[ttyd](https://github.com/tsl0922/ttyd)__ projects.

The project has one simple aim; to provide a containerized webgui for editing text files of various types.

## Background
I was searching for a simple and lightweight way to edit my traefik dynamic configuration without the need to ssh into the underlying server. Though I already knew of full IDEs like code-server and cloud9, for my use case they were too heavy and feature-rich for editing a couple of yaml or toml files. After I stumbled on the ttyd project I realized that it would be possible to put together a minimal docker image that would fulfill this task.

## Features
- Minimal - No extra cruft. Only what you need to edit config files, text files, or even code if you're so inclined.
- Tiny - the image is less than 8Mb in size. Perfect as a sidecar image.
- Few dependencies - Just [tini](https://github.com/krallin/tini), [ttyd](https://github.com/tsl0922/ttyd), and [micro](https://github.com/zyedidia/micro) on [alpine linux](https://www.alpinelinux.org/). And thanks to the convenience of github-actions it's always up to date!
- Versatile - With the powerful [Micro](https://micro-editor.github.io/) editor built in, it's easy to write code in a lightweight ncui with many of the creature comforts of a full IDE.
- Cross-compatible - Images for x86, x86_64, arm64/aarch64, and armhf/v7 are available.

## How to use it
### Example usage with docker
```
docker run --rm -p 7681:7681 --name microw ghcr.io/pyunramura/microw
or
docker run --rm -p 7681:7681 --name microw pyunramura/microw
```
Here the container is mapped to port 7681 on the host and 7681 inside the container.

Then access the newly created Micro buffer at http://localhost:7681/

### Using a docker volume mapping to edit a local config file
```
docker run -p 7681:7681 -v local-dir/example-file.conf:/data/example-file.conf --name microw ghcr.io/pyunramura/microw
```
Then access the file in the webgui at http://localhost:7681/?arg=/data/example-file.conf

Where `?arg=` is the argument you want passed on to Micro. You can also string arguments with an `&` between each one.

e.x. `?arg=/data/example-file.conf&arg=/data/another-file.conf`

***Note:*** More examples of **Micro's** configuration options [are available here](https://github.com/zyedidia/micro/tree/master/runtime/help).

### Mapping Microw's config directory to customize Microw's settings persistently
```
docker run -p 7681:7681 -v micro-config-dir:/config --name microw ghcr.io/pyunramura/microw
```
Now you can persist any changes you prefer in to micro's configuration settings, keybindings, or installed plugins.

### Advanced usage with docker using "cmd"
```
docker run -p 7681:7681 --name microw ghcr.io/pyunramura/microw -t titleFixed=Microw -t fontSize=18 micro
```
Here the commands after `ghcr.io/pyunramura/microw` get passed to the tini init system, so if you'd prefer to log into the shell instead you could run `... ghcr.io/pyunramura/microw /sbin/login`

***Note:*** More examples of **ttyd's** configuration options [are available here](https://github.com/tsl0922/ttyd#command-line-options).

### Example usage with docker-compose and traefik
[/docker-compose.yml](docker-compose.yml)
```
---
version: '3.8'
services:
  traefik:
    # Docs: https://doc.traefik.io/traefik
    image: traefik
    container_name: traefik
    command:
      - --api.dashboard=true
      - --providers.docker=true
      - --providers.file=true
      - --providers.file.filename=/dynamic.yml
      - --entryPoints.web.address=:80
      - --entryPoints.web.http.redirections.entryPoint.to=websecure
      - --entryPoints.web.http.redirections.entryPoint.scheme=https
      - --entryPoints.web.http.redirections.entryPoint.permanent=true
      - --entryPoints.websecure.address=:443
      - --entrypoints.websecure.http.tls=true
      - --entrypoints.websecure.http.tls.certresolver=le
      - --certificatesresolvers.le.acme.email=youremail@yoursite.com
      - --certificatesresolvers.le.acme.httpschallenge=true
      - --certificatesresolvers.le.acme.storage=/acme.json
    networks:
      - traefik-public
    ports:
      - 80:80
      - 443:443
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./dynamic-config.yml:/dynamic.yml
      - ./acme.json:/acme.json
      - ./.htpasswd:/.htpasswd
    labels:
      - traefik.http.routers.traefik.rule=Host(`traefik.yoursite.com`)
      - traefik.http.routers.traefik.service=api@internal
      - traefik.http.routers.traefik.middlewares=user-auth
      - traefik.http.middlewares.user-auth.basicauth.usersfile=/.htpasswd
  microw:
    # Docs: https://github.com/pyunramura/microw
    image: ghcr.io/pyunramura/microw:latest
    container_name: microw
    restart: unless-stopped
    volumes:
      - ./dynamic-config.yml:/data/dynamic.yml
    networks:
      - traefik-public
    depends_on:
      - traefik
    labels:
      - traefik.routers.microw.rule=Host(`traefik-config.yoursite.com`)
      - traefik.http.routers.traefik.service=microw
      - traefik.http.routers.traefik.middlewares=user-auth
networks:
  traefik-public:
```
Here we've set up both traefik and microw in a configuration so that Traefik will provide an https endpoint and authentication to microw's web interface, and microw can then write to traefik's dynamic config file located at /dynamic.yml which are then loaded by traefik.

After running `docker-compose up -d` we can access the webgui at https://traefik-config.yoursite.com/?arg=/data/dynamic.yml.

### Example usage with docker swarm and traefik
[/docker-compose-swarm.yml](docker-compose-swarm.yml)
```
---
version: '3.8'
services:
  traefik:
    # Docs: https://doc.traefik.io/traefik
    image: traefik
    container_name: traefik
    command:
      - --api.dashboard=true
      - --providers.docker=true
      - --providers.file=true
      - --providers.file.filename=/dynamic.yml
      - --entryPoints.web.address=:80
      - --entryPoints.web.http.redirections.entryPoint.to=websecure
      - --entryPoints.web.http.redirections.entryPoint.scheme=https
      - --entryPoints.web.http.redirections.entryPoint.permanent=true
      - --entryPoints.websecure.address=:443
      - --entrypoints.websecure.http.tls=true
      - --entrypoints.websecure.http.tls.certresolver=le
      - --certificatesresolvers.le.acme.email=youremail@yoursite.com
      - --certificatesresolvers.le.acme.httpschallenge=true
      - --certificatesresolvers.le.acme.storage=/acme.json
    networks:
      - traefik-public
    ports:
      - 80:80
      - 443:443
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./dynamic-config.yml:/dynamic.yml
      - ./acme.json:/acme.json
      - ./.htpasswd:/.htpasswd
    deploy:
      placement:
        constraints:
          - node.role == manager
          - node.labels.traefik-public.traefik-certificates == true
          - node.labels.traefik-configs.traefik-dynamic == true
      labels:
        - traefik.http.routers.traefik.rule=Host(`traefik.yoursite.com`)
        - traefik.http.routers.traefik.service=api@internal
        - traefik.http.routers.traefik.middlewares=user-auth
        - traefik.http.middlewares.user-auth.basicauth.usersfile=/.htpasswd
  microw:
    # Docs: https://github.com/pyunramura/microw
    image: ghcr.io/pyunramura/microw:latest
    container_name: microw
    restart: unless-stopped
    volumes:
      - ./dynamic-config.yml:/data/dynamic.yml
    networks:
      - traefik-public
    deploy:
      placement:
        constraints:
          - node.labels.traefik-configs.traefik-dynamic == true
      labels:
        - traefik.routers.microw.rule=Host(`traefik-config.yoursite.com`)
        - traefik.http.routers.traefik.service=microw
        - traefik.http.routers.traefik.middlewares=user-auth
networks:
  traefik-public:
```
In this example we are setting up the same stack on docker with swarm mode. The only difference here are new deployment constraints causing traefik and microw to only run on a node which has traefik's configuration files. We can add this with `docker node update --label-add traefik-configs.traefik-dynamic=true yournode`.

As before after running `docker stack deploy -c docker-compose-swarm.yml` we can access the webgui at https://traefik-config.yoursite.com/?arg=/data/dynamic.yml.

## Security considerations
Due to the nature of the micro-editor and how it's implemented here by default, anyone who has access to the web interface will have **full access** to the underlying filesystem of the container. Be sure to **put proper safeguards in place** in front of it. e.g. an **authenticated reverse-proxy**, and allow **trusted users only**.

## Reach out
If have any issue with microw or the examples above please feel free to open a new issue, or if you would like to contribute to the project I would welcome a pull-request as well. And thank you for making it this far!

## To Do
- [ ] Flags to harden intra-container security (puid? chroot? login?)

## Updates
- 1.3.0    Update WORKDIR, package versions, and Alpine base image
- 1.2.0    Update CI tooling and package versions
- 1.1.0    Remove external deps. for Micro
- 1.0.2    Fix build pipeline
- 1.0.1    Updated README for container repos
- 1.0.0    Stable release
- 0.0.0    Init
