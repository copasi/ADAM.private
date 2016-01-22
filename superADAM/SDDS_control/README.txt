=== HOW TO RUN SDDS_control ===

SDDS_control has been made available as a Docker container to make it easy to run anywhere without tedious technical manipulation. For more information about Docker, see http://docker.com
The SDDS_control docker image is available here: https://registry.hub.docker.com/u/algorun/sdds_control/

1. Install docker
See https://docs.docker.com/

2. Run the SDDS_control docker image
sudo docker run -d -p 31331:8765 --name react algorun/sdds_control
This will automatically pull the algorun/sdds_control docker image from docker hub.
Note that you can pick an other port number than 31331

3. You can access the Algorun web interface via your web browser
Direct your web browser to http://127.0.0.1:31331

5. [optional] to stop and delete the container
sudo docker kill react
sudo docker rm react

=== HOW TO REBUILD THE DOCKER IMAGE ===

If you changed the SDDS_control code, you need to rebuild the docker image:
cd superADAM/SDDS_control
sudo docker build -t <your username>/sdds_control .
You may also have to update the Dockerfile to reflect changes you made in the SDDS_control docker container.
