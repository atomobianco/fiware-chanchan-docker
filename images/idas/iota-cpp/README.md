## Backend Device Management - IDAS IoT Agent for UL2.0/HTTP, MQTT and Thinking Things Docker image

The [Backend Device Management](http://catalogue.fiware.org/enablers/backend-device-management-idas) is an implementation of the Backend Device Management GE. 

Find detailed information of this Generic enabler at [Architecture Description](https://forge.fiware.org/plugins/mediawiki/wiki/fiware/index.php/FIWARE.ArchitectureDescription.IoT.Backend.DeviceManagement).

## Requirements

- MongoDB. For docker usage we've already made some images available [here](https://registry.hub.docker.com/u/bitergia/mongodb/).
- Orion. For docker usage we've already made some images available [here](https://registry.hub.docker.com/u/bitergia/fiware-orion/).


## Image contents

- [x] `centos:centos6` baseimage available [here](https://registry.hub.docker.com/_/centos/)
- [x] [Fiware IoT Agent for UL2.0/HTTP, MQTT and Thinking Things](https://github.com/telefonicaid/fiware-IoTAgent-Cplusplus)

## Usage

We strongly suggest you to use [docker-compose](https://docs.docker.com/compose/). With docker compose you can define multiple containers in a single file, and link them easily. 

So for this purpose, we have already a simple file that launches:

   * A MongoDB database
   * Data-only container for the MongoDB database
   * Orion Context Broker as a service
   * IDAS IoT Agent for UL2.0/HTTP, MQTT and Thinking Things

The file `idas.yml` can be downloaded from [here](https://raw.githubusercontent.com/Bitergia/fiware-chanchan-docker/master/compose/idas.yml).

Once you get it, you just have to:

```
docker-compose -f idas.yml up -d idasiotacpp
```
And all the services will be up. End to end testing can be done using the complete [chanchanapp docker compose](https://github.com/Bitergia/fiware-chanchan/blob/master/docker/compose/chanchan-new.yml).

**Note**: as retrieving the `<container-ip>` can be a bit 'tricky', we've created a set of utilities and useful scripts for handling docker images. You can find them all [here](https://github.com/Bitergia/docker/tree/master/utils).

 
## What if I don't want to use docker-compose?

No problem, the only thing is that you will have to deploy a MongoDB and orion yourself and modify the [config parameters](https://github.com/Bitergia/fiware-chanchan-docker/blob/master/images/idas/iota-cpp/1.2.0/config.json).

An example of how to run it could be:

```
docker run -d --name <container-name> bitergia/idas-iota-cpp:1.2.0
```

By running this, it expects a MongoDB database and Orion running on:

    * MONGODB_HOSTNAME: `mongodb`
    * MONGODB_PORT: `27017`
    * MONGODB_DATABASE: `iota-cpp`
    * ORION_HOSTNAME: `orion`
    * ORION_PORT: `1026`

So if you have your MongoDB and Orion somewhere else, just attach it as a parameter like:

```
docker run -d --name <container-name> \
-e MONGODB_HOSTNAME=<mongodb-host> \
-e MONGODB_PORT=<mongodb-port> \
-e MONGODB_DATABASE=<mongodb-database> \
-e ORION_HOSTNAME=<orion-host> \
-e ORION_PORT=<orion-port> \
bitergia/idas-iota-cpp:1.2.0
```

## Stopping the container

`docker stop` sends SIGTERM to the init process, which is then supposed to stop all services. Unfortunately most init systems don't do this correctly within Docker since they're built for hardware shutdowns instead. This causes processes to be hard killed with SIGKILL, which doesn't give them a chance to correctly clean-up things.

To avoid this, we suggest to use the [docker-stop](https://github.com/Bitergia/docker/tree/master/utils#docker-stop) script available in this [repository](https://github.com/Bitergia/docker/tree/master/utils). This script basically sends the SIGPWR signal to /sbin/init inside the container, triggering the shutdown process and allowing the running services to cleanly shutdown.

## User feedback

### Documentation

All the information regarding the image generation is hosted publicly on [Github](https://github.com/Bitergia/fiware-chanchan-docker/tree/master/images/idas/iota-cpp).

### Issues

If you find any issue with this image, feel free to contact us via [Github issue tracking system](https://github.com/Bitergia/fiware-chanchan-docker/issues).
